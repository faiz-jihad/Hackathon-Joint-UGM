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

    const result = await screeningService.runQualityGate(params.id, actor);

    return HttpResponse.success({
      screeningId: result.screening.id,
      screeningStatus: result.screening.status,
      qualityGatePassed: result.passed,
      evaluations: result.details.map((d) => d.toJSON()),
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
