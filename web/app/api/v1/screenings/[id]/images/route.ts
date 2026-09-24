import { NextRequest } from "next/server";
import { screeningService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { EyePosition } from "@/domain/screening/retinal-image.entity";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN"]);

    const formData = await req.formData();
    const eye = formData.get("eye") as string;
    const file = formData.get("file") as File | null;

    if (!eye || (eye !== "OD" && eye !== "OS")) {
      return HttpResponse.error("Field 'eye' is required and must be 'OD' or 'OS'.", "VALIDATION_ERROR", 400);
    }

    if (!file) {
      return HttpResponse.error("Field 'file' is required and must contain a retinal image.", "VALIDATION_ERROR", 400);
    }

    const mimeType = file.type || "image/jpeg";
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    if (buffer.length === 0) {
      return HttpResponse.error("The uploaded file is empty.", "VALIDATION_ERROR", 400);
    }

    const result = await screeningService.uploadRetinalImage(
      params.id,
      {
        eye: eye as EyePosition,
        mimeType,
        fileBuffer: buffer,
      },
      actor
    );

    return HttpResponse.created({
      retinalImage: result.retinalImage.toJSON(),
      screeningStatus: result.screeningStatus,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
