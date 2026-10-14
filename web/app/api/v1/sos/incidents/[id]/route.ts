import { NextRequest, NextResponse } from "next/server";
import { EmergencyStore, EmergencyIncidentStatus } from "@/infrastructure/database/emergency-store";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const incident = await EmergencyStore.getIncidentById(id);

    if (!incident) {
      return NextResponse.json(
        { success: false, error: "Insiden darurat tidak ditemukan." },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      data: incident,
    });
  } catch (error: any) {
    console.error("[api/sos/incidents/[id]] GET Error:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal mengambil data insiden." },
      { status: 500 }
    );
  }
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await req.json().catch(() => ({}));
    const { status, responderId, responderName, notes, actionTaken, followUpNote } = body;

    const existing = await EmergencyStore.getIncidentById(id);
    if (!existing) {
      return NextResponse.json(
        { success: false, error: "Insiden darurat tidak ditemukan." },
        { status: 404 }
      );
    }

    // 1. Status transition if provided
    let updated = existing;
    if (status && ["ACTIVE", "ACKNOWLEDGED", "RESOLVED", "CANCELLED"].includes(status)) {
      const res = await EmergencyStore.updateIncidentStatus(
        id,
        status as EmergencyIncidentStatus,
        responderId,
        responderName,
        notes
      );
      if (res) updated = res;
    }

    // 2. Add follow-up note if provided
    if (followUpNote || notes) {
      const noteText = followUpNote || notes;
      await EmergencyStore.addFollowUp(
        id,
        responderId || "usr-doctor",
        responderName || "Dokter Retiva",
        noteText,
        actionTaken
      );
      const reloaded = await EmergencyStore.getIncidentById(id);
      if (reloaded) updated = reloaded;
    }

    return NextResponse.json({
      success: true,
      message: "Status insiden berhasil diperbarui.",
      data: updated,
    });
  } catch (error: any) {
    console.error("[api/sos/incidents/[id]] PATCH Error:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal memperbarui insiden." },
      { status: 500 }
    );
  }
}
