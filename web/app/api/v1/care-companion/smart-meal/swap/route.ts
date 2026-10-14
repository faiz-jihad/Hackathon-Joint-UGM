import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const {
      currentMealId,
      substitutionType,
      category = "LUNCH",
    } = body;

    let swappedMeal;
    if (substitutionType === "VEGETARIAN_ECONOMICAL" || substitutionType === "PLANT_BASED_BUDGET") {
      swappedMeal = {
        id: `swapped-${Date.now()}`,
        category: category === "BREAKFAST" ? "SARAPAN" : "MAKAN_SIANG",
        time_recommendation: category === "BREAKFAST" ? "07.15" : "12.30",
        name: "Nasi Jagung Pulen, Pepes Tahu Tempe Kemangi & Sayur Asem",
        main_dish: "Pepes Tahu & Tempe Kukus Daun Kemangi (2 Bungkus)",
        complementary_foods: ["Nasi Jagung Pulen 100g", "Sayur Asem Bening Labu Siam & Kacang Panjang", "Lalap Timun"],
        suggested_portion: "Piring Model T: 1/2 sayur asem labu siam, 1/4 nasi jagung, 1/4 pepes tahu tempe.",
        ingredients: [
          { name: "Beras Jagung Lokal", quantity: "80 gram", est_cost_idr: 1800 },
          { name: "Tempe Kedelai Murni", quantity: "2 potong (70g)", est_cost_idr: 2500 },
          { name: "Tahu Putih Lembut", quantity: "1 kotak (60g)", est_cost_idr: 1700 },
          { name: "Sayuran Asem", quantity: "1 mangkuk", est_cost_idr: 2500 },
          { name: "Bumbu Pepes Rempah", quantity: "Secukupnya", est_cost_idr: 1500 },
        ],
        estimated_cost_idr: 10000,
        affordable_alternatives: [],
        nutrition: {
          calories_kcal: 340,
          carbs_grams: 34,
          fiber_grams: 8.5,
          protein_grams: 17,
          glycemic_index: "RENDAH",
          sodium_mg: 190,
        },
        nutritional_impact_explanation: {
          carbohydrate_impact: "Karbohidrat kompleks dari jagung memberi energi stabil siang hari.",
          fiber_impact: "Serat melimpah dari sayuran memperlambat laju absorpsi glukosa.",
          protein_vascular_impact: "Protein nabati tempe dan tahu bebas kolesterol jenuh dan ramah ginjal.",
          glucose_stability_summary: "Substitusi ekonomis hemat biaya hingga Rp 4.500 dengan manfaat glikemik setara.",
        },
        is_eaten: false,
        eaten_at: null,
        post_meal_glucose_mg_dl: null,
      };
    } else {
      // General swap fallback
      swappedMeal = {
        id: `swapped-${Date.now()}`,
        category: "MAKAN_SIANG",
        time_recommendation: "12.30",
        name: "Nasi Merah, Dada Ayam Ungkep Kuning & Labu Siam Bening",
        main_dish: "Dada Ayam Ungkep Kuning (70g)",
        complementary_foods: ["Nasi Merah 100g", "Labu Siam Bening 1 Mangkuk", "Tempe Bakar 1 Potong"],
        suggested_portion: "Piring Sehat: 1/2 sayur labu siam, 1/4 nasi merah, 1/4 ayam ungkep.",
        ingredients: [
          { name: "Beras Merah", quantity: "75 gram", est_cost_idr: 2000 },
          { name: "Dada Ayam", quantity: "70 gram", est_cost_idr: 7000 },
          { name: "Labu Siam", quantity: "1/2 buah", est_cost_idr: 2000 },
          { name: "Tempe", quantity: "1 potong", est_cost_idr: 1000 },
          { name: "Bumbu Kuning", quantity: "Secukupnya", est_cost_idr: 1500 },
        ],
        estimated_cost_idr: 13500,
        affordable_alternatives: [],
        nutrition: {
          calories_kcal: 360,
          carbs_grams: 29,
          fiber_grams: 6.5,
          protein_grams: 24,
          glycemic_index: "RENDAH",
          sodium_mg: 200,
        },
        nutritional_impact_explanation: {
          carbohydrate_impact: "Karbohidrat kompleks nasi merah menjaga stabilitas gula darah.",
          fiber_impact: "Serat labu siam mengikat lemak dan memperlambat pencernaan.",
          protein_vascular_impact: "Protein unggas tanpa lemak mendukung stamina dan regenerasi sel tubuh.",
          glucose_stability_summary: "Komposisi seimbang untuk mengendalikan glukosa 2 jam pasca makan.",
        },
        is_eaten: false,
        eaten_at: null,
        post_meal_glucose_mg_dl: null,
      };
    }

    return NextResponse.json({
      success: true,
      message: "Menu berhasil diganti dengan alternatif pilihan Anda.",
      data: swappedMeal,
    });
  } catch (error: any) {
    console.error("[smart-meal swap POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to swap meal alternative." },
      { status: 500 }
    );
  }
}
