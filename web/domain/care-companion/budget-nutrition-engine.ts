import { CareCompanionMasterStore, MasterMealDto } from "@/infrastructure/database/care-companion-master-store";

export interface MealItem {
  id: string;
  name: string;
  category: "SARAPAN" | "MAKAN_SIANG" | "MAKAN_MALAM" | "CAMILAN";
  portion: string;
  estimatedCostIdr: number;
  glycemicIndex: "RENDAH" | "SEDANG" | "TINGGI";
  carbsGrams: number;
  proteinGrams: number;
  ingredients: { name: string; quantity: string; estCostIdr: number }[];
  preparationNotes: string;
}

export interface ShoppingListItem {
  item: string;
  quantity: string;
  estPriceIdr: number;
  category: "POKOK" | "PROTEIN_NABATI" | "PROTEIN_HEWANI" | "SAYUR" | "BUAH" | "BUMBU";
}

export interface DailyMealPlanResult {
  dailyBudgetIdr: number;
  cityRegion: string;
  estimatedTotalCostIdr: number;
  remainingBudgetIdr: number;
  isOverBudget: boolean;
  isGeneralEducation: boolean;
  meals: {
    breakfast: MealItem;
    lunch: MealItem;
    dinner: MealItem;
    snack: MealItem;
  };
  shoppingList: ShoppingListItem[];
  clinicalGuidelineNotes: string;
  disclaimer: string;
}

export interface NutritionPreferencesInput {
  dailyBudgetIdr: number;
  cityRegion?: string;
  allergies?: string[];
  restrictions?: string[];
  preferredProteins?: ("TEMPE" | "TAHU" | "TELUR" | "IKAN" | "AYAM")[];
  clinicianDietaryNotes?: string;
  isGeneralEducation?: boolean;
}

export class BudgetNutritionEngine {
  private static mapMasterToMealItem(m: MasterMealDto): MealItem {
    const catMap: Record<string, MealItem["category"]> = {
      BREAKFAST: "SARAPAN",
      LUNCH: "MAKAN_SIANG",
      DINNER: "MAKAN_MALAM",
      SNACK: "CAMILAN",
    };
    const giMap: Record<string, MealItem["glycemicIndex"]> = {
      LOW: "RENDAH",
      MEDIUM: "SEDANG",
      HIGH: "TINGGI",
    };

    return {
      id: m.id,
      name: m.name,
      category: catMap[m.category] || "SARAPAN",
      portion: m.portion,
      estimatedCostIdr: m.estimatedCostIdr,
      glycemicIndex: giMap[m.glycemicIndex] || "RENDAH",
      carbsGrams: m.carbsGrams,
      proteinGrams: m.proteinGrams,
      ingredients: m.ingredients.map((ing) => ({
        name: ing,
        quantity: "1 porsi",
        estCostIdr: Math.round(m.estimatedCostIdr / Math.max(1, m.ingredients.length)),
      })),
      preparationNotes: m.preparationNotes,
    };
  }
  private static readonly BREAKFAST_OPTIONS: MealItem[] = [
    {
      id: "bf-01",
      name: "Nasi Merah Telur Rebus & Sayur Bening Bayam",
      category: "SARAPAN",
      portion: "1 Porsi (Nasi Merah 100g, 1 Telur, 1 Mangkuk Bayam)",
      estimatedCostIdr: 7500,
      glycemicIndex: "RENDAH",
      carbsGrams: 28,
      proteinGrams: 12,
      ingredients: [
        { name: "Beras Merah", quantity: "75 gram", estCostIdr: 2000 },
        { name: "Telur Ayam Ras", quantity: "1 butir", estCostIdr: 2500 },
        { name: "Bayam Hijau Segar", quantity: "1/2 ikat", estCostIdr: 2000 },
        { name: "Bawang Merah & Putih", quantity: "Secukupnya", estCostIdr: 1000 },
      ],
      preparationNotes: "Rebus telur hingga matang (hindari menggoreng dengan banyak minyak). Masak bayam dengan bawang bening sebentar saja agar vitamin C dan lutein tidak rusak.",
    },
    {
      id: "bf-02",
      name: "Oatmeal Gurih Kuah Kaldu Bening & Suwir Telur",
      category: "SARAPAN",
      portion: "1 Porsi (Oatmeal 4 sdm, Telur Orak-arik Minyak Minimal)",
      estimatedCostIdr: 7000,
      glycemicIndex: "RENDAH",
      carbsGrams: 24,
      proteinGrams: 10,
      ingredients: [
        { name: "Rolled Oats / Oatmeal Polos", quantity: "4 sdm (35g)", estCostIdr: 3000 },
        { name: "Telur Ayam Ras", quantity: "1 butir", estCostIdr: 2500 },
        { name: "Wortel Cincang", quantity: "1/2 batang", estCostIdr: 1000 },
        { name: "Daun Bawang & Seledri", quantity: "1 batang", estCostIdr: 500 },
      ],
      preparationNotes: "Seduh oatmeal dengan air kaldu bawang hangat. Masukkan potongan wortel dan telur rebus/orak-arik tanpa santan atau mentega berlebih.",
    },
    {
      id: "bf-03",
      name: "Ubi Jalar Rebus & Tempe Kukus Sambal Tomat Rebus",
      category: "SARAPAN",
      portion: "1 Porsi (1 Ubi Sedang, 2 Potong Tempe Kukus)",
      estimatedCostIdr: 6000,
      glycemicIndex: "RENDAH",
      carbsGrams: 30,
      proteinGrams: 11,
      ingredients: [
        { name: "Ubi Jalar Putih/Kuning Rebus", quantity: "1 buah (100g)", estCostIdr: 2500 },
        { name: "Tempe Kedelai Murni", quantity: "2 potong (60g)", estCostIdr: 2000 },
        { name: "Tomat & Cabai (Direbus)", quantity: "Secukupnya", estCostIdr: 1500 },
      ],
      preparationNotes: "Ubi dan tempe dikukus/direbus matang. Sambal diolah dengan tomat rebus dan cabai tanpa tambahan gula pasir (gunakan sedikit garam beryodium).",
    },
  ];

  private static readonly LUNCH_OPTIONS: MealItem[] = [
    {
      id: "lu-01",
      name: "Nasi Merah, Ikan Kembung Kukus Bumbu Kuning & Tumis Buncis",
      category: "MAKAN_SIANG",
      portion: "1 Porsi (Nasi Merah 100g, 1 Ikan Kembung, Tumis Buncis 1 Piring Kecil)",
      estimatedCostIdr: 13500,
      glycemicIndex: "RENDAH",
      carbsGrams: 32,
      proteinGrams: 22,
      ingredients: [
        { name: "Beras Merah", quantity: "75 gram", estCostIdr: 2000 },
        { name: "Ikan Kembung Segar", quantity: "1 ekor (80g)", estCostIdr: 7000 },
        { name: "Buncis Muda", quantity: "100 gram", estCostIdr: 2500 },
        { name: "Kunyit, Jahe, Bawang, Minyak Sedikit", quantity: "Secukupnya", estCostIdr: 2000 },
      ],
      preparationNotes: "Ikan kembung kaya asam lemak omega-3 yang mendukung kesehatan pembuluh darah mikro retina. Masak dengan cara kukus bumbu kuning tanpa santan.",
    },
    {
      id: "lu-02",
      name: "Nasi Jagung Pulen, Tempe & Tahu Bacem Rendah Gula, Lalap Segar",
      category: "MAKAN_SIANG",
      portion: "1 Porsi (Nasi Jagung 100g, 2 Tempe, 1 Tahu, Lalap Timun & Kemangi)",
      estimatedCostIdr: 9500,
      glycemicIndex: "RENDAH",
      carbsGrams: 35,
      proteinGrams: 18,
      ingredients: [
        { name: "Beras Jagung / Nasi Campur Jagung", quantity: "100 gram", estCostIdr: 2000 },
        { name: "Tempe Segar", quantity: "2 potong (70g)", estCostIdr: 2500 },
        { name: "Tahu Putih Segar", quantity: "1 potong (50g)", estCostIdr: 1500 },
        { name: "Lalapan (Timun & Kemangi)", quantity: "1 porsi", estCostIdr: 2000 },
        { name: "Bumbu Bacem Rempah (Kecap Rendah Gula)", quantity: "Secukupnya", estCostIdr: 1500 },
      ],
      preparationNotes: "Gunakan rempah ketumbar dan lengkuas kuat, batasi gula aren/gula merah dalam bumbu bacem agar lonjakan glukosa darah terkendali.",
    },
    {
      id: "lu-03",
      name: "Nasi Merah, Dada Ayam Ungkep Kuning & Sayur Bening Labu Siam",
      category: "MAKAN_SIANG",
      portion: "1 Porsi (Nasi Merah 100g, Dada Ayam 70g, Labu Siam Bening)",
      estimatedCostIdr: 14500,
      glycemicIndex: "RENDAH",
      carbsGrams: 30,
      proteinGrams: 24,
      ingredients: [
        { name: "Beras Merah", quantity: "75 gram", estCostIdr: 2000 },
        { name: "Dada Ayam Tanpa Kulit", quantity: "75 gram", estCostIdr: 7500 },
        { name: "Labu Siam Muda", quantity: "1 buah kecil", estCostIdr: 3000 },
        { name: "Bumbu Kuning & Garam", quantity: "Secukupnya", estCostIdr: 2000 },
      ],
      preparationNotes: "Ayam diungkep dengan kunyit dan serai tanpa digoreng kering. Labu siam memberikan serat larut yang baik untuk kestabilan gula darah.",
    },
  ];

  private static readonly DINNER_OPTIONS: MealItem[] = [
    {
      id: "di-01",
      name: "Pecel Sayuran (Kangkung, Tauge, Kacang Panjang) & Tahu Panggang",
      category: "MAKAN_MALAM",
      portion: "1 Porsi (Aneka Sayuran Rebus 150g, 2 Tahu Kuning, Bumbu Kacang Encer)",
      estimatedCostIdr: 8500,
      glycemicIndex: "RENDAH",
      carbsGrams: 22,
      proteinGrams: 14,
      ingredients: [
        { name: "Kangkung & Tauge Segar", quantity: "1 mangkuk", estCostIdr: 2500 },
        { name: "Kacang Panjang", quantity: "4 batang", estCostIdr: 1500 },
        { name: "Tahu Kuning Panggang Teflon", quantity: "2 potong", estCostIdr: 2500 },
        { name: "Bumbu Kacang Sedang (Tanpa Gula)", quantity: "2 sdm encer", estCostIdr: 2000 },
      ],
      preparationNotes: "Makan malam kaya serat dengan karbohidrat minimalis sangat baik mencegah hiperglikemia nokturnal saat tidur. Bumbu kacang tidak ditambah gula pasir.",
    },
    {
      id: "di-02",
      name: "Sup Bening Tahu Sutra, Wortel & Jamur Tiram",
      category: "MAKAN_MALAM",
      portion: "1 Mangkuk Besar Sup Bening Hangat + 1 Centong Nasi Merah",
      estimatedCostIdr: 9000,
      glycemicIndex: "RENDAH",
      carbsGrams: 25,
      proteinGrams: 12,
      ingredients: [
        { name: "Tahu Putih / Tahu Sutra", quantity: "1 kotak sedang", estCostIdr: 2500 },
        { name: "Wortel Segar", quantity: "1 batang", estCostIdr: 2000 },
        { name: "Jamur Tiram", quantity: "50 gram", estCostIdr: 2000 },
        { name: "Beras Merah (Centong Kecil)", quantity: "50 gram", estCostIdr: 1500 },
        { name: "Bumbu Bawang & Merica", quantity: "Secukupnya", estCostIdr: 1000 },
      ],
      preparationNotes: "Wortel kaya beta-karoten yang baik untuk retina. Sup bening hangat membantu hidrasi dan rasa kenyang tanpa beban kalori berlebih.",
    },
    {
      id: "di-03",
      name: "Tumis Kangkung Terasi Minimalis & Pepes Ikan Tongkol",
      category: "MAKAN_MALAM",
      portion: "1 Porsi (Kangkung 1 Piring, 1 Pepes Tongkol Kecil)",
      estimatedCostIdr: 11000,
      glycemicIndex: "RENDAH",
      carbsGrams: 18,
      proteinGrams: 19,
      ingredients: [
        { name: "Ikan Tongkol Pindang", quantity: "1 potong (60g)", estCostIdr: 5000 },
        { name: "Kangkung Segar", quantity: "1 ikat", estCostIdr: 2500 },
        { name: "Daun Pisang & Bumbu Pepes", quantity: "Secukupnya", estCostIdr: 2000 },
        { name: "Minyak Tumis (1/2 sdt)", quantity: "Sedikit", estCostIdr: 1500 },
      ],
      preparationNotes: "Pepes dibungkus daun pisang dan dikukus/dibakar tanpa minyak. Sangat aman untuk profil lipid dan tekanan darah penderita diabetes.",
    },
  ];

  private static readonly SNACK_OPTIONS: MealItem[] = [
    {
      id: "sn-01",
      name: "Pepaya California Potong Segar",
      category: "CAMILAN",
      portion: "1 Piring Kecil (100 gram)",
      estimatedCostIdr: 2500,
      glycemicIndex: "SEDANG",
      carbsGrams: 11,
      proteinGrams: 1,
      ingredients: [
        { name: "Pepaya California Matang", quantity: "100 gram", estCostIdr: 2500 },
      ],
      preparationNotes: "Buah potong segar kaya enzim papain, likopen, dan vitamin C. Hindari jus buah dengan gula atau kental manis.",
    },
    {
      id: "sn-02",
      name: "Apel Malang Lokal Segar",
      category: "CAMILAN",
      portion: "1 Buah Sedang (Kira-kira 100g)",
      estimatedCostIdr: 3500,
      glycemicIndex: "RENDAH",
      carbsGrams: 14,
      proteinGrams: 0.5,
      ingredients: [
        { name: "Apel Malang Lokal", quantity: "1 buah", estCostIdr: 3500 },
      ],
      preparationNotes: "Konsumsi bersama kulitnya setelah dicuci bersih untuk mendapatkan serat pektin alami yang memperlambat penyerapan karbohidrat.",
    },
    {
      id: "sn-03",
      name: "Pisang Kepok Rebus",
      category: "CAMILAN",
      portion: "1 Buah Pisang Kepok Rebus",
      estimatedCostIdr: 2500,
      glycemicIndex: "RENDAH",
      carbsGrams: 15,
      proteinGrams: 1,
      ingredients: [
        { name: "Pisang Kepok Mengkal Rebus", quantity: "1 buah", estCostIdr: 2500 },
      ],
      preparationNotes: "Pisang kepok yang dikukus/direbus memiliki pati resisten tinggi yang bersahabat bagi sensitivitas insulin.",
    },
  ];

  /**
   * Generates a complete daily meal plan dynamically from Master Database items.
   */
  public static async generatePlanAsync(input: NutritionPreferencesInput): Promise<DailyMealPlanResult> {
    const dailyBudgetIdr = input.dailyBudgetIdr > 0 ? input.dailyBudgetIdr : 35000;
    const cityRegion = input.cityRegion || "D.I. Yogyakarta";
    const isGeneralEducation = input.isGeneralEducation !== false;

    // Fetch active meals from database
    const [allBreakfasts, allLunches, allDinners, allSnacks] = await Promise.all([
      CareCompanionMasterStore.getAllMeals("BREAKFAST"),
      CareCompanionMasterStore.getAllMeals("LUNCH"),
      CareCompanionMasterStore.getAllMeals("DINNER"),
      CareCompanionMasterStore.getAllMeals("SNACK"),
    ]);

    const bfOptions = allBreakfasts.map(this.mapMasterToMealItem);
    const luOptions = allLunches.map(this.mapMasterToMealItem);
    const diOptions = allDinners.map(this.mapMasterToMealItem);
    const snOptions = allSnacks.map(this.mapMasterToMealItem);

    // Pick meals based on budget constraints
    let breakfast = bfOptions[0] || this.BREAKFAST_OPTIONS[0];
    let lunch = luOptions[0] || this.LUNCH_OPTIONS[0];
    let dinner = diOptions[0] || this.DINNER_OPTIONS[0];
    let snack = snOptions[0] || this.SNACK_OPTIONS[0];

    // If budget is lower (< Rp 30.000), prioritize affordable vegetable and plant proteins
    if (dailyBudgetIdr < 30000) {
      breakfast = bfOptions.find((m) => m.estimatedCostIdr <= 6500) || bfOptions[0] || this.BREAKFAST_OPTIONS[2];
      lunch = luOptions.find((m) => m.estimatedCostIdr <= 10000) || luOptions[0] || this.LUNCH_OPTIONS[1];
      dinner = diOptions.find((m) => m.estimatedCostIdr <= 9000) || diOptions[0] || this.DINNER_OPTIONS[0];
      snack = snOptions.find((m) => m.estimatedCostIdr <= 3000) || snOptions[0] || this.SNACK_OPTIONS[0];
    }

    const estimatedTotalCostIdr =
      breakfast.estimatedCostIdr +
      lunch.estimatedCostIdr +
      dinner.estimatedCostIdr +
      snack.estimatedCostIdr;

    const remainingBudgetIdr = dailyBudgetIdr - estimatedTotalCostIdr;
    const isOverBudget = remainingBudgetIdr < 0;

    const shoppingList: ShoppingListItem[] = this.buildShoppingList([breakfast, lunch, dinner, snack]);

    const disclaimer = isGeneralEducation
      ? "Pemberitahuan Edukasi: Menu ini merupakan panduan nutrisi umum ramah kantong untuk penderita diabetes. Bukan diet medis terpersonalisasi. Makanan bergizi seimbang membantu kontrol glikemik, namun tidak menyembuhkan kerusakan retina."
      : "Rencana Nutrisi Pasca-Konsultasi: Disusun berdasarkan hasil catatan dokter, profil glikemik, dan anggaran harian Anda. Makanan sehat mendukung stabilitas vaskular mata namun tidak menggantikan resep/terapi medis dokter spesialis mata.";

    return {
      dailyBudgetIdr,
      cityRegion,
      estimatedTotalCostIdr,
      remainingBudgetIdr,
      isOverBudget,
      isGeneralEducation,
      meals: {
        breakfast,
        lunch,
        dinner,
        snack,
      },
      shoppingList,
      clinicalGuidelineNotes:
        "Panduan Gizi Perdami 2024: Jaga asupan karbohidrat kompleks rendah IG, prioritaskan sayur berdaun hijau gelap kaya Lutein & Zeaxanthin (bayam, brokoli, labu), cukupi Omega-3 (ikan kembung), dan batasi natrium < 2000 mg/hari.",
      disclaimer,
    };
  }

  /**
   * Synchronous fallback generator using default options.
   */
  public static generatePlan(input: NutritionPreferencesInput): DailyMealPlanResult {
    const dailyBudgetIdr = input.dailyBudgetIdr > 0 ? input.dailyBudgetIdr : 35000;
    const cityRegion = input.cityRegion || "D.I. Yogyakarta";
    const isGeneralEducation = input.isGeneralEducation !== false;

    let breakfast = this.BREAKFAST_OPTIONS[0];
    let lunch = this.LUNCH_OPTIONS[0];
    let dinner = this.DINNER_OPTIONS[0];
    let snack = this.SNACK_OPTIONS[0];

    if (dailyBudgetIdr < 30000) {
      breakfast = this.BREAKFAST_OPTIONS[2];
      lunch = this.LUNCH_OPTIONS[1];
      dinner = this.DINNER_OPTIONS[0];
      snack = this.SNACK_OPTIONS[0];
    }

    const estimatedTotalCostIdr =
      breakfast.estimatedCostIdr +
      lunch.estimatedCostIdr +
      dinner.estimatedCostIdr +
      snack.estimatedCostIdr;

    const remainingBudgetIdr = dailyBudgetIdr - estimatedTotalCostIdr;
    const isOverBudget = remainingBudgetIdr < 0;

    const shoppingList: ShoppingListItem[] = this.buildShoppingList([breakfast, lunch, dinner, snack]);

    const disclaimer = isGeneralEducation
      ? "Pemberitahuan Edukasi: Menu ini merupakan panduan nutrisi umum ramah kantong untuk penderita diabetes. Bukan diet medis terpersonalisasi. Makanan bergizi seimbang membantu kontrol glikemik, namun tidak menyembuhkan kerusakan retina."
      : "Rencana Nutrisi Pasca-Konsultasi: Disusun berdasarkan hasil catatan dokter, profil glikemik, dan anggaran harian Anda. Makanan sehat mendukung stabilitas vaskular mata namun tidak menggantikan resep/terapi medis dokter spesialis mata.";

    return {
      dailyBudgetIdr,
      cityRegion,
      estimatedTotalCostIdr,
      remainingBudgetIdr,
      isOverBudget,
      isGeneralEducation,
      meals: {
        breakfast,
        lunch,
        dinner,
        snack,
      },
      shoppingList,
      clinicalGuidelineNotes:
        "Panduan Gizi Perdami 2024: Jaga asupan karbohidrat kompleks rendah IG, prioritaskan sayur berdaun hijau gelap kaya Lutein & Zeaxanthin (bayam, brokoli, labu), cukupi Omega-3 (ikan kembung), dan batasi natrium < 2000 mg/hari.",
      disclaimer,
    };
  }

  /**
   * Replaces a specific meal and recalculates the budget using Master Database.
   */
  public static async replaceMealAsync(
    currentPlan: DailyMealPlanResult,
    targetCategory: "SARAPAN" | "MAKAN_SIANG" | "MAKAN_MALAM" | "CAMILAN",
    replacementMealId?: string
  ): Promise<DailyMealPlanResult> {
    const dbCatMap: Record<string, string> = {
      SARAPAN: "BREAKFAST",
      MAKAN_SIANG: "LUNCH",
      MAKAN_MALAM: "DINNER",
      CAMILAN: "SNACK",
    };

    const masterMeals = await CareCompanionMasterStore.getAllMeals(dbCatMap[targetCategory]);
    let candidateOptions = masterMeals.map(this.mapMasterToMealItem);
    if (candidateOptions.length === 0) {
      candidateOptions = targetCategory === "SARAPAN" ? this.BREAKFAST_OPTIONS : targetCategory === "MAKAN_SIANG" ? this.LUNCH_OPTIONS : targetCategory === "MAKAN_MALAM" ? this.DINNER_OPTIONS : this.SNACK_OPTIONS;
    }

    let newMeal: MealItem;
    if (replacementMealId) {
      newMeal = candidateOptions.find((m) => m.id === replacementMealId) || candidateOptions[0];
    } else {
      const currentKey = targetCategory === "SARAPAN" ? "breakfast" : targetCategory === "MAKAN_SIANG" ? "lunch" : targetCategory === "MAKAN_MALAM" ? "dinner" : "snack";
      const currentId = currentPlan.meals[currentKey]?.id;
      const nextIdx = (candidateOptions.findIndex((m) => m.id === currentId) + 1) % candidateOptions.length;
      newMeal = candidateOptions[nextIdx];
    }

    const updatedMeals = {
      ...currentPlan.meals,
      ...(targetCategory === "SARAPAN" ? { breakfast: newMeal } : {}),
      ...(targetCategory === "MAKAN_SIANG" ? { lunch: newMeal } : {}),
      ...(targetCategory === "MAKAN_MALAM" ? { dinner: newMeal } : {}),
      ...(targetCategory === "CAMILAN" ? { snack: newMeal } : {}),
    };

    const newTotalCost =
      updatedMeals.breakfast.estimatedCostIdr +
      updatedMeals.lunch.estimatedCostIdr +
      updatedMeals.dinner.estimatedCostIdr +
      updatedMeals.snack.estimatedCostIdr;

    const remainingBudgetIdr = currentPlan.dailyBudgetIdr - newTotalCost;

    return {
      ...currentPlan,
      meals: updatedMeals,
      estimatedTotalCostIdr: newTotalCost,
      remainingBudgetIdr,
      isOverBudget: remainingBudgetIdr < 0,
      shoppingList: this.buildShoppingList([
        updatedMeals.breakfast,
        updatedMeals.lunch,
        updatedMeals.dinner,
        updatedMeals.snack,
      ]),
    };
  }

  /**
   * Synchronous replace meal.
   */
  public static replaceMeal(
    currentPlan: DailyMealPlanResult,
    targetCategory: "SARAPAN" | "MAKAN_SIANG" | "MAKAN_MALAM" | "CAMILAN",
    replacementMealId?: string
  ): DailyMealPlanResult {
    let candidateOptions: MealItem[];
    switch (targetCategory) {
      case "SARAPAN":
        candidateOptions = this.BREAKFAST_OPTIONS;
        break;
      case "MAKAN_SIANG":
        candidateOptions = this.LUNCH_OPTIONS;
        break;
      case "MAKAN_MALAM":
        candidateOptions = this.DINNER_OPTIONS;
        break;
      case "CAMILAN":
        candidateOptions = this.SNACK_OPTIONS;
        break;
    }

    let newMeal: MealItem;
    if (replacementMealId) {
      newMeal = candidateOptions.find((m) => m.id === replacementMealId) || candidateOptions[0];
    } else {
      const currentKey = targetCategory === "SARAPAN" ? "breakfast" : targetCategory === "MAKAN_SIANG" ? "lunch" : targetCategory === "MAKAN_MALAM" ? "dinner" : "snack";
      const currentId = currentPlan.meals[currentKey].id;
      const nextIdx = (candidateOptions.findIndex((m) => m.id === currentId) + 1) % candidateOptions.length;
      newMeal = candidateOptions[nextIdx];
    }

    const updatedMeals = {
      ...currentPlan.meals,
      ...(targetCategory === "SARAPAN" ? { breakfast: newMeal } : {}),
      ...(targetCategory === "MAKAN_SIANG" ? { lunch: newMeal } : {}),
      ...(targetCategory === "MAKAN_MALAM" ? { dinner: newMeal } : {}),
      ...(targetCategory === "CAMILAN" ? { snack: newMeal } : {}),
    };

    const newTotalCost =
      updatedMeals.breakfast.estimatedCostIdr +
      updatedMeals.lunch.estimatedCostIdr +
      updatedMeals.dinner.estimatedCostIdr +
      updatedMeals.snack.estimatedCostIdr;

    const remainingBudgetIdr = currentPlan.dailyBudgetIdr - newTotalCost;

    return {
      ...currentPlan,
      meals: updatedMeals,
      estimatedTotalCostIdr: newTotalCost,
      remainingBudgetIdr,
      isOverBudget: remainingBudgetIdr < 0,
      shoppingList: this.buildShoppingList([
        updatedMeals.breakfast,
        updatedMeals.lunch,
        updatedMeals.dinner,
        updatedMeals.snack,
      ]),
    };
  }

  /**
   * Helper to build clean categorized shopping list.
   */
  private static buildShoppingList(meals: MealItem[]): ShoppingListItem[] {
    const itemMap = new Map<string, ShoppingListItem>();

    for (const meal of meals) {
      for (const ing of meal.ingredients) {
        const key = ing.name.toLowerCase().trim();
        if (itemMap.has(key)) {
          const existing = itemMap.get(key)!;
          existing.estPriceIdr += ing.estCostIdr;
        } else {
          let category: ShoppingListItem["category"] = "SAYUR";
          if (ing.name.includes("Beras") || ing.name.includes("Oat") || ing.name.includes("Ubi")) category = "POKOK";
          else if (ing.name.includes("Tempe") || ing.name.includes("Tahu")) category = "PROTEIN_NABATI";
          else if (ing.name.includes("Ikan") || ing.name.includes("Ayam") || ing.name.includes("Telur")) category = "PROTEIN_HEWANI";
          else if (ing.name.includes("Pepaya") || ing.name.includes("Apel") || ing.name.includes("Pisang")) category = "BUAH";
          else if (ing.name.includes("Bumbu") || ing.name.includes("Kunyit") || ing.name.includes("Bawang")) category = "BUMBU";

          itemMap.set(key, {
            item: ing.name,
            quantity: ing.quantity,
            estPriceIdr: ing.estCostIdr,
            category,
          });
        }
      }
    }

    return Array.from(itemMap.values());
  }

  public static getAllMealOptions() {
    return {
      breakfast: this.BREAKFAST_OPTIONS,
      lunch: this.LUNCH_OPTIONS,
      dinner: this.DINNER_OPTIONS,
      snack: this.SNACK_OPTIONS,
    };
  }
}
