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
  private static memoryScreenings: Map<string, Screening> = new Map();
  private static memoryImages: Map<string, RetinalImage> = new Map();
  private static memoryQualityChecks: Map<string, QualityCheck> = new Map();
  private static memoryAiResults: Map<string, AIResult> = new Map();
  private static memoryReliabilities: Map<string, ReliabilityAssessment> = new Map();
  private static memoryReviews: Map<string, HumanReview> = new Map();
  private static memoryRecommendations: Map<string, Recommendation> = new Map();

  constructor() {
    if (PrismaScreeningRepository.memoryScreenings.size === 0) {
      this.seedInitial();
    }
  }

  private seedInitial() {
    // Screening 1: Bambang Sudarmono (Moderate NPDR - Needs Review)
    const s1Id = "SCR-2026-0891";
    const img1 = RetinalImage.reconstitute({
      id: "IMG-OD-0891",
      screeningId: s1Id,
      eye: "OD",
      storageKey: "fundus/2026/09/SCR-2026-0891-OD.jpg",
      mimeType: "image/jpeg",
      checksum: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      fileSizeBytes: 2451000,
      uploadedAt: new Date("2026-09-24T09:14:00Z"),
    });

    const qc1 = QualityCheck.reconstitute({
      id: "QC-0891",
      retinalImageId: img1.id,
      passed: true,
      overallScore: 0.84,
      blurScore: 0.85,
      illuminationScore: 0.80,
      fovScore: 0.90,
      retakeReason: null,
      retakeInstructions: null,
      checkedAt: new Date("2026-09-24T09:14:30Z"),
    });

    const air1 = AIResult.reconstitute({
      id: "AIR-0891",
      screeningId: s1Id,
      modelVersionId: "mod-001",
      predictedClass: "MODERATE_DR",
      confidence: 87.4,
      rawProbabilities: {
        NO_DR: 0.021,
        MILD_NPDR: 0.093,
        MODERATE_NPDR: 0.874,
        SEVERE_NPDR: 0.011,
        PDR: 0.001,
      },
      inferenceDurationMs: 412,
      inferenceTimestamp: new Date("2026-09-24T09:15:00Z"),
    });

    const rel1 = ReliabilityAssessment.reconstitute({
      id: "REL-0891",
      screeningId: s1Id,
      status: "HUMAN_REVIEW",
      score: 0.874,
      confidenceThreshold: 0.90,
      qualityThreshold: 0.70,
      reasoning: "Borderline confidence below 90% threshold requires ophthalmologist adjudication.",
      assessedAt: new Date("2026-09-24T09:15:05Z"),
    });

    const s1 = Screening.reconstitute(
      {
        id: s1Id,
        patientId: "P-001",
        conductedById: "usr-002",
        facilityId: "FAC-001",
        status: "HUMAN_REVIEW",
        notes: "Skrining rutin tahunan pasien DM Tipe 2 dengan kendali glikemik suboptimal (HbA1c 8.2%).",
        metadata: { patientName: "Bambang Sudarmono", patientNik: "3404071203720001" },
        createdAt: new Date("2026-09-24T09:14:00Z"),
        updatedAt: new Date("2026-09-24T09:15:05Z"),
      },
      [img1],
      [qc1],
      air1,
      rel1
    );

    // Screening 2: Siti Aminah (Severe NPDR - High Reliability, Confirmed by dr. Hendra)
    const s2Id = "SCR-2026-0890";
    const img2 = RetinalImage.reconstitute({
      id: "IMG-OS-0890",
      screeningId: s2Id,
      eye: "OS",
      storageKey: "fundus/2026/09/SCR-2026-0890-OS.jpg",
      mimeType: "image/jpeg",
      checksum: "f4a1c55298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b866",
      fileSizeBytes: 2780000,
      uploadedAt: new Date("2026-09-24T08:40:00Z"),
    });

    const qc2 = QualityCheck.reconstitute({
      id: "QC-0890",
      retinalImageId: img2.id,
      passed: true,
      overallScore: 0.89,
      blurScore: 0.90,
      illuminationScore: 0.85,
      fovScore: 0.92,
      retakeReason: null,
      retakeInstructions: null,
      checkedAt: new Date("2026-09-24T08:41:00Z"),
    });

    const air2 = AIResult.reconstitute({
      id: "AIR-0890",
      screeningId: s2Id,
      modelVersionId: "mod-001",
      predictedClass: "SEVERE_DR",
      confidence: 94.2,
      rawProbabilities: {
        NO_DR: 0.002,
        MILD_NPDR: 0.012,
        MODERATE_NPDR: 0.044,
        SEVERE_NPDR: 0.942,
        PDR: 0.000,
      },
      inferenceDurationMs: 388,
      inferenceTimestamp: new Date("2026-09-24T08:42:00Z"),
    });

    const rel2 = ReliabilityAssessment.reconstitute({
      id: "REL-0890",
      screeningId: s2Id,
      status: "ANALYZE",
      score: 0.942,
      confidenceThreshold: 0.90,
      qualityThreshold: 0.70,
      reasoning: "High inference confidence (94.2%) with excellent retinal image quality (0.89).",
      assessedAt: new Date("2026-09-24T08:42:05Z"),
    });

    const hr2 = HumanReview.reconstitute({
      id: "HR-0890",
      screeningId: s2Id,
      reviewerId: "usr-001",
      reviewStatus: "CONFIRMED_AI",
      confirmedClass: "SEVERE_DR",
      clinicalNotes: "Tampak perdarahan intraretina difus pada 4 kuadran sesuai aturan 4-2-1. Rujukan prioritas cito ke sub-spesialis retina.",
      reviewedAt: new Date("2026-09-24T09:00:00Z"),
    });

    const rec2 = Recommendation.reconstitute({
      id: "REC-0890",
      screeningId: s2Id,
      summary: "Severe NPDR terkonfirmasi, rujukan cito ke FKRTL",
      recommendedAction: "SPECIALIST_OPHTHALMOLOGY_REFERRAL",
      urgencyLevel: "HIGH",
      referralIndicated: true,
      clinicalGuideline: "Perdami 2024 / ADA 2024",
      generatedAt: new Date("2026-09-24T09:01:00Z"),
    });

    const s2 = Screening.reconstitute(
      {
        id: s2Id,
        patientId: "P-002",
        conductedById: "usr-002",
        facilityId: "FAC-001",
        status: "SCREENING_COMPLETED",
        notes: "Pemeriksaan mata kiri menunjukkan retinopati diabetik derajat berat.",
        metadata: { patientName: "Siti Aminah", patientNik: "3404084501650002" },
        createdAt: new Date("2026-09-24T08:40:00Z"),
        updatedAt: new Date("2026-09-24T09:01:00Z"),
      },
      [img2],
      [qc2],
      air2,
      rel2
    );

    PrismaScreeningRepository.memoryImages.set(img1.id, img1);
    PrismaScreeningRepository.memoryImages.set(img2.id, img2);
    PrismaScreeningRepository.memoryQualityChecks.set(qc1.retinalImageId, qc1);
    PrismaScreeningRepository.memoryQualityChecks.set(qc2.retinalImageId, qc2);
    PrismaScreeningRepository.memoryAiResults.set(air1.screeningId, air1);
    PrismaScreeningRepository.memoryAiResults.set(air2.screeningId, air2);
    PrismaScreeningRepository.memoryReliabilities.set(rel1.screeningId, rel1);
    PrismaScreeningRepository.memoryReliabilities.set(rel2.screeningId, rel2);
    PrismaScreeningRepository.memoryReviews.set(hr2.screeningId, hr2);
    PrismaScreeningRepository.memoryRecommendations.set(rec2.screeningId, rec2);

    PrismaScreeningRepository.memoryScreenings.set(s1.id, s1);
    PrismaScreeningRepository.memoryScreenings.set(s2.id, s2);
  }

  async findById(id: string): Promise<Screening | null> {
    try {
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

      if (!record) return PrismaScreeningRepository.memoryScreenings.get(id) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryScreenings.get(id) || null;
    }
  }

  async search(params: ScreeningSearchParams): Promise<ScreeningSearchResult> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

    try {
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
    } catch {
      let list = Array.from(PrismaScreeningRepository.memoryScreenings.values());
      if (params.patientId) list = list.filter((s) => s.patientId === params.patientId);
      if (params.conductedById) list = list.filter((s) => s.conductedById === params.conductedById);
      if (params.facilityId) list = list.filter((s) => s.facilityId === params.facilityId);
      if (params.status) list = list.filter((s) => s.status === params.status);

      return {
        screenings: list.slice(offset, offset + limit),
        total: list.length,
      };
    }
  }

  async create(screening: Screening): Promise<Screening> {
    PrismaScreeningRepository.memoryScreenings.set(screening.id, screening);
    try {
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
    } catch {
      return screening;
    }
  }

  async update(screening: Screening): Promise<Screening> {
    PrismaScreeningRepository.memoryScreenings.set(screening.id, screening);
    try {
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
    } catch {
      return screening;
    }
  }

  async addImage(image: RetinalImage): Promise<RetinalImage> {
    PrismaScreeningRepository.memoryImages.set(image.id, image);
    try {
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
    } catch {
      return image;
    }
  }

  async findImageById(imageId: string): Promise<RetinalImage | null> {
    try {
      const record = await prisma.retinalImage.findUnique({
        where: { id: imageId },
      });
      if (!record) return PrismaScreeningRepository.memoryImages.get(imageId) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryImages.get(imageId) || null;
    }
  }

  async findImagesByScreeningId(screeningId: string): Promise<RetinalImage[]> {
    try {
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
    } catch {
      return Array.from(PrismaScreeningRepository.memoryImages.values()).filter(
        (img) => img.screeningId === screeningId
      );
    }
  }

  async saveQualityCheck(check: QualityCheck): Promise<QualityCheck> {
    PrismaScreeningRepository.memoryQualityChecks.set(check.retinalImageId, check);
    try {
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
    } catch {
      return check;
    }
  }

  async findQualityCheckByImageId(retinalImageId: string): Promise<QualityCheck | null> {
    try {
      const record = await prisma.qualityCheck.findUnique({
        where: { retinalImageId },
      });
      if (!record) return PrismaScreeningRepository.memoryQualityChecks.get(retinalImageId) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryQualityChecks.get(retinalImageId) || null;
    }
  }

  async findQualityChecksByScreeningId(screeningId: string): Promise<QualityCheck[]> {
    try {
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
    } catch {
      const screenImages = Array.from(PrismaScreeningRepository.memoryImages.values()).filter(
        (img) => img.screeningId === screeningId
      );
      return screenImages
        .map((img) => PrismaScreeningRepository.memoryQualityChecks.get(img.id))
        .filter((qc): qc is QualityCheck => !!qc);
    }
  }

  async saveAIResult(result: AIResult): Promise<AIResult> {
    PrismaScreeningRepository.memoryAiResults.set(result.screeningId, result);
    try {
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
    } catch {
      return result;
    }
  }

  async findAIResultByScreeningId(screeningId: string): Promise<AIResult | null> {
    try {
      const record = await prisma.aIResult.findFirst({
        where: { screeningId },
        orderBy: { inferenceTimestamp: "desc" },
      });
      if (!record) return PrismaScreeningRepository.memoryAiResults.get(screeningId) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryAiResults.get(screeningId) || null;
    }
  }

  async saveReliabilityAssessment(assessment: ReliabilityAssessment): Promise<ReliabilityAssessment> {
    PrismaScreeningRepository.memoryReliabilities.set(assessment.screeningId, assessment);
    try {
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
    } catch {
      return assessment;
    }
  }

  async findReliabilityAssessmentByScreeningId(screeningId: string): Promise<ReliabilityAssessment | null> {
    try {
      const record = await prisma.reliabilityAssessment.findUnique({
        where: { screeningId },
      });
      if (!record) return PrismaScreeningRepository.memoryReliabilities.get(screeningId) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryReliabilities.get(screeningId) || null;
    }
  }

  async saveHumanReview(review: HumanReview): Promise<HumanReview> {
    PrismaScreeningRepository.memoryReviews.set(review.screeningId, review);
    try {
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
    } catch {
      return review;
    }
  }

  async findHumanReviewByScreeningId(screeningId: string): Promise<HumanReview | null> {
    try {
      const record = await prisma.humanReview.findUnique({
        where: { screeningId },
      });
      if (!record) return PrismaScreeningRepository.memoryReviews.get(screeningId) || null;

      return HumanReview.reconstitute({
        id: record.id,
        screeningId: record.screeningId,
        reviewerId: record.reviewerId,
        reviewStatus: record.reviewStatus as HumanReviewStatus,
        confirmedClass: record.confirmedClass as DRClassification,
        clinicalNotes: record.clinicalNotes,
        reviewedAt: record.reviewedAt,
      });
    } catch {
      return PrismaScreeningRepository.memoryReviews.get(screeningId) || null;
    }
  }

  async findPendingReviews(): Promise<Screening[]> {
    const result = await this.search({ status: "HUMAN_REVIEW", limit: 50 });
    return result.screenings;
  }

  async saveRecommendation(recommendation: Recommendation): Promise<Recommendation> {
    PrismaScreeningRepository.memoryRecommendations.set(recommendation.screeningId, recommendation);
    try {
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
    } catch {
      return recommendation;
    }
  }

  async findRecommendationByScreeningId(screeningId: string): Promise<Recommendation | null> {
    try {
      const record = await prisma.recommendation.findUnique({
        where: { screeningId },
      });
      if (!record) return PrismaScreeningRepository.memoryRecommendations.get(screeningId) || null;

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
    } catch {
      return PrismaScreeningRepository.memoryRecommendations.get(screeningId) || null;
    }
  }
}
