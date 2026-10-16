import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { HttpResponse, CORS_HEADERS } from "@/lib/http-response";

export async function OPTIONS() {
  return HttpResponse.corsOptions();
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const {
      patientId = "P-DEFAULT",
      mealId,
      mealName,
      category = "LUNCH",
      postMealGlucoseMgDl,
      notes,
    } = body;

    const eatenAt = new Date().toISOString();

    // 1. Evaluate post-meal glucose if provided (GD2PP target: < 180 mg/dL)
    let glucoseEvaluation = null;
    if (postMealGlucoseMgDl !== undefined && postMealGlucoseMgDl !== null) {
      const bg = Number(postMealGlucoseMgDl);
      if (bg < 70) {
        glucoseEvaluation = {
          status: "HYPOGLYCEMIA",
          badgeColor: "RED",
          message: `⚠️ Kadar gula darah 2 jam pasca makan ${bg} mg/dL tergolong rendah (hipoglikemia). Segera konsumsi 15g karbohidrat manis dan istirahat.`,
        };
      } else if (bg > 250) {
        glucoseEvaluation = {
          status: "HIGH_HYPERGLYCEMIA",
          badgeColor: "RED",
          message: `⚠️ Kadar gula darah 2 jam pasca makan ${bg} mg/dL tinggi. Perbanyak minum air putih dan catat di riwayat kontrol Anda.`,
        };
      } else if (bg >= 180) {
        glucoseEvaluation = {
          status: "ABOVE_TARGET",
          badgeColor: "YELLOW",
          message: `Kadar gula darah 2 jam pasca makan ${bg} mg/dL sedikit di atas target (< 180 mg/dL). Pertahankan asupan serat dan kurangi porsi karbohidrat pada menu berikutnya.`,
        };
      } else {
        glucoseEvaluation = {
          status: "OPTIMAL",
          badgeColor: "GREEN",
          message: `Target Tercapai! Kadar gula darah 2 jam pasca makan ${bg} mg/dL berada dalam rentang kendali yang sangat baik (< 180 mg/dL).`,
        };
      }
    }

    // 2. Persist to CareProgressLog in DB
    try {
      await (prisma as any).careProgressLog?.create({
        data: {
          patientId,
          logDate: new Date(),
          mealsCompleted: {
            mealId,
            mealName,
            category,
            eatenAt,
            postMealGlucoseMgDl: postMealGlucoseMgDl ? Number(postMealGlucoseMgDl) : null,
          },
          patientNotes: notes || `Selesai mengonsumsi menu ${mealName || category}.`,
        },
      });
    } catch {
      // Non-fatal if DB is in mock mode
    }

    return NextResponse.json({
      success: true,
      data: {
        mealId,
        isEaten: true,
        eatenAt,
        postMealGlucoseMgDl: postMealGlucoseMgDl ? Number(postMealGlucoseMgDl) : null,
        glucoseEvaluation,
        mascotFeedback:
          postMealGlucoseMgDl && Number(postMealGlucoseMgDl) <= 180
            ? "Pilihan menu yang tepat! Gula darah Anda stabil setelah makan 💙"
            : "Terima kasih sudah mencatat menu makan sehat hari ini 🥗",
      },
    }, { headers: CORS_HEADERS });
  } catch (error: any) {
    console.error("[smart-meal eaten POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to mark meal as eaten." },
      { status: 500, headers: CORS_HEADERS }
    );
  }
}
