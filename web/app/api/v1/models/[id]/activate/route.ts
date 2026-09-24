import { NextRequest } from "next/server";
import { modelVersionService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["ADMIN"]);

    const activated = await modelVersionService.activateModel(params.id, actor);
    return HttpResponse.success(activated.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
