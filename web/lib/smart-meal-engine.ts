export interface PersonalizeArgs {
  category: string;
  dailyBudget: number;
  allergies: string[];
  dietaryRestrictions: string[];
  availableIngredients: string[];
}

export interface SmartMealResult {
  id: string;
  category: string;
  time_recommendation: string;
  name: string;
  main_dish: string;
  complementary_foods: string[];
  suggested_portion: string;
  ingredients: Array<{ name: string; quantity: string; est_cost_idr: number }>;
  estimated_cost_idr: number;
  affordable_alternatives: Array<{
    title: string;
    savings_idr: number;
    description: string;
    substitution_type: string;
  }>;
  nutrition: {
    calories_kcal: number;
    carbs_grams: number;
    fiber_grams: number;
    protein_grams: number;
    glycemic_index: string;
    sodium_mg: number;
  };
  nutritional_impact_explanation: {
    carbohydrate_impact: string;
    fiber_impact: string;
    protein_vascular_impact: string;
    glucose_stability_summary: string;
  };
  personalization_tags: string[];
  is_eaten: boolean;
  eaten_at: string | null;
  post_meal_glucose_mg_dl: number | null;
}

export function generatePersonalizedMeal(args: PersonalizeArgs): SmartMealResult {
  const {
    category,
    dailyBudget = 35000,
    allergies = [],
    dietaryRestrictions = [],
    availableIngredients = [],
  } = args;
  const cat = (category || "LUNCH").toUpperCase();

  // Normalize filters
  const lowerAllergies = allergies.map((a) => a.toLowerCase().trim());
  const lowerRestrictions = dietaryRestrictions.map((r) => r.toLowerCase().trim());
  const pantryRaw = availableIngredients.join(" ").toLowerCase();

  // 1. Allergies Detection
  const hasSeafoodAllergy = lowerAllergies.some((a) => a.includes("seafood") || a.includes("ikan"));
  const hasUdangAllergy = lowerAllergies.some((a) => a.includes("udang")) || hasSeafoodAllergy;
  const hasEggAllergy = lowerAllergies.some((a) => a.includes("telur"));
  const hasPeanutAllergy = lowerAllergies.some((a) => a.includes("kacang"));

  // 2. Clinical Restrictions Detection
  const hasNephropathy = lowerRestrictions.some((r) => r.includes("nefropati") || r.includes("ginjal"));
  const hasLowSalt = lowerRestrictions.some(
    (r) => r.includes("rendah_garam") || r.includes("garam") || r.includes("hipertensi")
  );

  // 3. Pantry Ingredients Detection
  const hasTahuPantry = pantryRaw.includes("tahu");
  const hasTempePantry = pantryRaw.includes("tempe");
  const hasAyamPantry = pantryRaw.includes("ayam");
  const hasTelurPantry = pantryRaw.includes("telur");
  const hasIkanPantry =
    pantryRaw.includes("ikan") ||
    pantryRaw.includes("lele") ||
    pantryRaw.includes("nila") ||
    pantryRaw.includes("tongkol") ||
    pantryRaw.includes("kembung");
  const hasUdangPantry = pantryRaw.includes("udang");

  const hasBayamPantry = pantryRaw.includes("bayam");
  const hasKangkungPantry = pantryRaw.includes("kangkung");
  const hasBuncisPantry = pantryRaw.includes("buncis");
  const hasOyongLabuPantry =
    pantryRaw.includes("oyong") || pantryRaw.includes("labu") || pantryRaw.includes("gambas");

  // Filter pantry proteins against allergies
  const safePantryProteins: string[] = [];
  let allergyRejectionNote = "";
  if (hasTahuPantry) safePantryProteins.push("tahu");
  if (hasTempePantry) safePantryProteins.push("tempe");
  if (hasAyamPantry) safePantryProteins.push("ayam");
  if (hasTelurPantry) {
    if (hasEggAllergy) {
      allergyRejectionNote = "Bahan telur dari kulkas dikesampingkan demi keamanan alergi telur.";
    } else {
      safePantryProteins.push("telur");
    }
  }
  if (hasIkanPantry) {
    if (hasSeafoodAllergy) {
      allergyRejectionNote = "Bahan ikan dari kulkas dikesampingkan demi keamanan alergi seafood.";
    } else {
      safePantryProteins.push("ikan");
    }
  }
  if (hasUdangPantry) {
    if (hasUdangAllergy || hasSeafoodAllergy) {
      allergyRejectionNote = "Bahan udang dari kulkas dikesampingkan demi keamanan alergi seafood/udang.";
    } else {
      safePantryProteins.push("udang");
    }
  }

  // 4. Select Target Protein for Lauk Utama
  let chosenProtein = "";
  let isFromPantry = false;

  if (safePantryProteins.length > 0) {
    isFromPantry = true;
    if (hasNephropathy) {
      // Prioritize plant protein (tahu/tempe), or if only poultry available, strictly measured portion
      if (safePantryProteins.includes("tahu")) chosenProtein = "tahu";
      else if (safePantryProteins.includes("tempe")) chosenProtein = "tempe";
      else chosenProtein = safePantryProteins[0];
    } else {
      if (safePantryProteins.includes("ayam")) chosenProtein = "ayam";
      else if (safePantryProteins.includes("ikan")) chosenProtein = "ikan";
      else if (safePantryProteins.includes("tahu")) chosenProtein = "tahu";
      else if (safePantryProteins.includes("tempe")) chosenProtein = "tempe";
      else chosenProtein = safePantryProteins[0];
    }
  } else {
    // Default protein based on category, clinical and allergies
    isFromPantry = false;
    if (hasNephropathy) {
      chosenProtein = "tahu";
    } else if (cat === "BREAKFAST") {
      chosenProtein = hasEggAllergy ? "tempe" : "telur";
    } else if (cat === "DINNER") {
      chosenProtein = "tempe";
    } else {
      chosenProtein = hasSeafoodAllergy ? "ayam" : "ikan";
    }
  }

  // 5. Build Lauk Utama Name, Description, and Portion
  let mainDishName = "";
  let proteinGrams = 18;
  let sodiumMg = 140;
  let proteinCost = 6000;
  let proteinIngredientName = "";
  let proteinPortionStr = "";

  if (hasNephropathy) {
    // GLOMERULAR FILTRATION PROTEIN CEILING: 10g
    proteinGrams = 10;
    sodiumMg = hasLowSalt ? 75 : 105;

    if (chosenProtein === "tahu") {
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Tahu Sutra Dapur Bumbu Rempah Daun Jeruk & Serai (Protein Terukur 10g, Sodium <75mg)"
            : "Pepes Tahu Sutra Bumbu Rempah Daun Jeruk (Protein Terukur 10g, Bebas Garam Tambahan)")
        : (isFromPantry
            ? "Tahu Sutra Kukus Dapur Daun Pisang (Protein Terukur 10g & Rendah Fosfat)"
            : "Pepes Tahu Sutra Kukus Daun Pisang (Protein Terukur 10g & Rendah Fosfat)");
      proteinIngredientName = isFromPantry ? "Tahu Sutra Putih (Dapur Pasien)" : "Tahu Sutra Putih Lembut";
      proteinPortionStr = "1 kotak kecil (70g)";
      proteinCost = isFromPantry ? 1000 : 2200;
    } else if (chosenProtein === "tempe") {
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Tempe Kedelai Dapur Kukus Bumbu Serai & Kunyit (Porsi Terukur 50g / Protein 10g, Bebas Garam)"
            : "Tempe Kukus Bumbu Rempah Daun Jeruk Serai (Porsi Terukur 50g / Protein 10g, Bebas Garam)")
        : (isFromPantry
            ? "Tempe Kedelai Dapur Kukus Bumbu Kunyit Lengkuas (Porsi Terukur 50g / Protein 10g)"
            : "Tempe Kedelai Kukus Daun Salam Lengkuas (Porsi Terukur 50g / Protein 10g)");
      proteinIngredientName = isFromPantry ? "Tempe Kedelai (Dapur Pasien)" : "Tempe Kedelai Segar";
      proteinPortionStr = "1 potong sedang (50g)";
      proteinCost = isFromPantry ? 1000 : 1800;
    } else if (chosenProtein === "ayam") {
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Dada Ayam Dapur Suwir Porsi Ringan 40g Bumbu Daun Jeruk Serai (Protein Terukur 10g, Bebas Garam)"
            : "Dada Ayam Suwir Porsi Ringan 40g Bumbu Daun Jeruk Serai (Protein Terukur 10g, Bebas Garam)")
        : (isFromPantry
            ? "Dada Ayam Suwir Dapur Porsi Ringan (40g / Protein Terukur 10g Ramah Ginjal) Bumbu Kemangi"
            : "Dada Ayam Suwir Kukus Porsi Ringan (40g / Protein Terukur 10g Ramah Ginjal)");
      proteinIngredientName = isFromPantry ? "Dada Ayam Tanpa Kulit (Dapur Pasien)" : "Dada Ayam Tanpa Kulit Fillet";
      proteinPortionStr = "40 gram (Porsi Terukur Ginjal)";
      proteinCost = isFromPantry ? 2500 : 4500;
    } else {
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Fillet Ikan Dapur Kukus Bumbu Rempah Daun Jeruk (Porsi Ringan 45g / Protein 10g, Bebas Garam)"
            : "Fillet Ikan Segar Kukus Rempah Serai (Porsi Ringan 45g / Protein 10g, Bebas Garam)")
        : (isFromPantry
            ? "Fillet Ikan Dapur Kukus Kuah Kunyit Porsi Ringan (45g / Protein 10g)"
            : "Fillet Ikan Kembung Kukus Kunyit Porsi Ringan (45g / Protein 10g)");
      proteinIngredientName = isFromPantry ? "Ikan Segar (Dapur Pasien)" : "Ikan Kembung Segar Fillet";
      proteinPortionStr = "45 gram (Porsi Terukur Ginjal)";
      proteinCost = isFromPantry ? 3000 : 5000;
    }
  } else {
    // STANDARD DIABETIC PROTEIN PORTION (13 - 24g)
    if (chosenProtein === "ayam") {
      proteinGrams = 24;
      sodiumMg = hasLowSalt ? 80 : 150;
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Dada Ayam Fillet Dapur Ungkep Rempah Daun Jeruk & Serai (Bebas Garam Tambahan / Sodium <85mg)"
            : "Dada Ayam Ungkep Rempah Daun Jeruk & Serai (Bebas Garam Tambahan / Sodium <85mg)")
        : (isFromPantry
            ? "Dada Ayam Suwir Kukus Dapur Bumbu Kemangi & Ketumbar (80g)"
            : "Dada Ayam Ungkep Bumbu Kuning Lengkuas (1 Potong 75g)");
      proteinIngredientName = isFromPantry ? "Dada Ayam Tanpa Kulit (Dapur Pasien)" : "Dada Ayam Fillet Segar";
      proteinPortionStr = "80 gram";
      proteinCost = isFromPantry ? 2500 : 6500;
    } else if (chosenProtein === "ikan") {
      proteinGrams = 22;
      sodiumMg = hasLowSalt ? 80 : 160;
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Ikan Segar Dapur Kukus Rempah Kunyit & Daun Jeruk (Bebas Garam Tambahan / Sodium <85mg)"
            : "Ikan Kembung Segar Kukus Rempah Daun Jeruk (Bebas Garam Tambahan / Sodium <85mg)")
        : (isFromPantry
            ? "Ikan Segar Dapur Kukus Bumbu Kunyit & Serai Segar (1 Ekor 80g)"
            : "Ikan Kembung Kukus Bumbu Kunyit & Kemangi (1 Ekor 80g)");
      proteinIngredientName = isFromPantry ? "Ikan Segar (Dapur Pasien)" : "Ikan Kembung Segar";
      proteinPortionStr = "1 ekor (80g)";
      proteinCost = isFromPantry ? 2500 : 7000;
    } else if (chosenProtein === "telur") {
      proteinGrams = 13;
      sodiumMg = hasLowSalt ? 75 : 120;
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Telur Rebus Dapur Rempah Daun Salam & Serai (Bebas Garam Tambahan / 1 Butir)"
            : "Telur Ayam Rebus Rempah Daun Salam (Bebas Garam Tambahan / 1 Butir)")
        : (isFromPantry
            ? "Telur Rebus Dapur Bebas Minyak (1 Butir 60g)"
            : "Telur Ayam Ras Rebus Bebas Minyak (1 Butir)");
      proteinIngredientName = isFromPantry ? "Telur Ayam (Dapur Pasien)" : "Telur Ayam Ras Segar";
      proteinPortionStr = "1 butir (60g)";
      proteinCost = isFromPantry ? 800 : 2500;
    } else if (chosenProtein === "tempe") {
      proteinGrams = 16;
      sodiumMg = hasLowSalt ? 80 : 130;
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Tempe Kedelai Dapur Bakar Teflon Bumbu Serai & Bawang Putih (Bebas Garam Tambahan / Sodium <80mg)"
            : "Tempe Kedelai Bakar Teflon Rempah Daun Jeruk Serai (Bebas Garam Tambahan / Sodium <80mg)")
        : (isFromPantry
            ? "Tempe Kedelai Dapur Bakar Teflon Bumbu Ketumbar Gurih (2 Potong Tebal 80g)"
            : "Tempe Kedelai Bakar Teflon Bumbu Ketumbar Kemangi (2 Potong Tebal 80g)");
      proteinIngredientName = isFromPantry ? "Tempe Kedelai Murni (Dapur Pasien)" : "Tempe Kedelai Murni";
      proteinPortionStr = "2 potong tebal (80g)";
      proteinCost = isFromPantry ? 1000 : 2500;
    } else {
      proteinGrams = 14;
      sodiumMg = hasLowSalt ? 80 : 125;
      mainDishName = hasLowSalt
        ? (isFromPantry
            ? "Tahu Sutra Dapur Bakar Teflon Bumbu Rempah Daun Jeruk (Bebas Garam Tambahan / Sodium <80mg)"
            : "Tahu Sutra Bakar Teflon Bumbu Rempah Daun Jeruk (Bebas Garam Tambahan / Sodium <80mg)")
        : (isFromPantry
            ? "Tahu Sutra Kukus Dapur Bumbu Kunyit & Daun Kemangi (2 Potong 120g)"
            : "Tahu Sutra Kukus Bumbu Kunyit & Daun Kemangi (2 Potong 120g)");
      proteinIngredientName = isFromPantry ? "Tahu Sutra Putih (Dapur Pasien)" : "Tahu Sutra Putih Segar";
      proteinPortionStr = "2 potong kotak (120g)";
      proteinCost = isFromPantry ? 1000 : 2500;
    }
  }

  // 6. Sayuran & Lauk Pendamping (Complementary Foods)
  const complementaryFoods: string[] = [];
  const ingredients: Array<{ name: string; quantity: string; est_cost_idr: number }> = [];

  ingredients.push({
    name: proteinIngredientName,
    quantity: proteinPortionStr,
    est_cost_idr: proteinCost,
  });

  if (hasNephropathy) {
    complementaryFoods.push("Sup Bening Oyong Gambas & Labu Siam Rendah Kalium (1 Mangkuk)");
    complementaryFoods.push("Lalap Mentimun Iris Segar");
    ingredients.push({
      name: hasOyongLabuPantry ? "Oyong & Labu Siam (Dapur Pasien)" : "Oyong Muda & Labu Siam Segar",
      quantity: "1 mangkuk kecil",
      est_cost_idr: hasOyongLabuPantry ? 1000 : 2500,
    });
  } else if (hasBayamPantry) {
    complementaryFoods.push("Sayur Bening Bayam Segar Kaldu Bawang Dapur (1 Mangkuk)");
    complementaryFoods.push("Lalap Timun Iris Segar");
    ingredients.push({
      name: "Bayam Hijau Segar (Dapur Pasien)",
      quantity: "1 ikat",
      est_cost_idr: 1000,
    });
  } else if (hasKangkungPantry) {
    complementaryFoods.push("Tumis Kangkung Bawang Putih Segar Rendah Minyak (1 Piring)");
    complementaryFoods.push("Sambal Tomat Kukus Segar Bebas Gula");
    ingredients.push({
      name: "Kangkung Segar (Dapur Pasien)",
      quantity: "1 ikat",
      est_cost_idr: 1000,
    });
  } else if (hasBuncisPantry) {
    complementaryFoods.push(
      hasLowSalt
        ? "Tumis Buncis Muda & Wortel Rempah (Bebas Garam Tambahan)"
        : "Tumis Buncis Muda & Wortel Sedikit Minyak"
    );
    complementaryFoods.push("Lalap Daun Kemangi Segar");
    ingredients.push({
      name: "Buncis Muda & Wortel (Dapur Pasien)",
      quantity: "100 gram",
      est_cost_idr: 1200,
    });
  } else if (cat === "DINNER" && hasPeanutAllergy) {
    complementaryFoods.push("Capcay Kuah Bening Segar (Kembang Kol, Wortel, Jamur - Bebas Kacang)");
    complementaryFoods.push("Sambal Tomat Rebus Segar Tanpa Gula");
    ingredients.push({
      name: "Sayuran Capcay Segar (Wortel, Kembang Kol, Sawi)",
      quantity: "1 mangkuk besar",
      est_cost_idr: 3500,
    });
  } else if (cat === "DINNER") {
    complementaryFoods.push("Rebusan Sayur Kangkung & Tauge Segar (1 Piring)");
    complementaryFoods.push("Sambal Tomat Rebus Segar Rendah Gula (2 sdm)");
    ingredients.push({
      name: "Kangkung & Tauge Segar",
      quantity: "1 porsi",
      est_cost_idr: 2500,
    });
  } else if (cat === "BREAKFAST") {
    complementaryFoods.push("Sayur Bening Bayam Segar Kaldu Bawang (1 Mangkuk)");
    ingredients.push({
      name: "Bayam Hijau Segar",
      quantity: "1/2 ikat",
      est_cost_idr: 2000,
    });
  } else {
    complementaryFoods.push(
      hasLowSalt
        ? "Tumis Buncis Muda Bawang Putih Bakar (Bebas Garam Tambahan)"
        : "Tumis Buncis Muda & Wortel Sedikit Minyak"
    );
    complementaryFoods.push("Lalap Timun Kemangi Segar");
    ingredients.push({
      name: "Buncis Muda & Wortel Segar",
      quantity: "100 gram",
      est_cost_idr: 2500,
    });
  }

  // Carbohydrate Selection
  let carbName = "Nasi Beras Merah Pulen (100g)";
  let carbIngredientName = "Beras Merah Pulen";
  let carbCost = 2000;
  if (hasNephropathy) {
    carbName = "Nasi Jagung Rendah Purin Porsi Terukur (75g)";
    carbIngredientName = "Beras Jagung Rendah Purin";
    carbCost = 1600;
  } else if (dailyBudget <= 25000 || isFromPantry) {
    carbName = "Nasi Jagung Pulen Lokal Rendah Glikemik (100g)";
    carbIngredientName = "Beras Jagung Lokal";
    carbCost = 1500;
  }
  complementaryFoods.splice(1, 0, carbName);

  ingredients.push({
    name: carbIngredientName,
    quantity: hasNephropathy ? "65 gram" : "75 gram",
    est_cost_idr: carbCost,
  });

  ingredients.push({
    name: hasLowSalt
      ? "Bumbu Aromatik Daun Jeruk, Serai, Kunyit & Bawang Putih"
      : "Bumbu Rempah Segar & Daun Salam Kemangi",
    quantity: "Secukupnya",
    est_cost_idr: 1200,
  });

  const estimatedTotalCost = ingredients.reduce((sum, item) => sum + item.est_cost_idr, 0);

  // 7. Personalization Badges / Tags
  const personalizationTags: string[] = [];
  if (isFromPantry) {
    const proteinLabelCapital = chosenProtein.charAt(0).toUpperCase() + chosenProtein.slice(1);
    personalizationTags.push(`Bahan Dapur: ${proteinLabelCapital}`);
  }
  if (hasBayamPantry || hasKangkungPantry || hasBuncisPantry || hasOyongLabuPantry) {
    const vegLabel = hasBayamPantry
      ? "Bayam"
      : hasKangkungPantry
      ? "Kangkung"
      : hasBuncisPantry
      ? "Buncis"
      : "Oyong";
    personalizationTags.push(`Sayur Dapur: ${vegLabel}`);
  }
  if (hasNephropathy) {
    personalizationTags.push("Klinis: Nefropati (Protein 10g)");
  }
  if (hasLowSalt) {
    personalizationTags.push("Klinis: Rendah Garam (<90mg)");
  }
  if (hasSeafoodAllergy) {
    personalizationTags.push("Bebas Alergen: Seafood");
  }
  if (hasEggAllergy) {
    personalizationTags.push("Bebas Alergen: Telur");
  }
  if (hasPeanutAllergy) {
    personalizationTags.push("Bebas Alergen: Kacang");
  }
  if (allergyRejectionNote) {
    personalizationTags.push("Penyesuaian: Alergen Dapur Dieliminasi");
  }

  // 8. Generate Dish Title Name
  const carbShort = hasNephropathy || dailyBudget <= 25000 || isFromPantry ? "Nasi Jagung" : "Nasi Merah";
  const mainDishShort = mainDishName.split("(")[0].trim();
  const veggieShort = complementaryFoods[0].split("(")[0].trim();
  const dishTitle = `${carbShort}, ${mainDishShort} & ${veggieShort}`;

  // 9. Nutritional Explanation Text
  const proteinImpactDesc = hasNephropathy
    ? `Safeguard Nefropati: Porsi ${chosenProtein} dibatasi presisi 10g untuk mencegah hiperfiltrasi glomerulus ginjal.`
    : hasLowSalt
    ? `Safeguard Hipertensi: Pengolahan rempah aromatik daun jeruk & serai alami tanpa sodium tinggi menjaga tekanan mikrovaskular retina.`
    : `Protein murni ${chosenProtein} bebas alergi mendukung regenerasi sel dan stabilitas glukosa post-prandial.`;

  const summaryDesc = [
    isFromPantry ? `Mengoptimalkan bahan dapur (${chosenProtein}).` : "",
    hasNephropathy ? "Protein dibatasi ramah ginjal (10g)." : "",
    hasLowSalt ? "Sodium sangat rendah (<90mg) untuk proteksi tensi retina." : "",
    hasSeafoodAllergy ? "Bebas seafood/ikan." : "",
    hasEggAllergy ? "Bebas telur." : "",
    hasPeanutAllergy ? "Bebas bumbu kacang." : "",
  ]
    .filter(Boolean)
    .join(" ");

  const mealTime = cat === "BREAKFAST" ? "07.15" : cat === "DINNER" ? "19.00" : "12.30";
  const mealCategoryLabel =
    cat === "BREAKFAST" ? "SARAPAN" : cat === "DINNER" ? "MAKAN_MALAM" : "MAKAN_SIANG";

  return {
    id: `meal-${cat.toLowerCase()}-${isFromPantry ? "pantry-" : ""}${chosenProtein}-${hasNephropathy ? "nefro-" : ""}${hasLowSalt ? "lowsalt" : "std"}`,
    category: mealCategoryLabel,
    time_recommendation: mealTime,
    name: dishTitle,
    main_dish: mainDishName,
    complementary_foods: complementaryFoods,
    suggested_portion: `Piring Model T Personalisasi: 1/2 sayuran, 1/4 karbohidrat terukur, 1/4 ${mainDishShort}.`,
    ingredients,
    estimated_cost_idr: estimatedTotalCost,
    affordable_alternatives: [
      {
        title: "Kreasi Olah Kukus / Bakar Teflon",
        savings_idr: 500,
        description:
          "Gunakan wajan teflon tanpa minyak kelapa sawit untuk menghemat biaya minyak dan menjaga profil lipid pembuluh darah.",
        substitution_type: "COOKING_METHOD",
      },
    ],
    nutrition: {
      calories_kcal: hasNephropathy ? 275 : 335,
      carbs_grams: hasNephropathy ? 28 : 31,
      fiber_grams: 7.5,
      protein_grams: proteinGrams,
      glycemic_index: "RENDAH",
      sodium_mg: sodiumMg,
    },
    nutritional_impact_explanation: {
      carbohydrate_impact: `${carbShort} kaya serat dan amilosa, memperlambat pemecahan zat gula dan mencegah lonjakan GD2PP.`,
      fiber_impact:
        "Serat sayuran melancarkan pencernaan dan mengandung antioksidan pelindung sel fotoreseptor makula retina.",
      protein_vascular_impact: proteinImpactDesc,
      glucose_stability_summary: summaryDesc || "Menu seimbang ramah glukosa darah.",
    },
    personalization_tags: personalizationTags,
    is_eaten: false,
    eaten_at: null,
    post_meal_glucose_mg_dl: null,
  };
}
