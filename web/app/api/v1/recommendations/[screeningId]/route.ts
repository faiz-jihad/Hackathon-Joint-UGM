import { NextRequest } from "next/server";
import { recommendationService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { screeningId: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const recommendation = await recommendationService.getRecommendationByScreeningId(
      params.screeningId,
      actor
    );

    if (!recommendation) {
      return HttpResponse.error("Recommendation not found for this screening.", "NOT_FOUND", 404);
    }

    return HttpResponse.success(recommendation.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
