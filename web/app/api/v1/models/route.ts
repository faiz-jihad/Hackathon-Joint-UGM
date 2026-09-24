import { NextRequest } from "next/server";
import { modelVersionService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { registerModelSchema } from "@/lib/validations/model.validation";

export async function GET(req: NextRequest) {
  try {
    AuthGuard.authenticate(req);
    const models = await modelVersionService.listModels();
    return HttpResponse.success(models.map((m) => m.toJSON()));
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function POST(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["ADMIN"]);

    const body = await req.json();
    const validated = registerModelSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const model = await modelVersionService.registerModel(validated.data, actor);
    return HttpResponse.created(model.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
