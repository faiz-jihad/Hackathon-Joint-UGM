import { NextRequest } from "next/server";
import { authService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { loginSchema } from "@/lib/validations/auth.validation";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const validated = loginSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await authService.login(validated.data);
    return HttpResponse.success(result);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
