import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string; imageId: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const result = await screeningService.getImagePresignedUrl(params.id, params.imageId, actor);
    return HttpResponse.success(result);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
