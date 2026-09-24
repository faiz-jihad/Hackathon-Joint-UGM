import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const screening = await screeningService.getScreeningById(params.id, actor);
    return HttpResponse.success(screening.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
