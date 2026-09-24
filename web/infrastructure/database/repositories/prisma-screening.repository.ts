import {
  ScreeningRepository,
  ScreeningSearchParams,
  ScreeningSearchResult,
} from "@/domain/screening/screening.repository";
import { Screening, ScreeningStatus } from "@/domain/screening/screening.entity";
import { RetinalImage, EyePosition } from "@/domain/screening/retinal-image.entity";
import { QualityCheck, QualityRetakeReason } from "@/domain/screening/quality-check.entity";
import { AIResult, DRClassification } from "@/domain/screening/ai-result.entity";
import { ReliabilityAssessment, ReliabilityStatus } from "@/domain/screening/reliability-assessment.entity";
import { HumanReview, HumanReviewStatus } from "@/domain/screening/human-review.entity";
import { Recommendation, RecommendedAction, UrgencyLevel } from "@/domain/recommendation/recommendation.entity";
import { prisma } from "../prisma/client";

export class PrismaScreeningRepository implements ScreeningRepository {
  async findById(id: string): Promise<Screening | null> {
    const record = await prisma.screening.findUnique({
      where: { id },
      include: {
        images: {
          include: {
            qualityCheck: true,
          },
        },
        aiResults: {
          orderBy: { inferenceTimestamp: "desc" },
          take: 1,
        },
        reliability: true,
      },
    });

    if (!record) return null;

    const images: RetinalImage[] = [];
    const qualityChecks: QualityCheck[] = [];

    for (const img of record.images) {
      const domainImg = RetinalImage.reconstitute({
        id: img.id,
        screeningId: img.screeningId,
        eye: img.eye as EyePosition,
        storageKey: img.storageKey,
        mimeType: img.mimeType,
        checksum: img.checksum,
        fileSizeBytes: img.fileSizeBytes,
        uploadedAt: img.uploadedAt,
      });
      images.push(domainImg);

      if (img.qualityCheck) {
        const domainQc = QualityCheck.reconstitute({
          id: img.qualityCheck.id,
          retinalImageId: img.qualityCheck.retinalImageId,
          passed: img.qualityCheck.passed,
          overallScore: img.qualityCheck.overallScore,
          blurScore: img.qualityCheck.blurScore,
          illuminationScore: img.qualityCheck.illuminationScore,
          fovScore: img.qualityCheck.fovScore,
          retakeReason: img.qualityCheck.retakeReason as QualityRetakeReason | null,
          retakeInstructions: img.qualityCheck.retakeInstructions,
          checkedAt: img.qualityCheck.checkedAt,
        });
        qualityChecks.push(domainQc);
      }
    }

    let domainAiResult: AIResult | null = null;
    if (record.aiResults && record.aiResults.length > 0) {
      const air = record.aiResults[0];
      domainAiResult = AIResult.reconstitute({
        id: air.id,
        screeningId: air.screeningId,
        modelVersionId: air.modelVersionId,
        predictedClass: air.predictedClass as DRClassification,
        confidence: air.confidence,
        rawProbabilities: (air.rawProbabilities as Record<string, number>) || {},
        inferenceDurationMs: air.inferenceDurationMs,
        inferenceTimestamp: air.inferenceTimestamp,
      });
    }

    let domainReliability: ReliabilityAssessment | null = null;
    if (record.reliability) {
      domainReliability = ReliabilityAssessment.reconstitute({
        id: record.reliability.id,
        screeningId: record.reliability.screeningId,
        status: record.reliability.status as ReliabilityStatus,
        score: record.reliability.score,
        confidenceThreshold: record.reliability.confidenceThreshold,
        qualityThreshold: record.reliability.qualityThreshold,
        reasoning: record.reliability.reasoning,
        assessedAt: record.reliability.assessedAt,
      });
    }

    return Screening.reconstitute(
      {
        id: record.id,
        patientId: record.patientId,
        conductedById: record.conductedById,
        facilityId: record.facilityId,
        status: record.status as ScreeningStatus,
        notes: record.notes,
        metadata: (record.metadata as Record<string, any>) || {},
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      },
      images,
      qualityChecks,
      domainAiResult,
      domainReliability
    );
  }

  async search(params: ScreeningSearchParams): Promise<ScreeningSearchResult> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

    const whereClause: any = {};
    if (params.patientId) whereClause.patientId = params.patientId;
    if (params.conductedById) whereClause.conductedById = params.conductedById;
    if (params.facilityId) whereClause.facilityId = params.facilityId;
    if (params.status) whereClause.status = params.status;

    const [records, total] = await Promise.all([
      prisma.screening.findMany({
        where: whereClause,
        take: limit,
        skip: offset,
        orderBy: { createdAt: "desc" },
        include: {
          images: {
            include: {
              qualityCheck: true,
            },
          },
        },
      }),
      prisma.screening.count({ where: whereClause }),
    ]);

    const screenings = records.map((record) => {
      const images: RetinalImage[] = [];
      const qualityChecks: QualityCheck[] = [];

      for (const img of record.images) {
        images.push(
          RetinalImage.reconstitute({
            id: img.id,
            screeningId: img.screeningId,
            eye: img.eye as EyePosition,
            storageKey: img.storageKey,
            mimeType: img.mimeType,
            checksum: img.checksum,
            fileSizeBytes: img.fileSizeBytes,
            uploadedAt: img.uploadedAt,
          })
        );

        if (img.qualityCheck) {
          qualityChecks.push(
            QualityCheck.reconstitute({
              id: img.qualityCheck.id,
              retinalImageId: img.qualityCheck.retinalImageId,
              passed: img.qualityCheck.passed,
              overallScore: img.qualityCheck.overallScore,
              blurScore: img.qualityCheck.blurScore,
              illuminationScore: img.qualityCheck.illuminationScore,
              fovScore: img.qualityCheck.fovScore,
              retakeReason: img.qualityCheck.retakeReason as QualityRetakeReason | null,
              retakeInstructions: img.qualityCheck.retakeInstructions,
              checkedAt: img.qualityCheck.checkedAt,
            })
          );
        }
      }

      return Screening.reconstitute(
        {
          id: record.id,
          patientId: record.patientId,
          conductedById: record.conductedById,
          facilityId: record.facilityId,
          status: record.status as ScreeningStatus,
          notes: record.notes,
          metadata: (record.metadata as Record<string, any>) || {},
          createdAt: record.createdAt,
          updatedAt: record.updatedAt,
        },
        images,
        qualityChecks
      );
    });

    return { screenings, total };
  }

  async create(screening: Screening): Promise<Screening> {
    const record = await prisma.screening.create({
      data: {
        id: screening.id,
        patientId: screening.patientId,
        conductedById: screening.conductedById,
        facilityId: screening.facilityId,
        status: screening.status,
        notes: screening.notes,
        metadata: screening.metadata || {},
      },
    });

    return Screening.reconstitute({
      id: record.id,
      patientId: record.patientId,
      conductedById: record.conductedById,
      facilityId: record.facilityId,
      status: record.status as ScreeningStatus,
      notes: record.notes,
      metadata: (record.metadata as Record<string, any>) || {},
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  async update(screening: Screening): Promise<Screening> {
    const record = await prisma.screening.update({
      where: { id: screening.id },
      data: {
        status: screening.status,
        notes: screening.notes,
        metadata: screening.metadata || {},
      },
    });

    return Screening.reconstitute(
      {
        id: record.id,
        patientId: record.patientId,
        conductedById: record.conductedById,
        facilityId: record.facilityId,
        status: record.status as ScreeningStatus,
        notes: record.notes,
        metadata: (record.metadata as Record<string, any>) || {},
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      },
      [...screening.images],
      Array.from(screening.qualityChecks.values())
    );
  }

  async addImage(image: RetinalImage): Promise<RetinalImage> {
    // Delete any previous image for the same eye in this screening to prevent duplicate OD/OS
    await prisma.retinalImage.deleteMany({
      where: {
        screeningId: image.screeningId,
        eye: image.eye,
      },
    });

    const record = await prisma.retinalImage.create({
      data: {
        id: image.id,
        screeningId: image.screeningId,
        eye: image.eye,
        storageKey: image.storageKey,
        mimeType: image.mimeType,
        checksum: image.checksum,
        fileSizeBytes: image.fileSizeBytes,
      },
    });

    return RetinalImage.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      eye: record.eye as EyePosition,
      storageKey: record.storageKey,
      mimeType: record.mimeType,
      checksum: record.checksum,
      fileSizeBytes: record.fileSizeBytes,
      uploadedAt: record.uploadedAt,
    });
  }

  async findImageById(imageId: string): Promise<RetinalImage | null> {
    const record = await prisma.retinalImage.findUnique({
      where: { id: imageId },
    });
    if (!record) return null;

    return RetinalImage.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      eye: record.eye as EyePosition,
      storageKey: record.storageKey,
      mimeType: record.mimeType,
      checksum: record.checksum,
      fileSizeBytes: record.fileSizeBytes,
      uploadedAt: record.uploadedAt,
    });
  }

  async findImagesByScreeningId(screeningId: string): Promise<RetinalImage[]> {
    const records = await prisma.retinalImage.findMany({
      where: { screeningId },
      orderBy: { eye: "asc" },
    });

    return records.map((record) =>
      RetinalImage.reconstitute({
        id: record.id,
        screeningId: record.screeningId,
        eye: record.eye as EyePosition,
        storageKey: record.storageKey,
        mimeType: record.mimeType,
        checksum: record.checksum,
        fileSizeBytes: record.fileSizeBytes,
        uploadedAt: record.uploadedAt,
      })
    );
  }

  async saveQualityCheck(check: QualityCheck): Promise<QualityCheck> {
    const record = await prisma.qualityCheck.upsert({
      where: { retinalImageId: check.retinalImageId },
      create: {
        id: check.id,
        retinalImageId: check.retinalImageId,
        passed: check.passed,
        overallScore: check.overallScore,
        blurScore: check.blurScore,
        illuminationScore: check.illuminationScore,
        fovScore: check.fovScore,
        retakeReason: check.retakeReason,
        retakeInstructions: check.retakeInstructions,
      },
      update: {
        passed: check.passed,
        overallScore: check.overallScore,
        blurScore: check.blurScore,
        illuminationScore: check.illuminationScore,
        fovScore: check.fovScore,
        retakeReason: check.retakeReason,
        retakeInstructions: check.retakeInstructions,
      },
    });

    return QualityCheck.reconstitute({
      id: record.id,
      retinalImageId: record.retinalImageId,
      passed: record.passed,
      overallScore: record.overallScore,
      blurScore: record.blurScore,
      illuminationScore: record.illuminationScore,
      fovScore: record.fovScore,
      retakeReason: record.retakeReason as QualityRetakeReason | null,
      retakeInstructions: record.retakeInstructions,
      checkedAt: record.checkedAt,
    });
  }

  async findQualityCheckByImageId(retinalImageId: string): Promise<QualityCheck | null> {
    const record = await prisma.qualityCheck.findUnique({
      where: { retinalImageId },
    });
    if (!record) return null;

    return QualityCheck.reconstitute({
      id: record.id,
      retinalImageId: record.retinalImageId,
      passed: record.passed,
      overallScore: record.overallScore,
      blurScore: record.blurScore,
      illuminationScore: record.illuminationScore,
      fovScore: record.fovScore,
      retakeReason: record.retakeReason as QualityRetakeReason | null,
      retakeInstructions: record.retakeInstructions,
      checkedAt: record.checkedAt,
    });
  }

  async findQualityChecksByScreeningId(screeningId: string): Promise<QualityCheck[]> {
    const images = await prisma.retinalImage.findMany({
      where: { screeningId },
      select: { id: true },
    });

    const imageIds = images.map((img) => img.id);
    const records = await prisma.qualityCheck.findMany({
      where: { retinalImageId: { in: imageIds } },
    });

    return records.map((record) =>
      QualityCheck.reconstitute({
        id: record.id,
        retinalImageId: record.retinalImageId,
        passed: record.passed,
        overallScore: record.overallScore,
        blurScore: record.blurScore,
        illuminationScore: record.illuminationScore,
        fovScore: record.fovScore,
        retakeReason: record.retakeReason as QualityRetakeReason | null,
        retakeInstructions: record.retakeInstructions,
        checkedAt: record.checkedAt,
      })
    );
  }

  async saveAIResult(result: AIResult): Promise<AIResult> {
    const record = await prisma.aIResult.create({
      data: {
        id: result.id,
        screeningId: result.screeningId,
        modelVersionId: result.modelVersionId,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        rawProbabilities: result.rawProbabilities,
        inferenceDurationMs: result.inferenceDurationMs,
      },
    });

    return AIResult.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      modelVersionId: record.modelVersionId,
      predictedClass: record.predictedClass as DRClassification,
      confidence: record.confidence,
      rawProbabilities: record.rawProbabilities as Record<string, number>,
      inferenceDurationMs: record.inferenceDurationMs,
      inferenceTimestamp: record.inferenceTimestamp,
    });
  }

  async findAIResultByScreeningId(screeningId: string): Promise<AIResult | null> {
    const record = await prisma.aIResult.findFirst({
      where: { screeningId },
      orderBy: { inferenceTimestamp: "desc" },
    });
    if (!record) return null;

    return AIResult.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      modelVersionId: record.modelVersionId,
      predictedClass: record.predictedClass as DRClassification,
      confidence: record.confidence,
      rawProbabilities: record.rawProbabilities as Record<string, number>,
      inferenceDurationMs: record.inferenceDurationMs,
      inferenceTimestamp: record.inferenceTimestamp,
    });
  }

  async saveReliabilityAssessment(assessment: ReliabilityAssessment): Promise<ReliabilityAssessment> {
    const record = await prisma.reliabilityAssessment.upsert({
      where: { screeningId: assessment.screeningId },
      create: {
        id: assessment.id,
        screeningId: assessment.screeningId,
        status: assessment.status,
        score: assessment.score,
        confidenceThreshold: assessment.confidenceThreshold,
        qualityThreshold: assessment.qualityThreshold,
        reasoning: assessment.reasoning,
      },
      update: {
        status: assessment.status,
        score: assessment.score,
        confidenceThreshold: assessment.confidenceThreshold,
        qualityThreshold: assessment.qualityThreshold,
        reasoning: assessment.reasoning,
      },
    });

    return ReliabilityAssessment.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      status: record.status as ReliabilityStatus,
      score: record.score,
      confidenceThreshold: record.confidenceThreshold,
      qualityThreshold: record.qualityThreshold,
      reasoning: record.reasoning,
      assessedAt: record.assessedAt,
    });
  }

  async findReliabilityAssessmentByScreeningId(screeningId: string): Promise<ReliabilityAssessment | null> {
    const record = await prisma.reliabilityAssessment.findUnique({
      where: { screeningId },
    });
    if (!record) return null;

    return ReliabilityAssessment.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      status: record.status as ReliabilityStatus,
      score: record.score,
      confidenceThreshold: record.confidenceThreshold,
      qualityThreshold: record.qualityThreshold,
      reasoning: record.reasoning,
      assessedAt: record.assessedAt,
    });
  }

  async saveHumanReview(review: HumanReview): Promise<HumanReview> {
    const record = await prisma.humanReview.upsert({
      where: { screeningId: review.screeningId },
      create: {
        id: review.id,
        screeningId: review.screeningId,
        reviewerId: review.reviewerId,
        reviewStatus: review.reviewStatus,
        confirmedClass: review.confirmedClass,
        clinicalNotes: review.clinicalNotes,
      },
      update: {
        reviewerId: review.reviewerId,
        reviewStatus: review.reviewStatus,
        confirmedClass: review.confirmedClass,
        clinicalNotes: review.clinicalNotes,
      },
    });

    return HumanReview.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      reviewerId: record.reviewerId,
      reviewStatus: record.reviewStatus as HumanReviewStatus,
      confirmedClass: record.confirmedClass as DRClassification,
      clinicalNotes: record.clinicalNotes,
      reviewedAt: record.reviewedAt,
    });
  }

  async findHumanReviewByScreeningId(screeningId: string): Promise<HumanReview | null> {
    const record = await prisma.humanReview.findUnique({
      where: { screeningId },
    });
    if (!record) return null;

    return HumanReview.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      reviewerId: record.reviewerId,
      reviewStatus: record.reviewStatus as HumanReviewStatus,
      confirmedClass: record.confirmedClass as DRClassification,
      clinicalNotes: record.clinicalNotes,
      reviewedAt: record.reviewedAt,
    });
  }

  async findPendingReviews(): Promise<Screening[]> {
    const result = await this.search({ status: "HUMAN_REVIEW", limit: 50 });
    return result.screenings;
  }

  async saveRecommendation(recommendation: Recommendation): Promise<Recommendation> {
    const record = await prisma.recommendation.upsert({
      where: { screeningId: recommendation.screeningId },
      create: {
        id: recommendation.id,
        screeningId: recommendation.screeningId,
        summary: recommendation.summary,
        recommendedAction: recommendation.recommendedAction,
        urgencyLevel: recommendation.urgencyLevel,
        referralIndicated: recommendation.referralIndicated,
        clinicalGuideline: recommendation.clinicalGuideline,
      },
      update: {
        summary: recommendation.summary,
        recommendedAction: recommendation.recommendedAction,
        urgencyLevel: recommendation.urgencyLevel,
        referralIndicated: recommendation.referralIndicated,
        clinicalGuideline: recommendation.clinicalGuideline,
      },
    });

    return Recommendation.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      summary: record.summary,
      recommendedAction: record.recommendedAction as RecommendedAction,
      urgencyLevel: record.urgencyLevel as UrgencyLevel,
      referralIndicated: record.referralIndicated,
      clinicalGuideline: record.clinicalGuideline,
      generatedAt: record.generatedAt,
    });
  }

  async findRecommendationByScreeningId(screeningId: string): Promise<Recommendation | null> {
    const record = await prisma.recommendation.findUnique({
      where: { screeningId },
    });
    if (!record) return null;

    return Recommendation.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      summary: record.summary,
      recommendedAction: record.recommendedAction as RecommendedAction,
      urgencyLevel: record.urgencyLevel as UrgencyLevel,
      referralIndicated: record.referralIndicated,
      clinicalGuideline: record.clinicalGuideline,
      generatedAt: record.generatedAt,
    });
  }
}
