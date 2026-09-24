import { NextRequest } from "next/server";
import { auditRepository } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { searchAuditLogSchema } from "@/lib/validations/model.validation";

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["ADMIN"]);

    const searchParams = req.nextUrl.searchParams;
    const actorId = searchParams.get("actorId") || undefined;
    const action = searchParams.get("action") || undefined;
    const resource = searchParams.get("resource") || undefined;
    const resourceId = searchParams.get("resourceId") || undefined;
    const limit = searchParams.get("limit") || "50";
    const offset = searchParams.get("offset") || "0";

    const validated = searchAuditLogSchema.safeParse({
      actorId,
      action,
      resource,
      resourceId,
      limit,
      offset,
    });

    if (!validated.success) {
      return HttpResponse.error(
        "Invalid query parameters",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await auditRepository.search(validated.data);

    return HttpResponse.success(
      result.logs.map((l) => l.toJSON()),
      200,
      {
        total: result.total,
        limit: validated.data.limit,
        offset: validated.data.offset,
      }
    );
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
