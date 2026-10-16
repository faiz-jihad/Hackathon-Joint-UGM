import { NextRequest, NextResponse } from "next/server";

// In-memory shared state for live real-time sync across mobile and web
// Supports serverless globalThis persistence during Next.js process runtime
interface ReviewStatusRecord {
  isReviewed: boolean;
  doctorName: string;
  doctorRole: string;
  doctorSip: string;
  notes?: string;
  adjudicatedAt: string;
  adjudicationAction?: "CONFIRM_AI" | "OVERRIDE";
  confirmedGrade?: string;
  overrideGrade?: string;
  finalGrade?: string;
  finalLabel?: string;
}

const g = globalThis as unknown as {
  _adjudicatedReviewsMap?: Map<string, ReviewStatusRecord>;
};

if (!g._adjudicatedReviewsMap) {
  g._adjudicatedReviewsMap = new Map<string, ReviewStatusRecord>();
}

const reviewsMap = g._adjudicatedReviewsMap;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: corsHeaders,
  });
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const screeningId = searchParams.get("screeningId") || "";

  if (!screeningId) {
    return NextResponse.json(
      {
        success: true,
        data: {
          isReviewed: false,
        },
      },
      { headers: corsHeaders }
    );
  }

  // Check exact ID or normalized ID (e.g. without '#' or with '#')
  const cleanId = screeningId.replace(/^#/, "").trim();
  const rawWithHash = `#${cleanId}`;

  // 1. Cek langsung di reviewsMap untuk ID kasus spesifik ini
  let record =
    reviewsMap.get(cleanId) ||
    reviewsMap.get(rawWithHash) ||
    reviewsMap.get(screeningId);

  // 2. Jika tidak ada di reviewsMap, cek di pendingReviewsList
  const gAny = globalThis as any;
  if (!record && gAny._pendingReviewsList && Array.isArray(gAny._pendingReviewsList)) {
    const pendingItem = gAny._pendingReviewsList.find(
      (p: any) =>
        p.id === cleanId ||
        p.id === rawWithHash ||
        p.id === screeningId ||
        p.id.replace(/^#/, "") === cleanId
    );
    if (pendingItem) {
      if (
        pendingItem.humanReview?.status === "CONFIRMED_AI" ||
        pendingItem.humanReview?.status === "OVERRIDDEN"
      ) {
        record = {
          isReviewed: true,
          doctorName: pendingItem.humanReview.reviewerName || "dr. Yunani Setyandriana, Sp.M",
          doctorRole: "Spesialis Vitreoretina & Oftalmologi",
          doctorSip: pendingItem.humanReview.reviewerSip || "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
          notes:
            pendingItem.humanReview.clinicalNotes ||
            pendingItem.recommendation?.notes ||
            "Telaah klinis dokter spesialis mata terverifikasi.",
          adjudicatedAt: pendingItem.humanReview.adjudicatedAt || new Date().toISOString(),
        };
      } else {
        // Kasus masih PENDING di antrean
        record = {
          isReviewed: false,
          doctorName: pendingItem.humanReview?.reviewerName || "dr. Yunani Setyandriana, Sp.M",
          doctorRole: "Spesialis Vitreoretina & Oftalmologi",
          doctorSip: pendingItem.humanReview?.reviewerSip || "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
          notes: "",
          adjudicatedAt: "",
        };
      }
    }
  }

  if (record) {
    return NextResponse.json(
      {
        success: true,
        data: {
          screeningId: cleanId,
          isReviewed: Boolean(record.isReviewed),
          doctorName: record.doctorName || "dr. Yunani Setyandriana, Sp.M",
          doctorRole: record.doctorRole || "Spesialis Vitreoretina & Oftalmologi",
          doctorSip: record.doctorSip || "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
          notes: record.notes || "",
          adjudicatedAt: record.adjudicatedAt || new Date().toISOString(),
          adjudicationAction: record.adjudicationAction || "CONFIRM_AI",
          confirmedGrade: record.confirmedGrade || record.finalGrade || "MODERATE_NPDR",
          overrideGrade: record.overrideGrade,
          finalGrade: record.finalGrade || record.confirmedGrade || "MODERATE_NPDR",
          finalLabel: record.finalLabel || "",
        },
      },
      { headers: corsHeaders }
    );
  }

  return NextResponse.json(
    {
      success: true,
      data: {
        screeningId: cleanId,
        isReviewed: false,
      },
    },
    { headers: corsHeaders }
  );
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      screeningId,
      isReviewed = true,
      doctorName = "dr. Yunani Setyandriana, Sp.M",
      doctorRole = "Spesialis Vitreoretina & Oftalmologi",
      doctorSip = "SIP: 446.1/1982/SIP-D/2024 (RTV-0003)",
      notes,
      adjudicationAction = "CONFIRM_AI",
      confirmedGrade,
      overrideGrade,
      finalGrade,
      finalLabel,
    } = body;

    if (!screeningId) {
      return NextResponse.json(
        { success: false, error: "screeningId is required" },
        { status: 400, headers: corsHeaders }
      );
    }

    const record: ReviewStatusRecord = {
      isReviewed: Boolean(isReviewed),
      doctorName,
      doctorRole,
      doctorSip,
      notes,
      adjudicatedAt: new Date().toISOString(),
      adjudicationAction,
      confirmedGrade: confirmedGrade || finalGrade,
      overrideGrade,
      finalGrade: finalGrade || confirmedGrade,
      finalLabel,
    };

    const cleanId = String(screeningId).replace(/^#/, "").trim();
    const rawWithHash = `#${cleanId}`;

    // Simpan status adjudikasi KHUSUS untuk ID kasus ini saja
    reviewsMap.set(screeningId, record);
    reviewsMap.set(cleanId, record);
    reviewsMap.set(rawWithHash, record);

    // Update status in pendingReviewsList jika ada
    const gAny = globalThis as any;
    if (gAny._pendingReviewsList && Array.isArray(gAny._pendingReviewsList)) {
      const found = gAny._pendingReviewsList.find(
        (p: any) =>
          p.id === cleanId ||
          p.id === screeningId ||
          p.id.replace(/^#/, "") === cleanId
      );
      if (found) {
        found.humanReview = {
          status: "CONFIRMED_AI",
          reviewerName: doctorName,
          reviewerSip: doctorSip,
          clinicalNotes: notes,
          adjudicatedAt: record.adjudicatedAt,
        };
      }
    }

    return NextResponse.json(
      {
        success: true,
        message: "Adjudication status synchronized successfully.",
        data: record,
      },
      { headers: corsHeaders }
    );
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        error: "Failed to update review status",
      },
      { status: 500, headers: corsHeaders }
    );
  }
}
