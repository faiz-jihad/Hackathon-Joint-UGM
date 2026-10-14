import { NextRequest, NextResponse } from "next/server";
import { CareCompanionMasterStore } from "@/infrastructure/database/care-companion-master-store";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const category = searchParams.get("category") || undefined;
    const search = searchParams.get("search") || undefined;

    const meals = await CareCompanionMasterStore.getAllMeals(category, search);

    return NextResponse.json({
      success: true,
      count: meals.length,
      data: meals,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch master meals" },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    if (!body.name || !body.category || body.estimatedCostIdr === undefined) {
      return NextResponse.json(
        { success: false, error: "Nama, kategori, dan estimasi harga wajib diisi" },
        { status: 400 }
      );
    }

    const created = await CareCompanionMasterStore.createMeal({
      name: body.name,
      category: body.category,
      portion: body.portion || "1 porsi",
      estimatedCostIdr: Number(body.estimatedCostIdr),
      glycemicIndex: body.glycemicIndex || "LOW",
      carbsGrams: Number(body.carbsGrams || 20),
      proteinGrams: Number(body.proteinGrams || 15),
      ingredients: Array.isArray(body.ingredients) ? body.ingredients : [],
      preparationNotes: body.preparationNotes || "",
      isActive: body.isActive ?? true,
    });

    return NextResponse.json({
      success: true,
      message: "Menu makanan berhasil ditambahkan ke database master",
      data: created,
    }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create master meal" },
      { status: 500 }
    );
  }
}
