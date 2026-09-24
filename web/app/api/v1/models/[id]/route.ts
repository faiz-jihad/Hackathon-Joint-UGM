import { NextRequest } from "next/server";
import { modelVersionService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    AuthGuard.authenticate(req);
    const model = await modelVersionService.getModelById(params.id);
    return HttpResponse.success(model.toJSON());
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
