import { ScreeningRepository, ScreeningSearchParams, ScreeningSearchResult } from "@/domain/screening/screening.repository";
import { PatientRepository } from "@/domain/patient/patient.repository";
import { ModelVersionRepository } from "@/domain/model-version/model-version.repository";
import { ImageStorage } from "@/domain/screening/image-storage.interface";
import { AIClient } from "@/domain/screening/ai-client.interface";
import { AuditRepository } from "@/domain/audit/audit.repository";
import { Screening } from "@/domain/screening/screening.entity";
import { RetinalImage, EyePosition } from "@/domain/screening/retinal-image.entity";
import { QualityCheck, QualityRetakeReason } from "@/domain/screening/quality-check.entity";
import { AIResult, DRClassification } from "@/domain/screening/ai-result.entity";
import { ReliabilityAssessment, ReliabilityStatus } from "@/domain/screening/reliability-assessment.entity";
import { ModelVersion } from "@/domain/model-version/model-version.entity";
import { NotFoundError, ForbiddenError, ValidationError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";

export interface InitiateScreeningDTO {
  patientId: string;
  notes?: string;
  metadata?: Record<string, any>;
}

export interface UploadRetinalImageDTO {
  eye: EyePosition;
  mimeType: string;
  fileBuffer: Buffer | Uint8Array;
}

export class ScreeningService {
  constructor(
    private readonly screeningRepository: ScreeningRepository,
    private readonly patientRepository: PatientRepository,
    private readonly modelVersionRepository: ModelVersionRepository,
    private readonly imageStorage: ImageStorage,
    private readonly aiClient: AIClient,
    private readonly auditRepository: AuditRepository
  ) {}

  async initiateScreening(dto: InitiateScreeningDTO, actor: AuthenticatedActor): Promise<Screening> {
    const patient = await this.patientRepository.findById(dto.patientId);
    if (!patient) {
      throw new NotFoundError("Patient", dto.patientId);
    }

    const screening = Screening.create({
      patientId: dto.patientId,
      conductedById: actor.id,
      facilityId: actor.facilityId ?? null,
      notes: dto.notes ?? null,
      metadata: dto.metadata ?? {},
    });

    const saved = await this.screeningRepository.create(screening);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "SCREENING_INITIATED",
      resource: "Screening",
      resourceId: saved.id,
      metadata: { patientId: dto.patientId },
    });

    return saved;
  }

  async getScreeningById(id: string, actor: AuthenticatedActor): Promise<Screening> {
    const screening = await this.screeningRepository.findById(id);
    if (!screening) {
      throw new NotFoundError("Screening", id);
    }

    if (actor.role === "PATIENT") {
      const patient = await this.patientRepository.findById(screening.patientId);
      if (!patient || patient.userId !== actor.id) {
        throw new ForbiddenError("Patients can only view their own screening records.");
      }
    }

    return screening;
  }

  async searchScreenings(params: ScreeningSearchParams, actor: AuthenticatedActor): Promise<ScreeningSearchResult> {
    if (actor.role === "PATIENT") {
      const patient = await this.patientRepository.findByUserId(actor.id);
      if (!patient) {
        return { screenings: [], total: 0 };
      }
      params.patientId = patient.id;
    }

    return this.screeningRepository.search(params);
  }

  async uploadRetinalImage(
    screeningId: string,
    dto: UploadRetinalImageDTO,
    actor: AuthenticatedActor
  ): Promise<{ retinalImage: RetinalImage; screeningStatus: string }> {
    const screening = await this.screeningRepository.findById(screeningId);
    if (!screening) {
      throw new NotFoundError("Screening", screeningId);
    }

    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Patients are not authorized to upload raw fundus imaging directly.");
    }

    const ext = dto.mimeType.split("/")[1] || "jpg";
    const storageKey = `screenings/${screeningId}/${dto.eye.toLowerCase()}_${Date.now()}.${ext}`;

    // Upload to Object Storage via abstraction (S3 / MinIO / Cloudflare R2)
    const { checksum } = await this.imageStorage.upload({
      storageKey,
      data: dto.fileBuffer,
      mimeType: dto.mimeType,
    });

    const retinalImage = RetinalImage.create({
      screeningId,
      eye: dto.eye,
      storageKey,
      mimeType: dto.mimeType,
      checksum,
      fileSizeBytes: dto.fileBuffer.length,
    });

    // Save image to DB
    const savedImage = await this.screeningRepository.addImage(retinalImage);

    // Update aggregate state machine -> IMAGE_UPLOADED
    screening.addImage(savedImage);
    await this.screeningRepository.update(screening);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "RETINAL_IMAGE_UPLOADED",
      resource: "RetinalImage",
      resourceId: savedImage.id,
      metadata: {
        screeningId,
        eye: dto.eye,
        checksum,
        storageKey,
      },
    });

    return {
      retinalImage: savedImage,
      screeningStatus: screening.status,
    };
  }

  async runQualityGate(
    screeningId: string,
    actor: AuthenticatedActor
  ): Promise<{ screening: Screening; passed: boolean; details: QualityCheck[] }> {
    const screening = await this.screeningRepository.findById(screeningId);
    if (!screening) {
      throw new NotFoundError("Screening", screeningId);
    }

    if (screening.images.length === 0) {
      throw new ValidationError("Cannot run quality check: No retinal images have been uploaded yet.");
    }

    const qualityChecks: QualityCheck[] = [];

    // Evaluate each uploaded fundus image through the AI Quality Gate
    for (const img of screening.images) {
      const signedUrl = await this.imageStorage.getSignedUrl(img.storageKey, 600);
      const aiQuality = await this.aiClient.checkQuality(signedUrl, img.eye);

      const qualityCheck = QualityCheck.create({
        retinalImageId: img.id,
        passed: aiQuality.passed,
        overallScore: aiQuality.overallScore,
        blurScore: aiQuality.blurScore,
        illuminationScore: aiQuality.illuminationScore,
        fovScore: aiQuality.fovScore,
        retakeReason: (aiQuality.retakeReason as QualityRetakeReason) || (aiQuality.passed ? null : "OTHER"),
        retakeInstructions: aiQuality.retakeInstructions,
      });

      const savedQc = await this.screeningRepository.saveQualityCheck(qualityCheck);
      qualityChecks.push(savedQc);
      screening.recordQualityCheck(savedQc);
    }

    // Persist updated state machine transition (QUALITY_CHECK or RETAKE_REQUIRED)
    const updatedScreening = await this.screeningRepository.update(screening);

    const isPassed = updatedScreening.status === "QUALITY_CHECK";

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: isPassed ? "QUALITY_GATE_PASSED" : "QUALITY_GATE_FAILED_RETAKE_REQUIRED",
      resource: "Screening",
      resourceId: screeningId,
      metadata: {
        finalStatus: updatedScreening.status,
        passed: isPassed,
        results: qualityChecks.map((q) => q.toJSON()),
      },
    });

    return {
      screening: updatedScreening,
      passed: isPassed,
      details: qualityChecks,
    };
  }

  async analyzeScreening(
    screeningId: string,
    actor: AuthenticatedActor
  ): Promise<{ screening: Screening; aiResult: AIResult; reliability: ReliabilityAssessment }> {
    const screening = await this.screeningRepository.findById(screeningId);
    if (!screening) {
      throw new NotFoundError("Screening", screeningId);
    }

    // Strict Architectural Rule: Image Quality Gate must pass before AI inference
    if (screening.status !== "QUALITY_CHECK") {
      throw new ValidationError(
        `Cannot execute AI screening: Current status is '${screening.status}'. Screening must pass Quality Gate (status: QUALITY_CHECK) first.`
      );
    }

    if (screening.images.length === 0) {
      throw new ValidationError("No retinal images found for this screening.");
    }

    // Resolve or bootstrap active ModelVersion
    let activeModel = await this.modelVersionRepository.getActiveModel();
    if (!activeModel) {
      activeModel = await this.modelVersionRepository.create(
        ModelVersion.create({
          modelName: "efficientnet-b3",
          version: "efficientnet-b3-v1.0.0",
          pipelineVersion: "dr-pipe-v1.2",
          weightsHash: "sha256:8f4e2c9a1d3b7e5f6a0c8b9d2e4f6a8b1c3d5e7f9a0b2c4d6e8f0a2b4c6d8e0f",
          isActive: true,
        })
      );
    }

    // Run inference on the primary image (OD or first available)
    const primaryImage = screening.images.find((img) => img.eye === "OD") || screening.images[0];
    const signedUrl = await this.imageStorage.getSignedUrl(primaryImage.storageKey, 600);

    const startTime = Date.now();
    const aiResponse = await this.aiClient.screen(signedUrl, primaryImage.eye, true);
    const durationMs = Date.now() - startTime;

    if (!aiResponse.prediction || !aiResponse.reliability) {
      throw new Error("AI service returned incomplete inference results.");
    }

    // Create & persist domain AIResult
    const aiResult = AIResult.create({
      screeningId: screening.id,
      modelVersionId: activeModel.id,
      predictedClass: aiResponse.prediction.predictedClass,
      confidence: aiResponse.prediction.confidence,
      rawProbabilities: aiResponse.prediction.rawProbabilities,
      inferenceDurationMs: durationMs,
    });
    const savedAiResult = await this.screeningRepository.saveAIResult(aiResult);

    // Create & persist domain ReliabilityAssessment
    const reliabilityAssessment = ReliabilityAssessment.create({
      screeningId: screening.id,
      status: aiResponse.reliability.status.toUpperCase() as ReliabilityStatus,
      score: aiResponse.reliability.score,
      confidenceThreshold: aiResponse.reliability.confidenceThreshold,
      qualityThreshold: aiResponse.reliability.qualityThreshold,
      reasoning: aiResponse.reliability.reason,
    });
    const savedReliability = await this.screeningRepository.saveReliabilityAssessment(reliabilityAssessment);

    // Advance State Machine
    screening.recordAiInference(savedAiResult, savedReliability);
    const updatedScreening = await this.screeningRepository.update(screening);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "AI_INFERENCE_PERFORMED",
      resource: "AIResult",
      resourceId: savedAiResult.id,
      metadata: {
        screeningId,
        modelVersion: activeModel.version,
        predictedClass: savedAiResult.predictedClass,
        confidence: savedAiResult.confidence,
        reliabilityStatus: savedReliability.status,
        reliabilityScore: savedReliability.score,
        finalScreeningStatus: updatedScreening.status,
      },
    });

    return {
      screening: updatedScreening,
      aiResult: savedAiResult,
      reliability: savedReliability,
    };
  }

  async getAiResult(
    screeningId: string,
    actor: AuthenticatedActor
  ): Promise<{
    aiResult: AIResult | null;
    reliability: ReliabilityAssessment | null;
    modelVersion: ModelVersion | null;
  }> {
    const screening = await this.getScreeningById(screeningId, actor);

    const [aiResult, reliability] = await Promise.all([
      this.screeningRepository.findAIResultByScreeningId(screening.id),
      this.screeningRepository.findReliabilityAssessmentByScreeningId(screening.id),
    ]);

    let modelVersion: ModelVersion | null = null;
    if (aiResult) {
      modelVersion = await this.modelVersionRepository.findById(aiResult.modelVersionId);
    }

    return {
      aiResult,
      reliability,
      modelVersion,
    };
  }

  async getImagePresignedUrl(
    screeningId: string,
    imageId: string,
    actor: AuthenticatedActor
  ): Promise<{ signedUrl: string; expiresInSeconds: number }> {
    const screening = await this.getScreeningById(screeningId, actor);
    const image = await this.screeningRepository.findImageById(imageId);

    if (!image || image.screeningId !== screening.id) {
      throw new NotFoundError("RetinalImage", imageId);
    }

    const expiresInSeconds = 900; // 15 minutes
    const signedUrl = await this.imageStorage.getSignedUrl(image.storageKey, expiresInSeconds);

    return { signedUrl, expiresInSeconds };
  }
}
