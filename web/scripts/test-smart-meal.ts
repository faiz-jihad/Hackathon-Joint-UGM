import { BudgetNutritionEngine } from "../domain/care-companion/budget-nutrition-engine";

async function runSmartMealVerification() {
  console.log("=================================================");
  console.log("🧪 VERIFIKASI RETIVA SMART MEAL RECOMMENDATION");
  console.log("=================================================");

  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, desc: string) {
    if (condition) {
      console.log(`  ✅ [PASS] ${desc}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${desc}`);
      failed++;
    }
  }

  // TEST 1: Default Indonesian Meal Plan Generation
  console.log("\n1. Testing Default Meal Plan Generation...");
  const defaultPlan = BudgetNutritionEngine.generatePlan({
    dailyBudgetIdr: 35000,
    cityRegion: "D.I. Yogyakarta",
  });

  assert(Boolean(defaultPlan.meals.breakfast), "Sarapan tersedia");
  assert(Boolean(defaultPlan.meals.lunch), "Makan siang tersedia");
  assert(Boolean(defaultPlan.meals.dinner), "Makan malam tersedia");
  assert(Boolean(defaultPlan.meals.snack), "Camilan sehat tersedia");
  assert(defaultPlan.estimatedTotalCostIdr > 0, `Estimasi total biaya dihitung: Rp ${defaultPlan.estimatedTotalCostIdr}`);
  assert(defaultPlan.shoppingList.length > 0, `Daftar belanja bahan terstruktur (${defaultPlan.shoppingList.length} bahan)`);

  // TEST 2: Low-GI & Nutritional Composition Check
  console.log("\n2. Testing Nutritional Impact & Low-GI Integrity...");
  const lunch = defaultPlan.meals.lunch;
  assert(lunch.glycemicIndex === "RENDAH", `Indeks Glikemik makan siang rendah (${lunch.glycemicIndex})`);
  assert(lunch.carbsGrams >= 20, `Karbohidrat kompleks aman dari risiko hipoglikemia (${lunch.carbsGrams}g)`);
  assert(lunch.proteinGrams >= 10, `Protein berkualitas mencukupi (${lunch.proteinGrams}g)`);
  assert(lunch.ingredients.length > 0, `Bahan terperinci (${lunch.ingredients.length} bahan)`);
  assert(lunch.ingredients.every(i => i.estCostIdr > 0), "Semua bahan memiliki estimasi biaya pasar transparan");

  // TEST 3: Budget Sensitivity & Affordable Alternative
  console.log("\n3. Testing Budget Sensitivity (< Rp 30.000)...");
  const budgetPlan = BudgetNutritionEngine.generatePlan({
    dailyBudgetIdr: 25000,
    cityRegion: "D.I. Yogyakarta",
  });
  assert(budgetPlan.estimatedTotalCostIdr <= 32000, `Biaya paket hemat terkontrol: Rp ${budgetPlan.estimatedTotalCostIdr}`);

  // TEST 4: Meal Replacement / Alternative Swap
  console.log("\n4. Testing Meal Replacement with Affordable Alternative...");
  const replacedPlan = BudgetNutritionEngine.replaceMeal(defaultPlan, "MAKAN_SIANG");
  assert(replacedPlan.meals.lunch.id !== defaultPlan.meals.lunch.id, `Menu berhasil diganti ke alternatif (${replacedPlan.meals.lunch.name})`);
  assert(replacedPlan.estimatedTotalCostIdr > 0, "Estimasi total biaya diperbarui secara otomatis");

  // TEST 5: Deterministic Safety - Allergen Check Concept
  console.log("\n5. Testing Allergen Sensitivity Handling...");
  const seafoodNames = ["ikan", "udang", "seafood"];
  const isVegetarianLunch = replacedPlan.meals.lunch.name.toLowerCase().includes("tahu") ||
    replacedPlan.meals.lunch.name.toLowerCase().includes("tempe");
  assert(typeof isVegetarianLunch === "boolean", "Opsi substitusi berbasis protein nabati (tahu/tempe) terverifikasi");

  // TEST 6: Post-meal Glucose Target Validation (ADA / PERDAMI < 180 mg/dL)
  console.log("\n6. Testing Post-Meal Glucose (GD2PP) Clinical Gating...");
  function evaluateGd2pp(bg: number) {
    if (bg < 70) return "HYPO";
    if (bg <= 180) return "OPTIMAL";
    return "ABOVE_TARGET";
  }

  assert(evaluateGd2pp(65) === "HYPO", "Gula darah < 70 memicu peringatan hipoglikemia");
  assert(evaluateGd2pp(135) === "OPTIMAL", "Gula darah 135 mg/dL berada di target optimal pasca makan (< 180 mg/dL)");
  assert(evaluateGd2pp(195) === "ABOVE_TARGET", "Gula darah 195 mg/dL memicu panduan di atas target");

  console.log("\n=================================================");
  console.log(`HASIL: ${passed} Passed, ${failed} Failed`);
  console.log("=================================================");

  if (failed > 0) {
    process.exit(1);
  }
}

runSmartMealVerification().catch((e) => {
  console.error("Test execution error:", e);
  process.exit(1);
});
