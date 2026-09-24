import { NextRequest } from "next/server";
import { diabetesProfileService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { upsertDiabetesProfileSchema } from "@/lib/validations/diabetes-profile.validation";
import { z } from "zod";

const createWithPatientIdSchema = upsertDiabetesProfileSchema.extend({
  patientId: z.string().uuid("Invalid patientId format"),
});

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = createWithPatientIdSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const { patientId, ...profileData } = validated.data;
    const saved = await diabetesProfileService.upsertProfile(patientId, profileData, actor);
    return HttpResponse.success(saved.toJSON(), 201);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
