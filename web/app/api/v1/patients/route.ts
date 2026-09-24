import { NextRequest } from "next/server";
import { patientService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { createPatientSchema, searchPatientSchema } from "@/lib/validations/patient.validation";

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const searchParams = req.nextUrl.searchParams;
    const query = searchParams.get("query") || undefined;
    const limit = searchParams.get("limit") || "20";
    const offset = searchParams.get("offset") || "0";

    const validated = searchPatientSchema.safeParse({ query, limit, offset });
    if (!validated.success) {
      return HttpResponse.error(
        "Invalid query parameters",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await patientService.searchPatients(validated.data, actor);

    return HttpResponse.success(
      result.patients.map((p) => p.toJSON()),
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

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    // Patients can only register their own profile; workers/admins can register any patient
    const body = await req.json();
    const validated = createPatientSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const patient = await patientService.createPatient(validated.data, actor);
    return HttpResponse.created(patient.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
