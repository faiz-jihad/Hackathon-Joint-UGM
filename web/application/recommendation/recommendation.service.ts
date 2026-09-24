import { ScreeningRepository } from "@/domain/screening/screening.repository";
import { DiabetesProfileRepository } from "@/domain/patient/diabetes-profile.repository";
import { RecommendationRulesEngine } from "@/domain/recommendation/recommendation-rules.engine";
import { Recommendation } from "@/domain/recommendation/recommendation.entity";
import { NotFoundError, ForbiddenError, ValidationError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";

export class RecommendationService {
  constructor(
    private readonly screeningRepository: ScreeningRepository,
    private readonly diabetesProfileRepository: DiabetesProfileRepository
  ) {}

  async generateRecommendation(screeningId: string, actor: AuthenticatedActor): Promise<Recommendation> {
    const screening = await this.screeningRepository.findById(screeningId);
    if (!screening) {
      throw new NotFoundError("Screening", screeningId);
    }

    // Determine clinical finding: Human Review takes precedence over raw AI result
    const [humanReview, aiResult] = await Promise.all([
      this.screeningRepository.findHumanReviewByScreeningId(screeningId),
      this.screeningRepository.findAIResultByScreeningId(screeningId),
    ]);

    let effectiveClass = humanReview?.confirmedClass || aiResult?.predictedClass;
    if (!effectiveClass) {
      throw new ValidationError(
        "Cannot generate recommendation: No AI classification or human review result found for this screening."
      );
    }

    const diabetesProfile = await this.diabetesProfileRepository.findByPatientId(screening.patientId);

    const recommendation = RecommendationRulesEngine.evaluate({
      screeningId: screening.id,
      confirmedClass: effectiveClass,
      diabetesProfile,
    });

    return this.screeningRepository.saveRecommendation(recommendation);
  }

  async getRecommendationByScreeningId(
    screeningId: string,
    actor: AuthenticatedActor
  ): Promise<Recommendation | null> {
    const recommendation = await this.screeningRepository.findRecommendationByScreeningId(screeningId);
    if (!recommendation) {
      throw new NotFoundError("Recommendation for screening", screeningId);
    }
    return recommendation;
  }
}
