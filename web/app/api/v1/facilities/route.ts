import { NextRequest } from "next/server";
import { facilityService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { searchFacilitySchema } from "@/lib/validations/facility.validation";

export async function GET(req: NextRequest) {
  try {
    AuthGuard.authenticate(req);

    const searchParams = req.nextUrl.searchParams;
    const query = searchParams.get("query") || undefined;
    const bpjsStatus = (searchParams.get("bpjsStatus") as any) || undefined;
    const hasService = searchParams.get("hasService") || undefined;
    const isVerified = searchParams.get("isVerified") || undefined;
    const limit = searchParams.get("limit") || "20";
    const offset = searchParams.get("offset") || "0";

    const validated = searchFacilitySchema.safeParse({
      query,
      bpjsStatus,
      hasService,
      isVerified,
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

    const result = await facilityService.searchFacilities(validated.data);

    return HttpResponse.success(
      result.facilities.map((f) => f.toJSON()),
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
