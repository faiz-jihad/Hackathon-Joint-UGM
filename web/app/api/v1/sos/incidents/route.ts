import { NextRequest, NextResponse } from "next/server";
import { EmergencyStore } from "@/infrastructure/database/emergency-store";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const status = searchParams.get("status") || "ALL";
    const urgency = searchParams.get("urgency") || "ALL";
    const search = searchParams.get("search") || "";

    const [incidents, stats] = await Promise.all([
      EmergencyStore.getIncidents({ status, urgency, search }),
      EmergencyStore.getStats(),
    ]);

    return NextResponse.json({
      success: true,
      stats,
      data: incidents,
      meta: {
        totalReturned: incidents.length,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error("[api/sos/incidents] GET Error:", error);
    return NextResponse.json(
      {
        success: false,
        error: error?.message || "Gagal mengambil daftar insiden darurat.",
      },
      { status: 500 }
    );
  }
}
