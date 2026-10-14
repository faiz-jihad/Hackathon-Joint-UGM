import { NextRequest, NextResponse } from "next/server";
import { BudgetNutritionEngine } from "@/domain/care-companion/budget-nutrition-engine";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const {
      dailyBudgetIdr = 35000,
      cityRegion = "D.I. Yogyakarta",
      allergies = [],
      restrictions = [],
      preferredProteins = [],
      isGeneralEducation = true,
      clinicianDietaryNotes,
    } = body;

    const planResult = await BudgetNutritionEngine.generatePlanAsync({
      dailyBudgetIdr: Number(dailyBudgetIdr),
      cityRegion,
      allergies,
      restrictions,
      preferredProteins,
      isGeneralEducation: Boolean(isGeneralEducation),
      clinicianDietaryNotes,
    });

    return NextResponse.json({
      success: true,
      data: planResult,
    });
  } catch (error: any) {
    console.error("[meal-plan generate]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to generate meal plan." },
      { status: 500 }
    );
  }
}
