import { NextRequest, NextResponse } from "next/server";
import { BudgetNutritionEngine } from "@/domain/care-companion/budget-nutrition-engine";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const { currentPlan, category, replacementMealId } = body;

    if (!currentPlan || !category) {
      return NextResponse.json(
        { success: false, error: "currentPlan and category are required parameters." },
        { status: 400 }
      );
    }

    const updatedPlan = await BudgetNutritionEngine.replaceMealAsync(currentPlan, category, replacementMealId);

    return NextResponse.json({
      success: true,
      data: updatedPlan,
      message: `Menu ${category} berhasil diganti dan anggaran otomatis dihitung ulang.`,
    });
  } catch (error: any) {
    console.error("[meal-plan replace-meal]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to replace meal." },
      { status: 500 }
    );
  }
}
