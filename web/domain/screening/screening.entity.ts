import { RetinalImage } from "./retinal-image.entity";
import { QualityCheck } from "./quality-check.entity";
import { AIResult } from "./ai-result.entity";
import { ReliabilityAssessment } from "./reliability-assessment.entity";

export type ScreeningStatus =
  | "CREATED"
  | "IMAGE_UPLOADED"
  | "QUALITY_CHECK"
  | "RETAKE_REQUIRED"
  | "AI_ANALYZED"
  | "HUMAN_REVIEW"
  | "SCREENING_COMPLETED"
  | "FOLLOW_UP_REQUIRED"
  | "REFERRAL_RECOMMENDED"
  | "FOLLOW_UP_COMPLETED";

export interface ScreeningProps {
  id: string;
  patientId: string;
  conductedById: string;
  facilityId?: string | null;
  status: ScreeningStatus;
  notes?: string | null;
  metadata?: Record<string, any> | null;
  createdAt: Date;
  updatedAt: Date;

  // Domain aggregates
  images?: RetinalImage[];
  qualityChecks?: Map<string, QualityCheck>; // keyed by retinalImageId
  aiResult?: AIResult | null;
  reliabilityAssessment?: ReliabilityAssessment | null;
}

export class Screening {
  private readonly _images: RetinalImage[] = [];
  private readonly _qualityChecks: Map<string, QualityCheck> = new Map();

  private _aiResult?: AIResult | null;
  private _reliabilityAssessment?: ReliabilityAssessment | null;

  private constructor(private readonly props: ScreeningProps) {
    if (props.images) {
      this._images = [...props.images];
    }
    if (props.qualityChecks) {
      this._qualityChecks = new Map(props.qualityChecks);
    }
    this._aiResult = props.aiResult ?? null;
    this._reliabilityAssessment = props.reliabilityAssessment ?? null;
  }

  public static create(
    props: Omit<ScreeningProps, "id" | "status" | "createdAt" | "updatedAt"> & { id?: string }
  ): Screening {
    return new Screening({
      id: props.id || crypto.randomUUID(),
      patientId: props.patientId,
      conductedById: props.conductedById,
      facilityId: props.facilityId ?? null,
      status: "CREATED",
      notes: props.notes ?? null,
      metadata: props.metadata ?? {},
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(
    props: ScreeningProps,
    images: RetinalImage[] = [],
    qualityChecks: QualityCheck[] = [],
    aiResult: AIResult | null = null,
    reliabilityAssessment: ReliabilityAssessment | null = null
  ): Screening {
    const qMap = new Map<string, QualityCheck>();
    for (const qc of qualityChecks) {
      qMap.set(qc.retinalImageId, qc);
    }
    return new Screening({
      ...props,
      images,
      qualityChecks: qMap,
      aiResult,
      reliabilityAssessment,
    });
  }

  public get id(): string { return this.props.id; }
  public get patientId(): string { return this.props.patientId; }
  public get conductedById(): string { return this.props.conductedById; }
  public get facilityId(): string | null | undefined { return this.props.facilityId; }
  public get status(): ScreeningStatus { return this.props.status; }
  public get notes(): string | null | undefined { return this.props.notes; }
  public get metadata(): Record<string, any> | null | undefined { return this.props.metadata; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }
  public get images(): ReadonlyArray<RetinalImage> { return this._images; }
  public get qualityChecks(): ReadonlyMap<string, QualityCheck> { return this._qualityChecks; }
  public get aiResult(): AIResult | null | undefined { return this._aiResult; }
  public get reliabilityAssessment(): ReliabilityAssessment | null | undefined { return this._reliabilityAssessment; }

  /**
   * State Machine: Add an image to the screening session
   */
  public addImage(image: RetinalImage): void {
    if (this.props.status === "SCREENING_COMPLETED" || this.props.status === "FOLLOW_UP_COMPLETED") {
      throw new Error(`Cannot add images to a finalized screening in status: ${this.props.status}`);
    }

    // Replace if same eye already exists, or append
    const existingIndex = this._images.findIndex((img) => img.eye === image.eye);
    if (existingIndex >= 0) {
      const oldImage = this._images[existingIndex];
      this._qualityChecks.delete(oldImage.id);
      this._images[existingIndex] = image;
    } else {
      this._images.push(image);
    }

    this.props.status = "IMAGE_UPLOADED";
    this.props.updatedAt = new Date();
  }

  /**
   * State Machine: Record a quality check result for an image
   */
  public recordQualityCheck(check: QualityCheck): void {
    this._qualityChecks.set(check.retinalImageId, check);

    // Evaluate entire screening quality gate on active images
    const currentImageIds = new Set(this._images.map((img) => img.id));
    let anyFailed = false;
    let checkedCount = 0;

    for (const [imgId, qc] of this._qualityChecks.entries()) {
      if (currentImageIds.has(imgId)) {
        checkedCount++;
        if (!qc.passed) {
          anyFailed = true;
          break;
        }
      }
    }

    if (anyFailed) {
      this.props.status = "RETAKE_REQUIRED";
    } else if (this._images.length > 0 && checkedCount >= this._images.length) {
      // All uploaded images have passed the Quality Gate
      this.props.status = "QUALITY_CHECK";
    }

    this.props.updatedAt = new Date();
  }

  /**
   * State Machine: Record AI inference result & Reliability Gate evaluation
   */
  public recordAiInference(aiResult: AIResult, reliability: ReliabilityAssessment): void {
    if (this.props.status !== "QUALITY_CHECK") {
      throw new Error(
        `Cannot perform AI inference on screening in status '${this.props.status}'. Quality check must pass first.`
      );
    }

    this._aiResult = aiResult;
    this._reliabilityAssessment = reliability;

    // Reliability Gate decisions:
    if (reliability.status === "HUMAN_REVIEW") {
      this.props.status = "HUMAN_REVIEW";
      this.props.metadata = {
        ...this.props.metadata,
        reliabilityStatus: "HUMAN_REVIEW",
        reliabilityScore: reliability.score,
        reliabilityReason: reliability.reasoning,
      };
    } else if (reliability.status === "RETAKE") {
      this.props.status = "RETAKE_REQUIRED";
      this.props.metadata = {
        ...this.props.metadata,
        reliabilityStatus: "RETAKE",
        reliabilityReason: reliability.reasoning,
      };
    } else {
      // High reliability -> AI_ANALYZED
      this.props.status = "AI_ANALYZED";
      this.props.metadata = {
        ...this.props.metadata,
        reliabilityStatus: "ANALYZE",
        reliabilityScore: reliability.score,
      };
    }

    this.props.updatedAt = new Date();
  }

  /**
   * State Machine: Advance to AI_ANALYZED
   */
  public markAiAnalyzed(): void {
    if (this.props.status !== "QUALITY_CHECK") {
      throw new Error(
        `Cannot advance to AI_ANALYZED from status '${this.props.status}'. Quality check must pass first.`
      );
    }
    this.props.status = "AI_ANALYZED";
    this.props.updatedAt = new Date();
  }

  /**
   * State Machine: Escalate to HUMAN_REVIEW
   */
  public markHumanReviewRequired(reason?: string): void {
    this.props.status = "HUMAN_REVIEW";
    if (reason) {
      this.props.metadata = { ...this.props.metadata, humanReviewReason: reason };
    }
    this.props.updatedAt = new Date();
  }

  /**
   * State Machine: Finalize screening as SCREENING_COMPLETED
   */
  public completeScreening(): void {
    if (this.props.status !== "AI_ANALYZED" && this.props.status !== "HUMAN_REVIEW") {
      throw new Error(
        `Cannot complete screening from status '${this.props.status}'. Must be AI_ANALYZED or HUMAN_REVIEW.`
      );
    }
    this.props.status = "SCREENING_COMPLETED";
    this.props.updatedAt = new Date();
  }

  public toJSON() {
    return {
      id: this.id,
      patientId: this.patientId,
      conductedById: this.conductedById,
      facilityId: this.facilityId,
      status: this.status,
      notes: this.notes,
      metadata: this.metadata,
      images: this._images.map((img) => img.toJSON()),
      qualityChecks: Array.from(this._qualityChecks.values()).map((qc) => qc.toJSON()),
      aiResult: this._aiResult ? this._aiResult.toJSON() : null,
      reliabilityAssessment: this._reliabilityAssessment ? this._reliabilityAssessment.toJSON() : null,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
