import { NextRequest } from "next/server";
import { referralService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { createReferralSchema } from "@/lib/validations/referral.validation";

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = createReferralSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const referral = await referralService.createReferral(validated.data, actor);
    return HttpResponse.created(referral.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
