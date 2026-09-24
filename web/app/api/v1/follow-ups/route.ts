import { NextRequest } from "next/server";
import { followUpService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { scheduleFollowUpSchema } from "@/lib/validations/follow-up.validation";

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = scheduleFollowUpSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const followUp = await followUpService.scheduleFollowUp(validated.data, actor);
    return HttpResponse.created(followUp.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    const searchParams = req.nextUrl.searchParams;
    const patientId = searchParams.get("patientId") || undefined;
    const status = (searchParams.get("status") as any) || undefined;
    const limit = parseInt(searchParams.get("limit") || "20", 10);
    const offset = parseInt(searchParams.get("offset") || "0", 10);

    const result = await followUpService.searchFollowUps(
      { patientId, status, limit, offset },
      actor
    );

    return HttpResponse.success(
      result.followUps.map((f) => f.toJSON()),
      200,
      { total: result.total, limit, offset }
    );
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
