import { NextRequest } from "next/server";
import { referralService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { updateReferralStatusSchema } from "@/lib/validations/referral.validation";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const result = await referralService.getReferralById(params.id, actor);

    return HttpResponse.success({
      referral: result.referral.toJSON(),
      facility: result.facility,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = updateReferralStatusSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const updated = await referralService.updateReferralStatus(params.id, validated.data.status, actor);
    return HttpResponse.success(updated.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
