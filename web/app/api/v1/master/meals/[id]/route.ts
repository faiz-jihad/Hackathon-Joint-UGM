import { NextRequest, NextResponse } from "next/server";
import { CareCompanionMasterStore } from "@/infrastructure/database/care-companion-master-store";

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const meal = await CareCompanionMasterStore.getMealById(params.id);
    if (!meal) {
      return NextResponse.json(
        { success: false, error: "Menu makanan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({ success: true, data: meal });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to get meal" },
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
    const updated = await CareCompanionMasterStore.updateMeal(params.id, body);
    if (!updated) {
      return NextResponse.json(
        { success: false, error: "Menu makanan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({
      success: true,
      message: "Menu makanan berhasil diperbarui",
      data: updated,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to update meal" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const deleted = await CareCompanionMasterStore.deleteMeal(params.id);
    if (!deleted) {
      return NextResponse.json(
        { success: false, error: "Menu makanan tidak ditemukan" },
        { status: 404 }
      );
    }
    return NextResponse.json({
      success: true,
      message: "Menu makanan berhasil dihapus dari master",
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to delete meal" },
      { status: 500 }
    );
  }
}
