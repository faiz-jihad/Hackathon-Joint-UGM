import { NextRequest } from "next/server";
import { humanReviewService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["OPHTHALMOLOGIST", "ADMIN"]);

    const pending = await humanReviewService.getPendingReviews(actor);
    return HttpResponse.success(pending.map((s) => s.toJSON()));
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
