import { prisma } from "./prisma/client";

export interface MasterMealDto {
  id: string;
  name: string;
  category: "BREAKFAST" | "LUNCH" | "DINNER" | "SNACK";
  portion: string;
  estimatedCostIdr: number;
  glycemicIndex: "LOW" | "MEDIUM" | "HIGH";
  carbsGrams: number;
  proteinGrams: number;
  ingredients: string[];
  preparationNotes: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface MasterQuestionDto {
  id: string;
  questionText: string;
  category: string;
  orderIndex: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

import { COMPREHENSIVE_MASTER_MEALS } from "./master-meals-data";

// Initial seed data aligned with Indonesian PERDAMI / ADA clinical low-GI guidelines (31 dishes)
const INITIAL_MEALS: MasterMealDto[] = COMPREHENSIVE_MASTER_MEALS as MasterMealDto[];

const INITIAL_QUESTIONS: MasterQuestionDto[] = [
  {
    id: "q-01",
    questionText: "Berapa derajat keparahan retinopati diabetik pada mata kanan dan kiri saya saat ini?",
    category: "Pemeriksaan Retina",
    orderIndex: 1,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: "q-02",
    questionText: "Apakah ada tanda pembengkakan makula (edema makula diabetik) yang mempengaruhi tajam penglihatan saya?",
    category: "Pemeriksaan Retina",
    orderIndex: 2,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: "q-03",
    questionText: "Apakah saya memerlukan tindakan laser fotokoagulasi, suntikan anti-VEGF, atau cukup observasi berkala?",
    category: "Tindakan Medis & Terapi",
    orderIndex: 3,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: "q-04",
    questionText: "Berapa target kadar HbA1c dan tekanan darah harian yang aman untuk mencegah kerusakan retina lebih lanjut?",
    category: "Gaya Hidup & Diet",
    orderIndex: 4,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: "q-05",
    questionText: "Kapan tanggal pasti saya harus kembali kontrol ke dokter spesialis mata?",
    category: "Jadwal Kontrol",
    orderIndex: 5,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: "q-06",
    questionText: "Apakah ada pantangan aktivitas fisik atau jenis obat tetes mata yang perlu saya gunakan?",
    category: "Obat & Terapi",
    orderIndex: 6,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

// Global runtime memory store for instantaneous updates and resilient offline fallback
const globalStore = globalThis as unknown as {
  _careMealsStore?: MasterMealDto[];
  _careQuestionsStore?: MasterQuestionDto[];
};

if (!globalStore._careMealsStore) {
  globalStore._careMealsStore = [...INITIAL_MEALS];
}
if (!globalStore._careQuestionsStore) {
  globalStore._careQuestionsStore = [...INITIAL_QUESTIONS];
}

export class CareCompanionMasterStore {
  // ==========================================
  // MEALS CRUD
  // ==========================================
  static async getAllMeals(category?: string, search?: string): Promise<MasterMealDto[]> {
    try {
      // Try querying Prisma database first
      const dbMeals = await prisma.masterMealItem.findMany({
        where: {
          isActive: true,
          ...(category ? { category: category as any } : {}),
          ...(search ? { name: { contains: search, mode: "insensitive" } } : {}),
        },
        orderBy: { createdAt: "asc" },
      });

      if (dbMeals && dbMeals.length > 0) {
        return dbMeals.map((m: any) => ({
          id: m.id,
          name: m.name,
          category: m.category as any,
          portion: m.portion,
          estimatedCostIdr: m.estimatedCostIdr,
          glycemicIndex: m.glycemicIndex as any,
          carbsGrams: m.carbsGrams,
          proteinGrams: m.proteinGrams,
          ingredients: m.ingredients,
          preparationNotes: m.preparationNotes || "",
          isActive: m.isActive,
          createdAt: m.createdAt.toISOString(),
          updatedAt: m.updatedAt.toISOString(),
        }));
      }
    } catch {
      // Fallback gracefully to dynamic runtime memory store if DB is offline
    }

    let results = [...(globalStore._careMealsStore || INITIAL_MEALS)].filter((m) => m.isActive);
    if (category) {
      results = results.filter((m) => m.category === category);
    }
    if (search) {
      const q = search.toLowerCase();
      results = results.filter((m) => m.name.toLowerCase().includes(q));
    }
    return results;
  }

  static async getMealById(id: string): Promise<MasterMealDto | null> {
    try {
      const dbMeal = await prisma.masterMealItem.findUnique({ where: { id } });
      if (dbMeal) {
        return {
          id: dbMeal.id,
          name: dbMeal.name,
          category: dbMeal.category as any,
          portion: dbMeal.portion,
          estimatedCostIdr: dbMeal.estimatedCostIdr,
          glycemicIndex: dbMeal.glycemicIndex as any,
          carbsGrams: dbMeal.carbsGrams,
          proteinGrams: dbMeal.proteinGrams,
          ingredients: dbMeal.ingredients,
          preparationNotes: dbMeal.preparationNotes || "",
          isActive: dbMeal.isActive,
          createdAt: dbMeal.createdAt.toISOString(),
          updatedAt: dbMeal.updatedAt.toISOString(),
        };
      }
    } catch {
      // Fallback to memory store
    }
    return (globalStore._careMealsStore || []).find((m) => m.id === id) || null;
  }

  static async createMeal(data: Omit<MasterMealDto, "id" | "createdAt" | "updatedAt">): Promise<MasterMealDto> {
    const newMeal: MasterMealDto = {
      id: `meal-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    try {
      const created = await prisma.masterMealItem.create({
        data: {
          name: data.name,
          category: data.category as any,
          portion: data.portion || "1 porsi",
          estimatedCostIdr: data.estimatedCostIdr,
          glycemicIndex: data.glycemicIndex as any,
          carbsGrams: data.carbsGrams,
          proteinGrams: data.proteinGrams,
          ingredients: data.ingredients,
          preparationNotes: data.preparationNotes,
          isActive: data.isActive ?? true,
        },
      });
      newMeal.id = created.id;
    } catch {
      // DB offline, stored in runtime store
    }

    globalStore._careMealsStore = [newMeal, ...(globalStore._careMealsStore || [])];
    return newMeal;
  }

  static async updateMeal(id: string, data: Partial<MasterMealDto>): Promise<MasterMealDto | null> {
    try {
      await prisma.masterMealItem.update({
        where: { id },
        data: {
          ...(data.name ? { name: data.name } : {}),
          ...(data.category ? { category: data.category as any } : {}),
          ...(data.portion ? { portion: data.portion } : {}),
          ...(data.estimatedCostIdr !== undefined ? { estimatedCostIdr: data.estimatedCostIdr } : {}),
          ...(data.glycemicIndex ? { glycemicIndex: data.glycemicIndex as any } : {}),
          ...(data.carbsGrams !== undefined ? { carbsGrams: data.carbsGrams } : {}),
          ...(data.proteinGrams !== undefined ? { proteinGrams: data.proteinGrams } : {}),
          ...(data.ingredients ? { ingredients: data.ingredients } : {}),
          ...(data.preparationNotes !== undefined ? { preparationNotes: data.preparationNotes } : {}),
          ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
        },
      });
    } catch {
      // DB offline, updated in runtime store
    }

    const idx = (globalStore._careMealsStore || []).findIndex((m) => m.id === id);
    if (idx !== -1) {
      const updated: MasterMealDto = {
        ...globalStore._careMealsStore![idx],
        ...data,
        updatedAt: new Date().toISOString(),
      };
      globalStore._careMealsStore![idx] = updated;
      return updated;
    }
    return null;
  }

  static async deleteMeal(id: string): Promise<boolean> {
    try {
      await prisma.masterMealItem.delete({ where: { id } });
    } catch {
      // DB offline, remove or soft delete in runtime store
    }

    if (globalStore._careMealsStore) {
      globalStore._careMealsStore = globalStore._careMealsStore.filter((m) => m.id !== id);
      return true;
    }
    return false;
  }

  // ==========================================
  // QUESTIONS CRUD
  // ==========================================
  static async getAllQuestions(category?: string): Promise<MasterQuestionDto[]> {
    try {
      const dbQuestions = await prisma.masterDoctorQuestion.findMany({
        where: {
          isActive: true,
          ...(category ? { category } : {}),
        },
        orderBy: { orderIndex: "asc" },
      });

      if (dbQuestions && dbQuestions.length > 0) {
        return dbQuestions.map((q: any) => ({
          id: q.id,
          questionText: q.questionText,
          category: q.category,
          orderIndex: q.orderIndex,
          isActive: q.isActive,
          createdAt: q.createdAt.toISOString(),
          updatedAt: q.updatedAt.toISOString(),
        }));
      }
    } catch {
      // Fallback to runtime memory store
    }

    let results = [...(globalStore._careQuestionsStore || INITIAL_QUESTIONS)].filter((q) => q.isActive);
    if (category) {
      results = results.filter((q) => q.category === category);
    }
    return results.sort((a, b) => a.orderIndex - b.orderIndex);
  }

  static async createQuestion(data: Omit<MasterQuestionDto, "id" | "createdAt" | "updatedAt">): Promise<MasterQuestionDto> {
    const newQ: MasterQuestionDto = {
      id: `q-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    try {
      const created = await prisma.masterDoctorQuestion.create({
        data: {
          questionText: data.questionText,
          category: data.category || "Umum",
          orderIndex: data.orderIndex || 0,
          isActive: data.isActive ?? true,
        },
      });
      newQ.id = created.id;
    } catch {
      // DB offline, stored in runtime store
    }

    globalStore._careQuestionsStore = [...(globalStore._careQuestionsStore || []), newQ];
    return newQ;
  }

  static async updateQuestion(id: string, data: Partial<MasterQuestionDto>): Promise<MasterQuestionDto | null> {
    try {
      await prisma.masterDoctorQuestion.update({
        where: { id },
        data: {
          ...(data.questionText ? { questionText: data.questionText } : {}),
          ...(data.category ? { category: data.category } : {}),
          ...(data.orderIndex !== undefined ? { orderIndex: data.orderIndex } : {}),
          ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
        },
      });
    } catch {
      // DB offline
    }

    const idx = (globalStore._careQuestionsStore || []).findIndex((q) => q.id === id);
    if (idx !== -1) {
      const updated: MasterQuestionDto = {
        ...globalStore._careQuestionsStore![idx],
        ...data,
        updatedAt: new Date().toISOString(),
      };
      globalStore._careQuestionsStore![idx] = updated;
      return updated;
    }
    return null;
  }

  static async deleteQuestion(id: string): Promise<boolean> {
    try {
      await prisma.masterDoctorQuestion.delete({ where: { id } });
    } catch {
      // DB offline
    }

    if (globalStore._careQuestionsStore) {
      globalStore._careQuestionsStore = globalStore._careQuestionsStore.filter((q) => q.id !== id);
      return true;
    }
    return false;
  }
}
