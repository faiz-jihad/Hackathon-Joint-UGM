import { NextRequest } from "next/server";
import { authService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(req: NextRequest) {
  try {
    const actor = AuthGuard.authenticate(req);
    const user = await authService.getCurrentUser(actor.id);
    return HttpResponse.success(user.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
