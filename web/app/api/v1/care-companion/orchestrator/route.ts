import { NextRequest, NextResponse } from "next/server";
import { CareCompanionOrchestrator, OrchestratorActionRequest } from "@/application/care-companion/care-companion-orchestrator";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body: OrchestratorActionRequest & { patientId?: string } = await req.json().catch(() => ({}));

    let { action, parameters = {}, patientConfirmed, patientId } = body;

    if (!action) {
      return NextResponse.json(
        { success: false, error: "Parameter 'action' wajib disertakan." },
        { status: 400 }
      );
    }

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id;
    }

    if (!patientId) {
      return NextResponse.json(
        { success: false, error: "Parameter 'patientId' wajib disertakan dan tidak ada pasien di basis data." },
        { status: 400 }
      );
    }

    const ipAddress = req.headers.get("x-forwarded-for") || req.headers.get("x-real-ip") || "127.0.0.1";

    const result = await CareCompanionOrchestrator.executeAction(
      { action, parameters, patientConfirmed },
      { patientId, ipAddress }
    );

    return NextResponse.json(result);
  } catch (error: any) {
    console.error("[care-companion orchestrator POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal mengeksekusi aksi orkestrator." },
      { status: 500 }
    );
  }
}
