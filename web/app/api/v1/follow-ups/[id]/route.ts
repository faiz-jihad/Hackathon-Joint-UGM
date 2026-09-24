import { NextRequest } from "next/server";
import { followUpService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { completeFollowUpSchema } from "@/lib/validations/follow-up.validation";

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = completeFollowUpSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const updated = await followUpService.completeFollowUp(params.id, validated.data.notes, actor);
    return HttpResponse.success(updated.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
