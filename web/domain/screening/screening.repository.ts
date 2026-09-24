import { Screening, ScreeningStatus } from "./screening.entity";
import { RetinalImage } from "./retinal-image.entity";
import { QualityCheck } from "./quality-check.entity";
import { AIResult } from "./ai-result.entity";
import { ReliabilityAssessment } from "./reliability-assessment.entity";

export interface ScreeningSearchParams {
  patientId?: string;
  conductedById?: string;
  facilityId?: string;
  status?: ScreeningStatus;
  limit?: number;
  offset?: number;
}

export interface ScreeningSearchResult {
  screenings: Screening[];
  total: number;
}

import { HumanReview } from "./human-review.entity";
import { Recommendation } from "../recommendation/recommendation.entity";

export interface ScreeningRepository {
  findById(id: string): Promise<Screening | null>;
  search(params: ScreeningSearchParams): Promise<ScreeningSearchResult>;
  create(screening: Screening): Promise<Screening>;
  update(screening: Screening): Promise<Screening>;
  
  // Retinal Image sub-aggregate operations
  addImage(image: RetinalImage): Promise<RetinalImage>;
  findImageById(imageId: string): Promise<RetinalImage | null>;
  findImagesByScreeningId(screeningId: string): Promise<RetinalImage[]>;

  // Quality Check operations
  saveQualityCheck(check: QualityCheck): Promise<QualityCheck>;
  findQualityCheckByImageId(retinalImageId: string): Promise<QualityCheck | null>;
  findQualityChecksByScreeningId(screeningId: string): Promise<QualityCheck[]>;

  // AI & Reliability operations
  saveAIResult(result: AIResult): Promise<AIResult>;
  findAIResultByScreeningId(screeningId: string): Promise<AIResult | null>;
  saveReliabilityAssessment(assessment: ReliabilityAssessment): Promise<ReliabilityAssessment>;
  findReliabilityAssessmentByScreeningId(screeningId: string): Promise<ReliabilityAssessment | null>;

  // Human Review operations
  saveHumanReview(review: HumanReview): Promise<HumanReview>;
  findHumanReviewByScreeningId(screeningId: string): Promise<HumanReview | null>;
  findPendingReviews(): Promise<Screening[]>;

  // Recommendation operations
  saveRecommendation(recommendation: Recommendation): Promise<Recommendation>;
  findRecommendationByScreeningId(screeningId: string): Promise<Recommendation | null>;
}
