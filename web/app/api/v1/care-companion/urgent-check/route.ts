import { NextRequest, NextResponse } from "next/server";
import { UrgentSymptomChecker } from "@/domain/care-companion/urgent-symptom-checker";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let { patientId, symptomsText = "", specificFlags = {} } = body;

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id;
    }

    const evaluation = UrgentSymptomChecker.evaluate(symptomsText, specificFlags);

    // Record audit if critical symptoms detected and patientId exists
    if (evaluation.isEmergency && patientId) {
      await (prisma as any).careActionAudit.create({
        data: {
          patientId,
          actionName: "check_urgent_symptoms",
          inputParameters: { symptomsText, specificFlags },
          executionResult: evaluation as any,
          patientConfirmed: false,
        },
      }).catch(() => null);
    }

    return NextResponse.json({
      success: true,
      data: evaluation,
    });
  } catch (error: any) {
    console.error("[urgent-check]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to evaluate urgent symptoms." },
      { status: 500 }
    );
  }
}
