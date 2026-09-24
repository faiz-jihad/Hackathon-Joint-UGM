import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const result = await screeningService.getAiResult(params.id, actor);

    if (!result.aiResult) {
      return HttpResponse.error("AI inference has not been performed on this screening.", "NOT_FOUND", 404);
    }

    return HttpResponse.success({
      aiResult: result.aiResult.toJSON(),
      reliability: result.reliability ? result.reliability.toJSON() : null,
      modelVersion: result.modelVersion ? result.modelVersion.toJSON() : null,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
