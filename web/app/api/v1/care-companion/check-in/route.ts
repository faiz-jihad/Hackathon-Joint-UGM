import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let {
      patientId,
      physicalCondition = "NORMAL",
      visualSymptoms = "",
      visualFlags = {},
      bloodGlucose,
      glucoseContext = "FASTING",
      medicationsCompleted = true,
      activityCompleted = true,
      patientNotes = "",
    } = body;

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "P-DEFAULT";
    }

    // 1. Evaluate with FastAPI AI microservice or clinical rule engine
    let aiEvaluationResult: any = null;
    const aiServiceUrl = process.env.AI_SERVICE_URL || "http://localhost:8003";

    try {
      const res = await fetch(`${aiServiceUrl}/api/v1/daily-care/evaluate-checkin`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patient_id: patientId,
          physical_condition: physicalCondition,
          visual_symptoms: visualSymptoms,
          visual_flags: visualFlags,
          blood_glucose: bloodGlucose ? Number(bloodGlucose) : null,
          glucose_context: glucoseContext,
          medications_completed: Boolean(medicationsCompleted),
          activity_completed: Boolean(activityCompleted),
          patient_notes: patientNotes,
        }),
      });

      if (res.ok) {
        aiEvaluationResult = await res.json();
      }
    } catch (_) {
      // Graceful fallback to embedded clinical safety engine
    }

    if (!aiEvaluationResult) {
      // Deterministic Safety Fallback (matching FastAPI & PERDAMI rules)
      const matchedTriggers: string[] = [];
      if (visualFlags.sudden_blur) matchedTriggers.push("Penurunan tajam penglihatan mendadak");
      if (visualFlags.flashes) matchedTriggers.push("Melihat kilatan cahaya (fotopsia)");
      if (visualFlags.new_floaters) matchedTriggers.push("Pertambahan floaters mendadak");
      if (visualFlags.curtain_shadow) matchedTriggers.push("Penglihatan tertutup bayangan tirai");

      const isEmergency = matchedTriggers.length > 0;
      const severity = isEmergency ? "CRITICAL_EMERGENCY" : (bloodGlucose && bloodGlucose < 70 ? "WARNING" : "ROUTINE");

      aiEvaluationResult = {
        is_emergency: isEmergency,
        severity,
        matched_triggers: matchedTriggers,
        summary: isEmergency
          ? "⚠️ PERINGATAN MEDIS DARURAT: Terdeteksi Tanda Bahaya Akut Retina"
          : "Kondisi Sehat Terpantau Stabil Hari Ini",
        explanation: isEmergency
          ? `Laporan Anda mendeteksi gejala kritis: ${matchedTriggers.join(", ")}. Segera periksakan diri ke IGD RS Mata.`
          : `Kondisi fisik dan gejala mata harian stabil. ${bloodGlucose ? `Gula darah tercatat ${bloodGlucose} mg/dL.` : ''}`,
        next_step: isEmergency
          ? "SEGERA KE IGD RS MATA DALAM 24 JAM"
          : "Lanjutkan jadwal agenda harian, minum obat rutin, dan kontrol berkala.",
        actionable_guidance: isEmergency
          ? ["Segera ke IGD RS Mata terdekat.", "Hindari mengejan atau angkat beban berat."]
          : ["Jaga hidrasi minimal 2L/hari.", "Lakukan jalan pagi santai 30 menit."],
        clinical_safety_notice: "Catatan: Hasil evaluasi mandiri ini tidak menggantikan konsultasi langsung dengan dokter spesialis mata (Sp.M).",
      };
    }

    // 2. Persist to Prisma DB (CareProgressLog)
    const logDate = new Date();
    const createdLog = await (prisma as any).careProgressLog?.create({
      data: {
        patientId,
        logDate,
        hasUrgentSymptoms: aiEvaluationResult.is_emergency || false,
        symptomsReported: visualSymptoms || (aiEvaluationResult.matched_triggers?.join(", ") || "Tidak ada keluhan"),
        patientNotes: JSON.stringify({
          physicalCondition,
          bloodGlucose: bloodGlucose ? Number(bloodGlucose) : null,
          glucoseContext,
          medicationsCompleted,
          activityCompleted,
          notes: patientNotes,
          aiEvaluation: aiEvaluationResult,
        }),
      },
    }).catch((err: any) => {
      console.warn("[Check-in POST DB Save Fallback]:", err?.message);
      return {
        id: `log-${Date.now()}`,
        patientId,
        logDate,
        hasUrgentSymptoms: aiEvaluationResult.is_emergency,
      };
    });

    return NextResponse.json({
      success: true,
      data: {
        logId: createdLog.id,
        patientId,
        timestamp: logDate.toISOString(),
        evaluation: aiEvaluationResult,
      },
    });
  } catch (error: any) {
    console.error("[check-in POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to submit daily check-in." },
      { status: 500 }
    );
  }
}

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    let patientId = searchParams.get("patientId") || searchParams.get("patient_id");

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "P-DEFAULT";
    }

    const logs = await (prisma as any).careProgressLog?.findMany({
      where: { patientId },
      orderBy: { logDate: "desc" },
      take: 14,
    }).catch(() => []);

    const formattedLogs = logs.map((l: any) => {
      let meta: any = {};
      try {
        meta = JSON.parse(l.patientNotes || "{}");
      } catch (_) {}

      return {
        id: l.id,
        date: l.logDate ? new Date(l.logDate).toISOString().split("T")[0] : "",
        timestamp: l.logDate ? l.logDate.toISOString() : "",
        hasUrgentSymptoms: l.hasUrgentSymptoms,
        symptoms: l.symptomsReported || "Normal",
        bloodGlucose: meta.bloodGlucose ?? null,
        glucoseContext: meta.glucoseContext ?? "FASTING",
        physicalCondition: meta.physicalCondition ?? "NORMAL",
        medicationsCompleted: meta.medicationsCompleted ?? true,
        activityCompleted: meta.activityCompleted ?? true,
        aiEvaluation: meta.aiEvaluation ?? null,
      };
    });

    return NextResponse.json({
      success: true,
      data: {
        patientId,
        logs: formattedLogs,
      },
    });
  } catch (error: any) {
    console.error("[check-in GET]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to fetch check-in history." },
      { status: 500 }
    );
  }
}
