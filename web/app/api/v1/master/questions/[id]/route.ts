import { NextRequest, NextResponse } from "next/server";
import { CareCompanionMasterStore } from "@/infrastructure/database/care-companion-master-store";

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const questions = await CareCompanionMasterStore.getAllQuestions();
    const q = questions.find((item) => item.id === params.id);
    if (!q) {
      return NextResponse.json(
        { success: false, error: "Pertanyaan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({ success: true, data: q });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to get question" },
      { status: 500 }
    );
  }
}

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await req.json();
    const updated = await CareCompanionMasterStore.updateQuestion(params.id, body);
    if (!updated) {
      return NextResponse.json(
        { success: false, error: "Pertanyaan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({
      success: true,
      message: "Pertanyaan dokter berhasil diperbarui",
      data: updated,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to update question" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const deleted = await CareCompanionMasterStore.deleteQuestion(params.id);
    if (!deleted) {
      return NextResponse.json(
        { success: false, error: "Pertanyaan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({
      success: true,
      message: "Pertanyaan dokter berhasil dihapus dari master",
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to delete question" },
      { status: 500 }
    );
  }
}
