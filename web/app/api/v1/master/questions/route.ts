import { NextRequest, NextResponse } from "next/server";
import { CareCompanionMasterStore } from "@/infrastructure/database/care-companion-master-store";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const category = searchParams.get("category") || undefined;

    const questions = await CareCompanionMasterStore.getAllQuestions(category);

    return NextResponse.json({
      success: true,
      count: questions.length,
      data: questions,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch master questions" },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    if (!body.questionText) {
      return NextResponse.json(
        { success: false, error: "Teks pertanyaan dokter wajib diisi" },
        { status: 400 }
      );
    }

    const created = await CareCompanionMasterStore.createQuestion({
      questionText: body.questionText,
      category: body.category || "Umum",
      orderIndex: Number(body.orderIndex || 0),
      isActive: body.isActive ?? true,
    });

    return NextResponse.json({
      success: true,
      message: "Pertanyaan dokter berhasil ditambahkan ke database master",
      data: created,
    }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create master question" },
      { status: 500 }
    );
  }
}
