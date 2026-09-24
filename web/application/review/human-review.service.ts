import { ScreeningRepository } from "@/domain/screening/screening.repository";
import { DiabetesProfileRepository } from "@/domain/patient/diabetes-profile.repository";
import { HumanReview, HumanReviewStatus } from "@/domain/screening/human-review.entity";
import { DRClassification } from "@/domain/screening/ai-result.entity";
import { RecommendationRulesEngine } from "@/domain/recommendation/recommendation-rules.engine";
import { AuditRepository } from "@/domain/audit/audit.repository";
import { NotFoundError, ForbiddenError, ValidationError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";
import { Screening } from "@/domain/screening/screening.entity";

export interface SubmitReviewDTO {
  reviewStatus: HumanReviewStatus;
  confirmedClass: DRClassification;
  clinicalNotes?: string;
}

export class HumanReviewService {
  constructor(
    private readonly screeningRepository: ScreeningRepository,
    private readonly diabetesProfileRepository: DiabetesProfileRepository,
    private readonly auditRepository: AuditRepository
  ) {}

  async getPendingReviews(actor: AuthenticatedActor): Promise<Screening[]> {
    if (actor.role !== "OPHTHALMOLOGIST" && actor.role !== "ADMIN") {
      throw new ForbiddenError("Only ophthalmologists or administrators can access the clinical review queue.");
    }
    return this.screeningRepository.findPendingReviews();
  }

  async submitReview(
    screeningId: string,
    dto: SubmitReviewDTO,
    actor: AuthenticatedActor
  ): Promise<{ review: HumanReview; screening: Screening; recommendation: any }> {
    if (actor.role !== "OPHTHALMOLOGIST" && actor.role !== "ADMIN") {
      throw new ForbiddenError("Only registered ophthalmologists can submit clinical diagnostic reviews.");
    }

    const screening = await this.screeningRepository.findById(screeningId);
    if (!screening) {
      throw new NotFoundError("Screening", screeningId);
    }

    if (screening.status !== "HUMAN_REVIEW" && screening.status !== "AI_ANALYZED") {
      throw new ValidationError(
        `Cannot submit human review for screening in status '${screening.status}'. Must be in HUMAN_REVIEW or AI_ANALYZED.`
      );
    }

    const humanReview = HumanReview.create({
      screeningId,
      reviewerId: actor.id,
      reviewStatus: dto.reviewStatus,
      confirmedClass: dto.confirmedClass,
      clinicalNotes: dto.clinicalNotes,
    });

    const savedReview = await this.screeningRepository.saveHumanReview(humanReview);

    // Advance screening State Machine -> SCREENING_COMPLETED
    screening.completeScreening();
    const updatedScreening = await this.screeningRepository.update(screening);

    // Automatically generate clinical recommendation based on confirmed class & diabetes profile
    const diabetesProfile = await this.diabetesProfileRepository.findByPatientId(screening.patientId);
    const recommendation = RecommendationRulesEngine.evaluate({
      screeningId: screening.id,
      confirmedClass: dto.confirmedClass,
      diabetesProfile,
    });
    const savedRecommendation = await this.screeningRepository.saveRecommendation(recommendation);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "HUMAN_REVIEW_COMPLETED",
      resource: "HumanReview",
      resourceId: savedReview.id,
      metadata: {
        screeningId,
        reviewStatus: dto.reviewStatus,
        confirmedClass: dto.confirmedClass,
        recommendedAction: savedRecommendation.recommendedAction,
      },
    });

    return {
      review: savedReview,
      screening: updatedScreening,
      recommendation: savedRecommendation,
    };
  }
}
