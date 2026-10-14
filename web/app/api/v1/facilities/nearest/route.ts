import { NextRequest } from "next/server";
import { facilityService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(req: NextRequest) {
  try {
    try {
      AuthGuard.authenticate(req);
    } catch {
      // Allow unauthenticated mobile queries for emergency hospital routing
    }

    const searchParams = req.nextUrl.searchParams;
    const latStr = searchParams.get("lat") || searchParams.get("latitude") || "-7.7713";
    const lngStr = searchParams.get("lng") || searchParams.get("longitude") || "110.3775";
    const maxDistStr = searchParams.get("maxDistanceKm") || searchParams.get("radius") || "50";
    const requireBpjsStr = searchParams.get("requireBpjs") || "false";
    const service = searchParams.get("service") || searchParams.get("requiredService") || undefined;

    const latitude = parseFloat(latStr);
    const longitude = parseFloat(lngStr);
    const maxDistanceKm = parseFloat(maxDistStr);
    const requireBpjs = requireBpjsStr === "true";

    if (isNaN(latitude) || isNaN(longitude)) {
      return HttpResponse.error("Valid latitude and longitude numbers are required.", "VALIDATION_ERROR", 400);
    }

    const matches = await facilityService.matchFacilities({
      latitude,
      longitude,
      maxDistanceKm: isNaN(maxDistanceKm) ? 50 : maxDistanceKm,
      requireBpjs,
      requiredService: service,
    });

    const formattedFacilities = matches.map((m) => {
      const fJson = m.facility.toJSON();
      return {
        id: fJson.id,
        name: fJson.name,
        type: fJson.name.includes("RSUP")
          ? "Rumah Sakit Rujukan Nasional (Tipe A)"
          : fJson.name.includes("Puskesmas")
          ? "Faskes Primer (FKTP)"
          : "Rumah Sakit Khusus Mata (FKRTL)",
        address: fJson.address,
        distanceKm: m.distanceKm,
        bpjsStatus: fJson.bpjsStatus,
        isVerified: fJson.isVerified,
        phone: fJson.contactPhone,
        services: fJson.services,
        latitude: fJson.latitude,
        longitude: fJson.longitude,
      };
    });

    return HttpResponse.success({
      facilities: formattedFacilities,
      total: formattedFacilities.length,
      coordinates: { latitude, longitude },
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
