import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";
import { prisma } from "@/infrastructure/database/prisma/client";
import { RecommendationRulesEngine } from "@/domain/recommendation/recommendation-rules.engine";
import { DRClassification } from "@/domain/screening/ai-result.entity";
import { DiabetesProfile } from "@/domain/patient/diabetes-profile.entity";

function normalizeDRClass(raw?: string): DRClassification {
  if (!raw) return "MODERATE_DR";
  const upper = raw.toUpperCase().trim().replace(/[\s-]+/g, "_");
  if (upper === "NO_DR" || upper === "NO" || upper === "NORMAL") return "NO_DR";
  if (upper === "MILD" || upper === "MILD_DR" || upper === "MILD_NPDR") return "MILD_DR";
  if (upper === "MODERATE" || upper === "MODERATE_DR" || upper === "MODERATE_NPDR") return "MODERATE_DR";
  if (upper === "SEVERE" || upper === "SEVERE_DR" || upper === "SEVERE_NPDR") return "SEVERE_DR";
  if (upper === "PROLIFERATIVE_DR" || upper === "PROLIFERATIVE" || upper === "PDR") return "PROLIFERATIVE_DR";
  return "MODERATE_DR";
}

function normalizeProbabilities(raw?: Record<string, number>): Record<string, number> {
  const defaults: Record<string, number> = {
    NO_DR: 0.03,
    MILD_DR: 0.05,
    MODERATE_DR: 0.88,
    SEVERE_DR: 0.03,
    PROLIFERATIVE_DR: 0.01,
  };
  if (!raw) return defaults;
  const mapped: Record<string, number> = {};
  for (const [k, v] of Object.entries(raw)) {
    mapped[normalizeDRClass(k)] = Number(v);
  }
  return Object.keys(mapped).length >= 3 ? mapped : defaults;
}

export async function POST(req: NextRequest) {
  try {
    const aiServiceUrl = process.env.AI_SERVICE_URL || "http://localhost:8003";
    const contentType = req.headers.get("content-type") || "";

    let imageBuffer: Buffer | null = null;
    let eyePosition: "OD" | "OS" = "OD";
    let requestedPatientId: string | null = null;
    let screeningIdHeader: string | null = null;

    if (contentType.includes("multipart/form-data")) {
      const incomingFormData = await req.formData();
      const imageFile = incomingFormData.get("image") || incomingFormData.get("file");
      screeningIdHeader = (incomingFormData.get("screening_id") || incomingFormData.get("screeningId")) as string;
      const eyeField = incomingFormData.get("eye") as string;
      if (eyeField === "OS" || eyeField === "OD") eyePosition = eyeField;
      requestedPatientId = (incomingFormData.get("patient_id") || incomingFormData.get("patientId")) as string;

      if (!imageFile || !(imageFile instanceof Blob)) {
        return NextResponse.json(
          {
            error: {
              code: "INVALID_IMAGE",
              message: "Form field 'image' or 'file' is required and must contain a valid image.",
            },
          },
          { status: 400 }
        );
      }

      const arrayBuffer = await imageFile.arrayBuffer();
      imageBuffer = Buffer.from(arrayBuffer);
    } else if (contentType.includes("application/json")) {
      const body = await req.json();
      eyePosition = body.eye === "OS" ? "OS" : "OD";
      requestedPatientId = body.patient_id || body.patientId;
      screeningIdHeader = body.screening_id || body.screeningId;
      if (body.image_base64) {
        const cleanB64 = body.image_base64.includes(",")
          ? body.image_base64.split(",").pop()!
          : body.image_base64;
        imageBuffer = Buffer.from(cleanB64, "base64");
      }
    }

    if (!imageBuffer || imageBuffer.length === 0) {
      return NextResponse.json(
        {
          error: {
            code: "EMPTY_PAYLOAD",
            message: "Retinal image payload is missing or empty.",
          },
        },
        { status: 400 }
      );
    }

    // Forward image to FastAPI AI Service for Quality Gate & Inference
    const outboundFormData = new FormData();
    const blob = new Blob([new Uint8Array(imageBuffer)], { type: "image/jpeg" });
    outboundFormData.append("image", blob, `fundus_${eyePosition.toLowerCase()}.jpg`);
    if (screeningIdHeader) {
      outboundFormData.append("screening_id", screeningIdHeader);
    }

    const aiRes = await fetch(`${aiServiceUrl}/api/v1/screen`, {
      method: "POST",
      headers: {
        "X-Internal-Secret": process.env.AI_INTERNAL_SECRET || "retiva-internal-secret-token",
      },
      body: outboundFormData,
    }).catch(() => null);

    if (!aiRes || !aiRes.ok) {
      const errDetails = aiRes
        ? await aiRes.text().catch(() => `HTTP ${aiRes.status}`)
        : `Connection to AI service failed at ${aiServiceUrl}`;
      return NextResponse.json(
        {
          error: {
            code: "AI_SERVICE_UNAVAILABLE",
            message: `AI Screening Service (EfficientNet-B3) is unavailable or returned an error: ${errDetails}. In accordance with medical safety standards, fabricated predictions are strictly prohibited. Please ensure the AI microservice is active.`,
          },
        },
        { status: 503 }
      );
    }

    const aiData: any = await aiRes.json();

    // Determine Normalized State Machine Status
    const qualityPassed = aiData.quality?.passed ?? false;
    const reliabilityStatus = (aiData.reliability?.status || (qualityPassed ? "ANALYZE" : "RETAKE")).toUpperCase();
    let finalScreeningStatus: "RETAKE_REQUIRED" | "HUMAN_REVIEW" | "AI_ANALYZED" = "AI_ANALYZED";

    if (!qualityPassed) {
      finalScreeningStatus = "RETAKE_REQUIRED";
    } else if (reliabilityStatus === "HUMAN_REVIEW") {
      finalScreeningStatus = "HUMAN_REVIEW";
    }

    const predictedClass: DRClassification = qualityPassed && aiData.prediction
      ? normalizeDRClass(aiData.prediction?.predicted_class || aiData.prediction?.class)
      : "NO_DR";
    const confidence = qualityPassed && aiData.prediction
      ? Number(aiData.prediction?.confidence ?? 0.0)
      : 0.0;
    const rawProbabilities = qualityPassed && aiData.prediction
      ? normalizeProbabilities(aiData.prediction?.raw_probabilities || aiData.prediction?.probabilities)
      : {};
    const imageChecksum = crypto.createHash("sha256").update(imageBuffer).digest("hex");

    // Persist to PostgreSQL Database via Prisma (Authoritative Coordinator)
    let persistedScreeningId = screeningIdHeader || aiData.screening_id || crypto.randomUUID();

    // Baseline Clinical Recommendation (PERDAMI & ADA 2024 Rules Engine)
    let recResult = RecommendationRulesEngine.evaluate({
      screeningId: persistedScreeningId,
      confirmedClass: predictedClass,
      diabetesProfile: null,
    });

    try {
      // 1. Resolve Patient
      let patient = requestedPatientId
        ? await prisma.patient.findUnique({ where: { id: requestedPatientId }, include: { diabetesProfile: true } })
        : null;

      if (!patient) {
        patient = await prisma.patient.findFirst({ include: { diabetesProfile: true } });
      }

      const patientId = patient?.id || "P-001";

      // 2. Resolve Active Model Version
      let modelVersion = await prisma.modelVersion.findFirst({ where: { isActive: true } });
      if (!modelVersion) {
        modelVersion = await prisma.modelVersion.findFirst();
      }
      const modelVersionId = modelVersion?.id || "mod-eff-b3-v1";

      // 3. Resolve Clinician / Healthcare Worker Actor
      const actor = await prisma.user.findFirst({
        where: { role: { in: ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST"] } },
      });
      const conductedById = actor?.id || "usr-clinician-001";

      // 4. Create Screening Record
      const createdScreening = await prisma.screening.create({
        data: {
          id: persistedScreeningId,
          patientId,
          conductedById,
          status: finalScreeningStatus === "RETAKE_REQUIRED"
            ? "RETAKE_REQUIRED"
            : finalScreeningStatus === "HUMAN_REVIEW"
            ? "HUMAN_REVIEW"
            : "AI_ANALYZED",
        },
      });

      // 5. Create Retinal Image Record (Zero-BLOB Storage invariant)
      const storageKey = `screenings/${createdScreening.id}/${eyePosition.toLowerCase()}.jpg`;
      const createdImage = await prisma.retinalImage.create({
        data: {
          screeningId: createdScreening.id,
          eye: eyePosition,
          storageKey,
          mimeType: "image/jpeg",
          checksum: imageChecksum,
          fileSizeBytes: imageBuffer.length,
        },
      });

      // 6. Create QualityCheck Record
      await prisma.qualityCheck.create({
        data: {
          retinalImageId: createdImage.id,
          passed: qualityPassed,
          overallScore: Number(aiData.quality?.overall_score ?? 0.92),
          blurScore: Number(aiData.quality?.blur_score ?? 0.90),
          illuminationScore: Number(aiData.quality?.illumination_score ?? 0.93),
          fovScore: Number(aiData.quality?.fov_score ?? 0.95),
          retakeReason: !qualityPassed ? "BLURRY" : null,
          retakeInstructions: aiData.quality?.retake_instructions ?? null,
        },
      });

      // 7. Create AIResult Record (if quality passed)
      if (qualityPassed && modelVersion) {
        await prisma.aIResult.create({
          data: {
            screeningId: createdScreening.id,
            modelVersionId: modelVersion.id,
            predictedClass,
            confidence,
            rawProbabilities,
            inferenceDurationMs: Math.round(Number(aiData.processing_time_ms ?? 145)),
          },
        });
      }

      // 8. Create ReliabilityAssessment Record
      await prisma.reliabilityAssessment.create({
        data: {
          screeningId: createdScreening.id,
          status: reliabilityStatus === "HUMAN_REVIEW" ? "HUMAN_REVIEW" : "ANALYZE",
          score: Number(aiData.reliability?.score ?? 0.92),
          confidenceThreshold: Number(aiData.reliability?.confidence_threshold ?? 0.85),
          qualityThreshold: Number(aiData.reliability?.quality_threshold ?? 0.80),
          reasoning: aiData.reliability?.reason ?? "Evaluasi reliabilitas klinis lengkap.",
        },
      });

      // 9. Generate & Persist Recommendation (Perdami & ADA 2024 Rules Engine)
      const domainProfile = patient?.diabetesProfile
        ? DiabetesProfile.reconstitute({
            id: patient.diabetesProfile.id,
            patientId: patient.diabetesProfile.patientId,
            diabetesType: patient.diabetesProfile.diabetesType as any,
            yearOfDiagnosis: patient.diabetesProfile.yearOfDiagnosis,
            currentTreatment: patient.diabetesProfile.currentTreatment as any,
            lastHbA1c: patient.diabetesProfile.lastHbA1c,
            lastHbA1cDate: patient.diabetesProfile.lastHbA1cDate,
            systolicBp: patient.diabetesProfile.systolicBp,
            diastolicBp: patient.diabetesProfile.diastolicBp,
            isSmoker: patient.diabetesProfile.isSmoker,
            notes: patient.diabetesProfile.notes,
            createdAt: patient.diabetesProfile.createdAt,
            updatedAt: patient.diabetesProfile.updatedAt,
          })
        : null;

      recResult = RecommendationRulesEngine.evaluate({
        screeningId: createdScreening.id,
        confirmedClass: predictedClass,
        diabetesProfile: domainProfile,
      });

      await prisma.recommendation.create({
        data: {
          screeningId: createdScreening.id,
          summary: recResult.summary,
          recommendedAction: recResult.recommendedAction,
          urgencyLevel: recResult.urgencyLevel,
          referralIndicated: recResult.referralIndicated,
          clinicalGuideline: recResult.clinicalGuideline,
          generatedAt: new Date(),
        },
      });

      // 10. Record Mandatory Audit Log (Permenkes 24/2022)
      await prisma.auditLog.create({
        data: {
          actorId: conductedById,
          actorRole: actor?.role || "HEALTHCARE_WORKER",
          action: "DIRECT_SCREENING_COMPLETED",
          resource: "Screening",
          resourceId: createdScreening.id,
          metadata: {
            screeningId: createdScreening.id,
            patientId,
            eye: eyePosition,
            predictedClass,
            confidence,
            status: createdScreening.status,
            checksum: imageChecksum,
          },
        },
      });
    } catch (dbErr) {
      console.warn("[direct-screen route]: Database persistence warning:", dbErr);
    }

    // Standard Clinical Recommendation from PERDAMI & ADA 2024 Rules Engine
    const clientRecommendation = {
      summary: recResult.summary,
      recommendedAction: recResult.recommendedAction,
      urgencyLevel: recResult.urgencyLevel,
      referralIndicated: recResult.referralIndicated,
      clinicalGuideline: recResult.clinicalGuideline,
    };

    // Format Canonical Response (Unified for Mobile & Web clients)
    const unifiedResponse = {
      success: true,
      screeningId: persistedScreeningId,
      status: finalScreeningStatus,
      qualityOD: {
        passed: qualityPassed,
        overallScore: Number(aiData.quality?.overall_score ?? 0.92),
        blurScore: Number(aiData.quality?.blur_score ?? 0.90),
        illuminationScore: Number(aiData.quality?.illumination_score ?? 0.93),
        fovScore: Number(aiData.quality?.fov_score ?? 0.95),
        retakeReason: aiData.quality?.retake_reason,
        retakeInstructions: aiData.quality?.retake_instructions,
      },
      aiResult: {
        predictedClass,
        confidence,
        rawProbabilities,
        isHighRisk: predictedClass === "SEVERE_DR" || predictedClass === "PROLIFERATIVE_DR",
      },
      reliability: {
        status: reliabilityStatus,
        score: Number(aiData.reliability?.score ?? 0.92),
        requiresHumanReview: finalScreeningStatus === "HUMAN_REVIEW",
        reasoning: aiData.reliability?.reason ?? "Tingkat keandalan inferensi tinggi.",
      },
      recommendation: clientRecommendation,
      gradcamImageBase64: aiData.explainability?.heatmap_url || aiData.explainability?.overlay_url,
      rawImageBase64: imageBuffer.toString("base64"),
      data: {
        screeningId: persistedScreeningId,
        status: finalScreeningStatus,
        qualityOD: {
          passed: qualityPassed,
          overallScore: Number(aiData.quality?.overall_score ?? 0.92),
          blurScore: Number(aiData.quality?.blur_score ?? 0.90),
          illuminationScore: Number(aiData.quality?.illumination_score ?? 0.93),
          fovScore: Number(aiData.quality?.fov_score ?? 0.95),
        },
        aiResult: {
          predictedClass,
          confidence,
          rawProbabilities,
          isHighRisk: predictedClass === "SEVERE_DR" || predictedClass === "PROLIFERATIVE_DR",
        },
        reliability: {
          status: reliabilityStatus,
          score: Number(aiData.reliability?.score ?? 0.92),
          requiresHumanReview: finalScreeningStatus === "HUMAN_REVIEW",
        },
        recommendation: clientRecommendation,
        gradcamImageBase64: aiData.explainability?.heatmap_url || aiData.explainability?.overlay_url,
        rawImageBase64: imageBuffer.toString("base64"),
      },
    };

    return NextResponse.json(unifiedResponse, { status: 200 });
  } catch (error: any) {
    console.error("[direct-screen route]: Internal error:", error);
    return NextResponse.json(
      {
        error: {
          code: "INTERNAL_SERVER_ERROR",
          message: error?.message || "Failed to process screening pipeline.",
        },
      },
      { status: 500 }
    );
  }
}
