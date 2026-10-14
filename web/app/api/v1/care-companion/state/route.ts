import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { CareStateMachine, CareStateContext } from "@/domain/care-companion/care-state-machine";
import { CareCompanionOrchestrator } from "@/application/care-companion/care-companion-orchestrator";
import { CareCompanionMasterStore } from "@/infrastructure/database/care-companion-master-store";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    let patientId = searchParams.get("patientId") || searchParams.get("patient_id");

    // Resolve default patient from DB if none provided
    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst({
        include: { diabetesProfile: true },
      }).catch(() => null);
      patientId = firstPatient?.id || "";
    }

    // 1. Fetch latest screening
    const latestScreening = await prisma.screening.findFirst({
      where: { patientId },
      orderBy: { createdAt: "desc" },
      include: { aiResults: true, recommendation: true, reliability: true },
    }).catch(() => null);

    // 2. Fetch latest consultation summary
    const latestConsultation = await (prisma as any).consultationSummary.findFirst({
      where: { patientId },
      orderBy: { createdAt: "desc" },
    }).catch(() => null);

    // 3. Fetch active care plan
    const activeCarePlan = await (prisma as any).carePlan.findFirst({
      where: { patientId, isActive: true },
      orderBy: { createdAt: "desc" },
      include: { mealPlans: { orderBy: { createdAt: "desc" }, take: 1 } },
    }).catch(() => null);

    // 4. Fetch reminders
    const reminders = await (prisma as any).careReminder.findMany({
      where: { patientId, isActive: true },
      orderBy: { scheduledTime: "asc" },
    }).catch(() => []);

    // 5. Build State Machine Context
    const stateContext: CareStateContext = {
      hasCompletedScreening: Boolean(latestScreening),
      hasRecordedConsultation: Boolean(latestConsultation),
      isConsultationConfirmed: Boolean(latestConsultation?.isPatientConfirmed),
      hasActiveCarePlan: Boolean(activeCarePlan),
      followUpDate: latestConsultation?.followUpDate,
    };

    const resolvedState = CareStateMachine.resolveState(stateContext, activeCarePlan?.state as any);
    const stateMetadata = CareStateMachine.getStateMetadata(resolvedState);

    // 6. Pre-consultation facility & question suggestions
    const facilitiesResult = await CareCompanionOrchestrator.executeAction(
      { action: "search_eye_care_facilities", parameters: { bpjsOnly: false } },
      { patientId }
    );

    const masterQuestions = await CareCompanionMasterStore.getAllQuestions();
    const questionsForDoctor = masterQuestions.map((q) => q.questionText);

    return NextResponse.json({
      success: true,
      data: {
        patientId,
        currentState: resolvedState,
        stateMetadata,
        stateContext,
        screening: latestScreening ? {
          id: latestScreening.id,
          status: latestScreening.status,
          predictedClass: latestScreening.aiResults?.[0]?.predictedClass || "NO_DR",
          confidence: latestScreening.aiResults?.[0]?.confidence ?? 0,
          recommendation: latestScreening.recommendation,
          disclaimer: "Hasil skrining AI ini bukan diagnosis klinis definitif. Keputusan medis ditentukan oleh dokter spesialis mata.",
        } : null,
        consultationSummary: latestConsultation,
        carePlan: activeCarePlan ? {
          ...activeCarePlan,
          activeMealPlan: activeCarePlan.mealPlans?.[0] || null,
        } : null,
        reminders,
        preConsultation: {
          facilities: facilitiesResult.data?.facilities || [],
          suggestedQuestions: questionsForDoctor,
          bpjsPathway: facilitiesResult.data?.referralPathwayGuideline,
        },
      },
    });
  } catch (error: any) {
    console.error("[care-companion state]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to load care companion state." },
      { status: 500 }
    );
  }
}
