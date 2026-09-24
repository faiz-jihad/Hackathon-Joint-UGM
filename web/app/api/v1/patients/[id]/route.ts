import { NextRequest } from "next/server";
import { patientService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { updatePatientSchema } from "@/lib/validations/patient.validation";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const patient = await patientService.getPatientById(params.id, actor);
    return HttpResponse.success(patient.toJSON());
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
    const body = await req.json();
    const validated = updatePatientSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const updated = await patientService.updatePatient(params.id, validated.data, actor);
    return HttpResponse.success(updated.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
