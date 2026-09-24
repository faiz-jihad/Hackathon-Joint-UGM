import { NextRequest } from "next/server";
import { diabetesProfileService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { upsertDiabetesProfileSchema } from "@/lib/validations/diabetes-profile.validation";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const profile = await diabetesProfileService.getProfileByPatientId(params.id, actor);

    if (!profile) {
      return HttpResponse.error("Diabetes profile not found for this patient.", "NOT_FOUND", 404);
    }

    return HttpResponse.success(profile.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = upsertDiabetesProfileSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const saved = await diabetesProfileService.upsertProfile(params.id, validated.data, actor);
    return HttpResponse.success(saved.toJSON(), 200);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  return POST(req, { params });
}
