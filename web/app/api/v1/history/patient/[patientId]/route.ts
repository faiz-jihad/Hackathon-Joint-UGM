import { NextRequest } from "next/server";
import { followUpService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(
  req: NextRequest,
  { params }: { params: { patientId: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    const history = await followUpService.getPatientHistory(params.patientId, actor);
    return HttpResponse.success(history);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
