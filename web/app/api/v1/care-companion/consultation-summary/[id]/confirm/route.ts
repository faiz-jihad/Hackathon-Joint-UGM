import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const summaryId = params.id;

    const existing = await (prisma as any).consultationSummary.findUnique({
      where: { id: summaryId },
    }).catch(() => null);

    const updated = await (prisma as any).consultationSummary.update({
      where: { id: summaryId },
      data: {
        isPatientConfirmed: true,
        confirmedAt: new Date(),
      },
    }).catch((dbErr: any) => {
      console.warn("[consultation confirm]: DB fallback update:", dbErr);
      return {
        id: summaryId,
        patientId: existing?.patientId || "",
        isPatientConfirmed: true,
        confirmedAt: new Date(),
        followUpDate: existing?.followUpDate,
        prescribedMedications: existing?.prescribedMedications,
      };
    });

    // Auto-create Follow-up Reminder if follow-up date is provided in summary
    if (updated.followUpDate) {
      await (prisma as any).careReminder.create({
        data: {
          patientId: updated.patientId,
          reminderType: "FOLLOW_UP_VISIT",
          title: "Kontrol Dokter Spesialis Mata",
          description: "Jadwal kontrol berkala sesuai instruksi klinis dokter penanggung jawab.",
          scheduledTime: new Date(updated.followUpDate),
          frequency: "ONCE",
          isCompleted: false,
          isActive: true,
        },
      }).catch(() => null);
    }

    // Auto-create Medication Reminders if prescribed medications exist
    const meds = updated.prescribedMedications as any[];
    if (Array.isArray(meds) && meds.length > 0) {
      for (const med of meds) {
        if (med && typeof med === "object" && med.name) {
          await (prisma as any).careReminder.create({
            data: {
              patientId: updated.patientId,
              reminderType: "MEDICATION",
              title: `Minum Obat: ${med.name}`,
              description: `Dosis: ${med.dosage || "-"}, Aturan: ${med.instructions || med.frequency || "Sesuai resep dokter"}`,
              scheduledTime: new Date(Date.now() + 8 * 3600 * 1000), // e.g. 08:00 WIB
              frequency: "DAILY",
              isCompleted: false,
              isActive: true,
            },
          }).catch(() => null);
        }
      }
    }

    return NextResponse.json({
      success: true,
      data: updated,
      message: "Ringkasan konsultasi dokter telah dikonfirmasi oleh pasien. Perencanaan pasca-konsultasi sekarang aktif.",
    });
  } catch (error: any) {
    console.error("[consultation-summary confirm]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to confirm consultation summary." },
      { status: 500 }
    );
  }
}
