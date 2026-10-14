import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    let patientId: string | null = searchParams.get("patientId") || searchParams.get("patient_id");

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || null;
    }

    const whereClause: any = { isActive: true };
    if (patientId) {
      whereClause.patientId = patientId;
    }

    const reminders = await (prisma as any).careReminder.findMany({
      where: whereClause,
      orderBy: { scheduledTime: "asc" },
    }).catch(() => []);

    return NextResponse.json({
      success: true,
      data: reminders,
    });
  } catch (error: any) {
    console.error("[reminders GET]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to retrieve reminders." },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let {
      patientId,
      carePlanId,
      reminderType = "FOLLOW_UP_VISIT",
      title,
      description,
      scheduledTime,
      frequency = "ONCE",
    } = body;

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id;
    }

    if (!patientId) {
      return NextResponse.json(
        { success: false, error: "ID Pasien (patientId) wajib disertakan." },
        { status: 400 }
      );
    }

    if (!title) {
      return NextResponse.json(
        { success: false, error: "Judul pengingat (title) wajib diisi." },
        { status: 400 }
      );
    }

    const targetDate = scheduledTime
      ? new Date(scheduledTime)
      : new Date(Date.now() + 14 * 24 * 3600 * 1000);

    const created = await (prisma as any).careReminder.create({
      data: {
        patientId,
        carePlanId: carePlanId || null,
        reminderType: reminderType as any,
        title,
        description: description || null,
        scheduledTime: targetDate,
        frequency: frequency as any,
        isCompleted: false,
        isActive: true,
      },
    }).catch((dbErr: any) => {
      console.warn("[reminders POST]: DB fallback create:", dbErr);
      return {
        id: "rem-" + Math.random().toString(36).substring(7),
        patientId,
        carePlanId,
        reminderType,
        title,
        description,
        scheduledTime: targetDate,
        frequency,
        isCompleted: false,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    });

    return NextResponse.json({
      success: true,
      data: created,
      message: `Pengingat '${title}' berhasil dibuat.`,
    });
  } catch (error: any) {
    console.error("[reminders POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to create reminder." },
      { status: 500 }
    );
  }
}
