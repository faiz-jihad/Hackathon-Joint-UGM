import { NextRequest, NextResponse } from "next/server";
import { EmergencyStore } from "@/infrastructure/database/emergency-store";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let {
      patientId,
      patientName,
      patientNik,
      patientPhone,
      symptoms = [],
      reportedContext = {},
      initialTrigger = "PATIENT_APP_BUTTON",
      latitude,
      longitude,
      accuracyMeters,
      locationStatus,
      locationAddress,
    } = body;

    // Resolve patient if not supplied
    if (!patientId) {
      const existingPatient = await prisma.patient.findFirst().catch(() => null);
      if (existingPatient) {
        patientId = existingPatient.id;
        patientName = patientName || existingPatient.fullName;
        patientNik = patientNik || existingPatient.nik;
        patientPhone = patientPhone || existingPatient.phone;
      } else {
        patientId = "patient-demo-01";
        patientName = patientName || "Bpk. Bambang Sutrisno";
        patientNik = patientNik || "3471011204650001";
        patientPhone = patientPhone || "081223344556";
      }
    }

    // Rate limiting & duplicate-request protection:
    // If an ACTIVE incident exists within the past 20 seconds for this patient, return existing
    const existingIncidents = await EmergencyStore.getIncidents({ status: "ACTIVE" });
    const duplicate = existingIncidents.find(
      (inc) =>
        inc.patientId === patientId &&
        Date.now() - new Date(inc.createdAt).getTime() < 20000
    );

    if (duplicate) {
      return NextResponse.json({
        success: true,
        message: "Peringatan darurat aktif telah tercatat dalam sistem.",
        isDuplicate: true,
        data: duplicate,
      });
    }

    // Optional: Call FastAPI Agentic AI Service for structured multi-stage triage
    // Clinical rule: If AI inference fails or times out, the core SOS workflow MUST continue without delay
    let aiTriageData: any = null;
    const aiServiceUrl = process.env.AI_SERVICE_URL || "http://localhost:8003";
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 1200); // 1.2s max to prevent delay
      const aiRes = await fetch(`${aiServiceUrl}/api/v1/sos/triage-assess`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patient_id: patientId,
          patient_name: patientName,
          symptoms,
          blood_glucose: reportedContext?.bloodGlucose,
          conscious: reportedContext?.conscious,
          can_swallow: reportedContext?.canSwallow,
          vision_changes: reportedContext?.visionChanges,
          seizure_occurred: reportedContext?.seizureOccurred,
          free_text_notes: reportedContext?.additionalNotes,
          latitude,
          longitude,
        }),
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      if (aiRes.ok) {
        aiTriageData = await aiRes.json();
      }
    } catch {
      // Graceful fallback to deterministic safety rules in EmergencyStore
    }

    // Call EmergencyStore to create incident with deterministic triage rules & contact notifications
    const incident = await EmergencyStore.createIncident({
      patientId,
      patientName,
      patientNik,
      patientPhone,
      symptoms,
      reportedContext,
      initialTrigger,
      latitude: typeof latitude === "number" ? latitude : undefined,
      longitude: typeof longitude === "number" ? longitude : undefined,
      accuracyMeters: typeof accuracyMeters === "number" ? accuracyMeters : undefined,
      locationStatus,
      locationAddress,
    });

    // If AI service provided workflow stages, enrich the incident
    if (aiTriageData && aiTriageData.workflow_stages) {
      incident.triageAssessment = {
        urgencyLevel: aiTriageData.urgency_level,
        clinicalRisk: aiTriageData.clinical_risk,
        immediateAction: aiTriageData.immediate_action,
        warningFlags: aiTriageData.warning_flags,
        safeProtocol: aiTriageData.safe_protocol,
        oralFoodAllowed: aiTriageData.oral_food_allowed,
        requiresAmbulance: aiTriageData.requires_ambulance,
        requiresEyeSpecialist: aiTriageData.requires_eye_specialist,
      };
      incident.triageSummary = aiTriageData.ai_explanation;
      (incident as any).workflowStages = aiTriageData.workflow_stages;
    }

    return NextResponse.json({
      success: true,
      message: "SOS Darurat Berhasil Diaktifkan. Petugas medis dan kontak darurat telah diberitahu.",
      data: incident,
    });
  } catch (error: any) {
    console.error("[api/sos/activate] Error:", error);
    return NextResponse.json(
      {
        success: false,
        error: error?.message || "Gagal mengaktifkan darurat SOS.",
      },
      { status: 500 }
    );
  }
}
