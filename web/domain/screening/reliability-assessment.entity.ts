export type ReliabilityStatus = "ANALYZE" | "HUMAN_REVIEW" | "RETAKE";

export interface ReliabilityAssessmentProps {
  id: string;
  screeningId: string;
  status: ReliabilityStatus;
  score: number; // Composite reliability score [0.0 - 1.0]
  confidenceThreshold: number;
  qualityThreshold: number;
  reasoning?: string | null;
  assessedAt: Date;
}

export class ReliabilityAssessment {
  private constructor(private readonly props: ReliabilityAssessmentProps) {}

  public static create(
    props: Omit<
      ReliabilityAssessmentProps,
      "id" | "assessedAt" | "confidenceThreshold" | "qualityThreshold"
    > & {
      id?: string;
      confidenceThreshold?: number;
      qualityThreshold?: number;
    }
  ): ReliabilityAssessment {
    if (props.score < 0.0 || props.score > 1.0) {
      throw new Error("Reliability score must be between 0.0 and 1.0.");
    }

    const validStatuses: ReliabilityStatus[] = ["ANALYZE", "HUMAN_REVIEW", "RETAKE"];
    if (!validStatuses.includes(props.status)) {
      throw new Error(`Invalid reliability status: ${props.status}`);
    }

    return new ReliabilityAssessment({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      status: props.status,
      score: props.score,
      confidenceThreshold: props.confidenceThreshold ?? 0.85,
      qualityThreshold: props.qualityThreshold ?? 0.75,
      reasoning: props.reasoning ?? null,
      assessedAt: new Date(),
    });
  }

  public static reconstitute(props: ReliabilityAssessmentProps): ReliabilityAssessment {
    return new ReliabilityAssessment(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get status(): ReliabilityStatus { return this.props.status; }
  public get score(): number { return this.props.score; }
  public get confidenceThreshold(): number { return this.props.confidenceThreshold; }
  public get qualityThreshold(): number { return this.props.qualityThreshold; }
  public get reasoning(): string | null | undefined { return this.props.reasoning; }
  public get assessedAt(): Date { return this.props.assessedAt; }

  public requiresHumanReview(): boolean {
    return this.props.status === "HUMAN_REVIEW";
  }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      status: this.status,
      score: this.score,
      confidenceThreshold: this.confidenceThreshold,
      qualityThreshold: this.qualityThreshold,
      requiresHumanReview: this.requiresHumanReview(),
      reasoning: this.reasoning,
      assessedAt: this.assessedAt.toISOString(),
    };
  }
}
