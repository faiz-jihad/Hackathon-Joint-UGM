import { NextRequest } from "next/server";
import { humanReviewService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";
import { submitReviewSchema } from "@/lib/validations/review.validation";
import { GET as getPendingReviews } from "../pending/route";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function GET(
  req: NextRequest,
  { params }: { params: { screeningId: string } }
) {
  if (params.screeningId === "pending") {
    return getPendingReviews(req);
  }

  try {
    const cleanId = params.screeningId.replace(/^#/, "");
    const screening = await prisma.screening.findFirst({
      where: {
        OR: [{ id: cleanId }, { id: `#${cleanId}` }],
      },
      include: {
        humanReview: true,
        patient: true,
      },
    });

    if (!screening) {
      return HttpResponse.error("Screening not found", "NOT_FOUND", 404);
    }

    return HttpResponse.success({ screening });
  } catch (err: any) {
    return HttpResponse.error(err.message, "INTERNAL_ERROR", 500);
  }
}

export async function POST(
  req: NextRequest,
  { params }: { params: { screeningId: string } }
) {
  try {
    const actor = AuthGuard.authenticate(req);
    AuthGuard.requireRole(actor, ["OPHTHALMOLOGIST", "ADMIN"]);

    const body = await req.json();
    const validated = submitReviewSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await humanReviewService.submitReview(params.screeningId, validated.data, actor);

    return HttpResponse.success({
      review: result.review.toJSON(),
      screeningStatus: result.screening.status,
      recommendation: result.recommendation.toJSON(),
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
