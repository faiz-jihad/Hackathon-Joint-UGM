import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let { agendaId, patientId, isCompleted = true } = body;

    if (!agendaId) {
      return NextResponse.json(
        { success: false, error: "ID Agenda (agendaId) wajib disertakan." },
        { status: 400 }
      );
    }

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "P-DEFAULT";
    }

    // Try finding existing CareReminder by id or title
    let reminder = await (prisma as any).careReminder?.findUnique({
      where: { id: agendaId },
    }).catch(() => null);

    if (!reminder) {
      // Create or upsert reminder record for persistence
      reminder = await (prisma as any).careReminder?.create({
        data: {
          id: agendaId,
          patientId,
          reminderType: "LIFESTYLE_CHECK",
          title: agendaId.replace(/^agenda-/, "").replace(/-[0-9]{4}-[0-9]{2}-[0-9]{2}$/, "").replace(/-/g, " ").toUpperCase(),
          scheduledTime: new Date(),
          isCompleted,
          completedAt: isCompleted ? new Date() : null,
          isActive: true,
        },
      }).catch(async () => {
        // Fallback update if already exists with duplicate key
        return await (prisma as any).careReminder?.update({
          where: { id: agendaId },
          data: { isCompleted, completedAt: isCompleted ? new Date() : null },
        }).catch(() => null);
      });
    } else {
      reminder = await (prisma as any).careReminder?.update({
        where: { id: agendaId },
        data: { isCompleted, completedAt: isCompleted ? new Date() : null },
      }).catch(() => null);
    }

    return NextResponse.json({
      success: true,
      data: {
        agendaId,
        isCompleted,
        completedAt: isCompleted ? new Date().toISOString() : null,
      },
    });
  } catch (error: any) {
    console.error("[agenda toggle POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to update agenda item status." },
      { status: 500 }
    );
  }
}
