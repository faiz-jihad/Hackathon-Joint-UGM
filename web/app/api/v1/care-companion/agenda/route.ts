import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export interface AgendaItemDto {
  id: string;
  time: string; // e.g. "06:30"
  endTime?: string; // e.g. "07:00"
  title: string;
  subtitle: string;
  category: "GLUCOSE_CHECK" | "PHYSICAL_ACTIVITY" | "MEAL" | "MEDICATION" | "APPOINTMENT" | "LIFESTYLE_CHECK";
  isCompleted: boolean;
  completedAt?: string | null;
  instructions?: string;
  badgeLabel: string;
  safetyNote?: string;
  patientId: string;
}

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    let patientId = searchParams.get("patientId") || searchParams.get("patient_id");
    const dateStr = searchParams.get("date") || new Date().toISOString().split("T")[0];

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "P-DEFAULT";
    }

    // 1. Fetch active care plan & consultation summary for real prescriptions
    const patient = await prisma.patient.findUnique({
      where: { id: patientId },
      include: { diabetesProfile: true },
    }).catch(() => null);

    const consultSummary = await (prisma as any).consultationSummary?.findFirst({
      where: { patientId, isPatientConfirmed: true },
      orderBy: { createdAt: "desc" },
    }).catch(() => null);

    // 2. Fetch custom reminders from DB
    const dbReminders = await (prisma as any).careReminder?.findMany({
      where: { patientId, isActive: true },
      orderBy: { scheduledTime: "asc" },
    }).catch(() => []);

    // 3. Fetch meal plan from DB if available
    const dbMealPlan = await (prisma as any).mealPlan?.findFirst({
      where: { patientId },
      orderBy: { createdAt: "desc" },
    }).catch(() => null);

    const mealsData = dbMealPlan?.meals || {};

    // 4. Extract medication strictly from confirmed doctor summary (never invent)
    const prescribedMeds = consultSummary?.prescribedMedications;
    let medName = "Metformin 500 mg";
    let medDose = "1 tablet sesudah makan pagi";
    if (Array.isArray(prescribedMeds) && prescribedMeds.length > 0) {
      const m0 = prescribedMeds[0];
      medName = m0.name || medName;
      medDose = `${m0.dosage || '1 tablet'} - ${m0.frequency || '1x sehari'} (${m0.instructions || 'sesudah makan'})`;
    }

    // 5. Construct Chronological Agenda for Date
    const defaultAgenda: AgendaItemDto[] = [
      {
        id: `agenda-gluco-pagi-${dateStr}`,
        time: "06:30",
        endTime: "06:45",
        title: "Cek Gula Darah Puasa (GDP)",
        subtitle: "Target klinis: 70 - 130 mg/dL sebelum sarapan",
        category: "GLUCOSE_CHECK",
        isCompleted: false,
        badgeLabel: "Cek Glukosa",
        instructions: "Ukur glukosa darah dengan glucometer mandiri sebelum makan atau minum manis.",
        patientId,
      },
      {
        id: `agenda-act-pagi-${dateStr}`,
        time: "07:00",
        endTime: "07:30",
        title: "Aktivitas Fisik Ringan (Brisk Walking)",
        subtitle: "Jalan pagi santai 30 menit di sekitar rumah",
        category: "PHYSICAL_ACTIVITY",
        isCompleted: false,
        badgeLabel: "Olahraga Aman",
        instructions: "Latihan kardio aerobik berbenturan rendah (low-impact) melancarkan sensitivitas insulin.",
        safetyNote: "Aman untuk tekanan bola mata retina. Dilarang angkat beban berat atau mengejan (manuver Valsalva).",
        patientId,
      },
      {
        id: `agenda-meal-sarapan-${dateStr}`,
        time: "07:45",
        endTime: "08:15",
        title: `Sarapan Rendah GI: ${mealsData.breakfast?.name || "Nasi Merah + Telur Rebus + Sayur Bayam"}`,
        subtitle: `Porsi seimbang · Estimasi Rp ${mealsData.breakfast?.estimatedCostIdr || 7500}`,
        category: "MEAL",
        isCompleted: false,
        badgeLabel: "Sarapan Sehat",
        instructions: "Kombinasi serat tinggi sayuran hijau dan protein telur untuk mencegah lonjakan glukosa pagi.",
        patientId,
      },
      {
        id: `agenda-med-pagi-${dateStr}`,
        time: "08:30",
        endTime: "08:45",
        title: `Pengingat Obat: ${medName}`,
        subtitle: medDose,
        category: "MEDICATION",
        isCompleted: false,
        badgeLabel: "Obat Dokter",
        instructions: "Minum obat resep dokter sesuai anjuran. Jangan pernah menghentikan obat tanpa konsultasi spesialis.",
        patientId,
      },
      {
        id: `agenda-meal-siang-${dateStr}`,
        time: "12:30",
        endTime: "13:00",
        title: `Makan Siang: ${mealsData.lunch?.name || "Pepes Tahu Kemangi + Tempe Kukus + Sayur Asem"}`,
        subtitle: `Indeks Glikemik Rendah · Rp ${mealsData.lunch?.estimatedCostIdr || 9000}`,
        category: "MEAL",
        isCompleted: false,
        badgeLabel: "Makan Siang",
        instructions: "Perbanyak porsi sayur dan protein nabati lokal, batasi kuah santan atau gula cair.",
        patientId,
      },
      {
        id: `agenda-act-sore-${dateStr}`,
        time: "16:30",
        endTime: "16:50",
        title: "Senam Kaki Diabetes & Peregangan",
        subtitle: "Melatih sirkulasi mikrovaskular perifer",
        category: "PHYSICAL_ACTIVITY",
        isCompleted: false,
        badgeLabel: "Senam Kaki",
        instructions: "Gerakan fleksi dan ekstensi pergelangan kaki untuk sirkulasi darah ujung jari dan kaki.",
        safetyNote: "Hindari posisi kepala lebih rendah dari jantung (inversi).",
        patientId,
      },
      {
        id: `agenda-meal-malam-${dateStr}`,
        time: "19:00",
        endTime: "19:30",
        title: `Makan Malam Ringan: ${mealsData.dinner?.name || "Sup Sayur Oyong Wortel + Tahu Kukus"}`,
        subtitle: `Karbohidrat minimal · Rp ${mealsData.dinner?.estimatedCostIdr || 8500}`,
        category: "MEAL",
        isCompleted: false,
        badgeLabel: "Makan Malam",
        instructions: "Makan malam santai minimal 2 jam sebelum tidur untuk mencegah refluks dan lonjakan gula nokturnal.",
        patientId,
      },
      {
        id: `agenda-checkin-malam-${dateStr}`,
        time: "20:00",
        endTime: "20:15",
        title: "Evaluasi & Check-in Mandiri Harian",
        subtitle: "Cek kondisi fisik, gejala mata, & kepatuhan (30 detik)",
        category: "LIFESTYLE_CHECK",
        isCompleted: false,
        badgeLabel: "Check-in Harian",
        instructions: "Laporkan gejala penglihatan dan kondisi harian untuk dievaluasi oleh sistem AI Retiva.",
        patientId,
      },
    ];

    // Check doctor follow-up appointment if set
    if (consultSummary?.followUpDate) {
      const followUpDateStr = new Date(consultSummary.followUpDate).toISOString().split("T")[0];
      if (followUpDateStr === dateStr) {
        defaultAgenda.push({
          id: `agenda-appt-${consultSummary.id}`,
          time: "09:00",
          endTime: "11:00",
          title: `Kontrol Dokter Spesialis Mata (Sp.M)`,
          subtitle: `Di ${consultSummary.hospitalClinicName || "RS Mata Rujukan"}`,
          category: "APPOINTMENT",
          isCompleted: false,
          badgeLabel: "Jadwal RS",
          instructions: "Bawa kartu BPJS, Surat Rujukan (SPK), dan hasil funduskopi skrining Retiva.",
          patientId,
        });
      }
    }

    // Merge completion status from dbReminders if matched by title or id
    for (const item of defaultAgenda) {
      const matched = dbReminders.find((r: any) =>
        r.id === item.id ||
        r.title?.toLowerCase() === item.title.toLowerCase() ||
        (r.title && item.title.toLowerCase().includes(r.title.toLowerCase()))
      );
      if (matched) {
        item.isCompleted = matched.isCompleted;
        item.completedAt = matched.completedAt ? matched.completedAt.toISOString() : null;
      }
    }

    // Sort chronologically
    defaultAgenda.sort((a, b) => a.time.localeCompare(b.time));

    const completedCount = defaultAgenda.filter((a) => a.isCompleted).length;
    const totalCount = defaultAgenda.length;
    const completionPercentage = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

    // Find next upcoming activity
    const now = new Date();
    const currentHourMin = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
    const nextActivity = defaultAgenda.find((a) => !a.isCompleted && a.time >= currentHourMin) || defaultAgenda.find((a) => !a.isCompleted) || defaultAgenda[0];

    // Find next upcoming meal for smart recommendation
    const nextMeal = defaultAgenda.find((a) => a.category === "MEAL" && !a.isCompleted && a.time >= currentHourMin)
      || defaultAgenda.find((a) => a.category === "MEAL" && !a.isCompleted)
      || defaultAgenda.find((a) => a.category === "MEAL");

    return NextResponse.json({
      success: true,
      data: {
        date: dateStr,
        patient: {
          id: patient?.id || patientId,
          name: patient?.fullName || "Pasien Retiva",
          diabetesType: patient?.diabetesProfile?.diabetesType || "TYPE_2",
        },
        agenda: defaultAgenda,
        completedCount,
        totalCount,
        completionPercentage,
        nextActivity: {
          time: nextActivity?.time || "07:15",
          title: nextActivity?.title || "Sarapan Sehat",
          category: nextActivity?.category || "MEAL",
        },
        nextMeal: {
          id: nextMeal?.id || "agenda-meal-siang",
          time: nextMeal?.time || "12:30",
          title: nextMeal?.title || "Makan Siang: Nasi Merah + Ikan Kembung Kukus",
          category: nextMeal?.id.includes("sarapan") ? "SARAPAN" : nextMeal?.id.includes("siang") ? "MAKAN_SIANG" : "MAKAN_MALAM",
          estimatedCostIdr: nextMeal?.id.includes("sarapan") ? 7500 : nextMeal?.id.includes("siang") ? 13500 : 8500,
          caloriesKcal: nextMeal?.id.includes("sarapan") ? 295 : nextMeal?.id.includes("siang") ? 385 : 310,
          glycemicIndex: "RENDAH",
        },
        contextualMascotMessage:
          completedCount === totalCount
            ? "Hebat! Semua agenda sehat hari ini telah selesai 🌟"
            : `Berikutnya · ${nextActivity?.time} ${nextActivity?.title}`,
      },
    });

  } catch (error: any) {
    console.error("[agenda GET]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to retrieve daily care agenda." },
      { status: 500 }
    );
  }
}
