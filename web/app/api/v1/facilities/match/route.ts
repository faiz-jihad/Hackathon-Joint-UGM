import { NextRequest } from "next/server";
import { facilityService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { matchFacilitySchema } from "@/lib/validations/facility.validation";

export async function POST(req: NextRequest) {
  try {
    AuthGuard.authenticate(req);

    const body = await req.json();
    const validated = matchFacilitySchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const matches = await facilityService.matchFacilities(validated.data);

    return HttpResponse.success(
      matches.map((m) => ({
        facility: m.facility.toJSON(),
        distanceKm: m.distanceKm,
        bpjsAvailable: m.bpjsAvailable,
        servicesAvailable: m.servicesAvailable,
      }))
    );
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
