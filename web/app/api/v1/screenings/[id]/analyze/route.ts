import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const result = await screeningService.analyzeScreening(params.id, actor);

    return HttpResponse.success({
      screeningId: result.screening.id,
      screeningStatus: result.screening.status,
      aiResult: result.aiResult.toJSON(),
      reliability: result.reliability.toJSON(),
      nextStep:
        result.reliability.status === "HUMAN_REVIEW"
          ? "HUMAN_REVIEW_REQUIRED"
          : "PROCEED_TO_RECOMMENDATION",
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
