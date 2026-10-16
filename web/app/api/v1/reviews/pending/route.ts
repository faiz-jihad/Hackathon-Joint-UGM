import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

// In-memory shared state for live real-time sync across mobile and web
export interface PendingReviewRecord {
  id: string;
  patientId: string;
  patientName: string;
  patientNik: string;
  eye: "OD" | "OS";
  capturedAt: string;
  qualityCheck: {
    passed: boolean;
    sharpness: number;
    illumination: number;
    coverage: number;
  };
  aiResult: {
    drGrade: string;
    drLabel: string;
    confidence: number;
    reliability: string;
    probabilities: Array<{ grade: string; label: string; prob: number }>;
    gradCamFocus: string;
    overlayUrl?: string;
  };
  reliability: string;
  reliabilityLabel: string;
  humanReview: {
    status: "PENDING" | "CONFIRMED_AI" | "OVERRIDDEN";
    reviewerName: string;
    reviewerNip?: string;
    reviewerSip?: string;
  };
  recommendation: {
    action: string;
    interval: string;
    referralNeeded: boolean;
    urgencyDays: number;
    notes: string;
  };
  imageHash: string;
}

const g = globalThis as unknown as {
  _pendingReviewsList?: PendingReviewRecord[];
};

if (!g._pendingReviewsList || g._pendingReviewsList.length === 0) {
  g._pendingReviewsList = [
    {
      id: "RTV-20261015-39",
      patientId: "pat-006",
      patientName: "Ibu Endang Rahayu",
      patientNik: "3402015206780004",
      eye: "OD",
      capturedAt: "2026-10-15T07:33:00.000Z",
      qualityCheck: {
        passed: true,
        sharpness: 0.85,
        illumination: 0.88,
        coverage: 0.92,
      },
      aiResult: {
        drGrade: "MODERATE_NPDR",
        drLabel: "Retinopati Diabetik Non-Proliferatif Sedang",
        confidence: 62.0,
        reliability: "LOW",
        probabilities: [
          { grade: "NO_DR", label: "Tidak Ada DR", prob: 8.0 },
          { grade: "MILD_NPDR", label: "NPDR Ringan", prob: 25.0 },
          { grade: "MODERATE_NPDR", label: "NPDR Sedang", prob: 62.0 },
          { grade: "SEVERE_NPDR", label: "NPDR Berat", prob: 4.0 },
          { grade: "PDR", label: "PDR Proliferatif", prob: 1.0 },
        ],
        gradCamFocus: "Area Mikroaneurisma & Perdarahan Makula (Borderline 62%)",
        overlayUrl: "/images/fundus_borderline_sample.jpg",
      },
      reliability: "NEEDS_REVIEW",
      reliabilityLabel: "Perlu Review Spesialis",
      humanReview: {
        status: "PENDING",
        reviewerName: "dr. Yunani Setyandriana, Sp.M",
        reviewerNip: "198204122010121003",
        reviewerSip: "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
      },
      recommendation: {
        action: "Telaah klinis spesialis mata (Sp.M) untuk verifikasi retinopati diabetik derajat sedang.",
        interval: "1x24 Jam Kerja",
        referralNeeded: true,
        urgencyDays: 14,
        notes: "Kasus dialihkan ke antrean telaah dokter spesialis mata mitra (dr. Yunani Setyandriana, Sp.M).",
      },
      imageHash: "hash-rtv-20261015-39",
    },
  ];
}

const pendingList = g._pendingReviewsList;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-retiva-clinical",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function GET(req: NextRequest) {
  try {
    // 1. Ambil data skrining yang butuh telaah spesialis dari PostgreSQL database
    let mappedFromDb: PendingReviewRecord[] = [];
    try {
      const dbPending = await prisma.screening.findMany({
        where: {
          NOT: { id: { startsWith: "scr_" } },
        },
        include: {
          patient: true,
          images: true,
          aiResults: true,
          humanReview: true,
          recommendation: true,
        },
        orderBy: { createdAt: "desc" },
        take: 20,
      });

      mappedFromDb = dbPending.map((s) => {
        const eye = (s.images[0]?.eye || "OD") as "OD" | "OS";
        const predClass = s.aiResults[0]?.predictedClass || "MODERATE_DR";
        const confidence = Number(s.aiResults[0]?.confidence || 0.62) * 100;

        return {
          id: s.id,
          patientId: s.patientId,
          patientName: s.patient?.fullName || "Pasien Terdaftar",
          patientNik: s.patient?.nik || "3404015508750001",
          eye,
          capturedAt: s.createdAt.toISOString(),
          qualityCheck: {
            passed: true,
            sharpness: 0.82,
            illumination: 0.85,
            coverage: 0.90,
          },
          aiResult: {
            drGrade: predClass === "MODERATE_DR" ? "MODERATE_NPDR" : predClass,
            drLabel: predClass === "MODERATE_DR" ? "Retinopati Diabetik Non-Proliferatif Sedang" : predClass,
            confidence,
            reliability: "LOW",
            probabilities: [
              { grade: "NO_DR", label: "Tidak Ada DR", prob: 8.0 },
              { grade: "MILD_NPDR", label: "NPDR Ringan", prob: 25.0 },
              { grade: "MODERATE_NPDR", label: "NPDR Sedang", prob: 62.0 },
              { grade: "SEVERE_NPDR", label: "NPDR Berat", prob: 4.0 },
              { grade: "PDR", label: "PDR Proliferatif", prob: 1.0 },
            ],
            gradCamFocus: "Area Mikroaneurisma & Perdarahan Makula (Borderline 62%)",
            overlayUrl: "/images/fundus_borderline_sample.jpg",
          },
          reliability: "NEEDS_REVIEW",
          reliabilityLabel: "Perlu Review Spesialis",
          humanReview: {
            status: s.humanReview ? (s.humanReview.reviewStatus as any) : "PENDING",
            reviewerName: "dr. Yunani Setyandriana, Sp.M",
            reviewerNip: "198204122010121003",
          },
          recommendation: {
            action: s.recommendation?.recommendedAction || "Telaah klinis spesialis mata (Sp.M)",
            interval: "1x24 Jam Kerja",
            referralNeeded: true,
            urgencyDays: 14,
            notes: s.recommendation?.summary || "Margin keyakinan borderline.",
          },
          imageHash: s.images[0]?.checksum || "default-hash",
        };
      });
    } catch (_) {}

    // 2. Gabungkan antrean in-memory dengan data database (database diutamakan agar nama pasien selalu akurat dan dinamis)
    const combinedMap = new Map<string, PendingReviewRecord>();
    for (const item of pendingList) {
      combinedMap.set(item.id, item);
      combinedMap.set(item.id.replace(/^#/, ""), item);
    }
    for (const item of mappedFromDb) {
      combinedMap.set(item.id, item);
      combinedMap.set(item.id.replace(/^#/, ""), item);
    }

    const result = Array.from(new Set(combinedMap.values())).filter(
      (item) => !item.id.toLowerCase().startsWith("scr_")
    );
    return NextResponse.json({ success: true, data: result }, { headers: corsHeaders });
  } catch (error) {
    return NextResponse.json({ success: true, data: pendingList }, { headers: corsHeaders });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const rawId = body.id || body.screeningId || `RTV-${Date.now()}`;
    const cleanId = String(rawId).replace(/^#/, "");

    const newRecord: PendingReviewRecord = {
      id: cleanId,
      patientId: body.patientId || "pat-001",
      patientName: body.patientName || "Bapak Sutrisno",
      patientNik: body.patientNik || "3404015508750001",
      eye: (body.eye === "OS" || body.eyePosition === "OS") ? "OS" : "OD",
      capturedAt: body.capturedAt || new Date().toISOString(),
      qualityCheck: body.qualityCheck || {
        passed: true,
        sharpness: 0.85,
        illumination: 0.88,
        coverage: 0.92,
      },
      aiResult: body.aiResult || {
        drGrade: body.drGrade || "MODERATE_NPDR",
        drLabel: body.drLabel || "Retinopati Diabetik Non-Proliferatif Sedang",
        confidence: Number(body.confidence || 62.0),
        reliability: "LOW",
        probabilities: [
          { grade: "NO_DR", label: "Tidak Ada DR", prob: 8.0 },
          { grade: "MILD_NPDR", label: "NPDR Ringan", prob: 25.0 },
          { grade: "MODERATE_NPDR", label: "NPDR Sedang", prob: 62.0 },
          { grade: "SEVERE_NPDR", label: "NPDR Berat", prob: 4.0 },
          { grade: "PDR", label: "PDR Proliferatif", prob: 1.0 },
        ],
        gradCamFocus: "Area Mikroaneurisma & Perdarahan Makula (Borderline 62%)",
        overlayUrl: "/images/fundus_borderline_sample.jpg",
      },
      reliability: "NEEDS_REVIEW",
      reliabilityLabel: "Perlu Review Spesialis",
      humanReview: {
        status: "PENDING",
        reviewerName: body.doctorName || "dr. Yunani Setyandriana, Sp.M",
        reviewerSip: body.doctorSip || "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
      },
      recommendation: body.recommendation || {
        action: "Telaah klinis spesialis mata (Sp.M) untuk verifikasi retinopati diabetik derajat sedang.",
        interval: "1x24 Jam Kerja",
        referralNeeded: true,
        urgencyDays: 14,
        notes: `Kasus dialihkan ke antrean telaah dokter spesialis mata mitra (${body.doctorName || "dr. Yunani Setyandriana, Sp.M"}).`,
      },
      imageHash: body.imageHash || "hash-" + Date.now(),
    };

    // Simpan ke antrean in-memory shared
    const existingIdx = pendingList.findIndex(
      (p) => p.id === cleanId || p.id === rawId || p.id.replace(/^#/, "") === cleanId
    );
    if (existingIdx !== -1) {
      pendingList[existingIdx] = newRecord;
    } else {
      pendingList.unshift(newRecord);
    }

    // Pastikan kasus ini berstatus belum ditelaah (PENDING) di reviewsMap
    const gAny = globalThis as any;
    if (gAny._adjudicatedReviewsMap) {
      gAny._adjudicatedReviewsMap.delete(cleanId);
      gAny._adjudicatedReviewsMap.delete(rawId);
      gAny._adjudicatedReviewsMap.delete(`#${cleanId}`);
    }

    // Usahakan simpan ke PostgreSQL database juga
    try {
      let patient = await prisma.patient.findFirst({
        where: { OR: [{ nik: newRecord.patientNik }, { fullName: newRecord.patientName }] },
      });
      if (!patient) {
        patient = await prisma.patient.findFirst();
      }
      if (patient) {
        const actor = await prisma.user.findFirst({
          where: { role: { in: ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST"] } },
        });
        await prisma.screening.upsert({
          where: { id: cleanId },
          create: {
            id: cleanId,
            patientId: patient.id,
            conductedById: actor?.id || "usr-clinician-001",
            status: "HUMAN_REVIEW",
          },
          update: {
            status: "HUMAN_REVIEW",
          },
        });
      }
    } catch (e) {
      console.warn("DB upsert warning for pending review:", e);
    }

    return NextResponse.json({ success: true, data: newRecord }, { headers: corsHeaders });
  } catch (error) {
    return NextResponse.json({ success: false, error: "Failed to submit review" }, { status: 500, headers: corsHeaders });
  }
}
