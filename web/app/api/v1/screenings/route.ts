import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { initiateScreeningSchema, searchScreeningSchema } from "@/lib/validations/screening.validation";

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = initiateScreeningSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const screening = await screeningService.initiateScreening(validated.data, actor);
    return HttpResponse.created(screening.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);

    const searchParams = req.nextUrl.searchParams;
    const patientId = searchParams.get("patientId") || undefined;
    const status = searchParams.get("status") || undefined;
    const limit = searchParams.get("limit") || "20";
    const offset = searchParams.get("offset") || "0";

    const validated = searchScreeningSchema.safeParse({ patientId, status, limit, offset });
    if (!validated.success) {
      return HttpResponse.error(
        "Invalid query parameters",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await screeningService.searchScreenings(validated.data, actor);

    return HttpResponse.success(
      result.screenings.map((s) => s.toJSON()),
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
