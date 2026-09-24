export type DRClassification =
  | "NO_DR"
  | "MILD_DR"
  | "MODERATE_DR"
  | "SEVERE_DR"
  | "PROLIFERATIVE_DR";

export interface AIResultProps {
  id: string;
  screeningId: string;
  modelVersionId: string;
  predictedClass: DRClassification;
  confidence: number; // 0.0 - 1.0
  rawProbabilities: Record<string, number>;
  inferenceDurationMs?: number | null;
  inferenceTimestamp: Date;
}

export class AIResult {
  private constructor(private readonly props: AIResultProps) {}

  public static create(
    props: Omit<AIResultProps, "id" | "inferenceTimestamp"> & { id?: string }
  ): AIResult {
    if (props.confidence < 0.0 || props.confidence > 1.0) {
      throw new Error("Confidence must be a value between 0.0 and 1.0.");
    }

    const validClasses: DRClassification[] = [
      "NO_DR",
      "MILD_DR",
      "MODERATE_DR",
      "SEVERE_DR",
      "PROLIFERATIVE_DR",
    ];

    if (!validClasses.includes(props.predictedClass)) {
      throw new Error(`Invalid DR predicted class: ${props.predictedClass}`);
    }

    return new AIResult({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      modelVersionId: props.modelVersionId,
      predictedClass: props.predictedClass,
      confidence: props.confidence,
      rawProbabilities: props.rawProbabilities,
      inferenceDurationMs: props.inferenceDurationMs ?? null,
      inferenceTimestamp: new Date(),
    });
  }

  public static reconstitute(props: AIResultProps): AIResult {
    return new AIResult(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get modelVersionId(): string { return this.props.modelVersionId; }
  public get predictedClass(): DRClassification { return this.props.predictedClass; }
  public get confidence(): number { return this.props.confidence; }
  public get rawProbabilities(): Record<string, number> { return this.props.rawProbabilities; }
  public get inferenceDurationMs(): number | null | undefined { return this.props.inferenceDurationMs; }
  public get inferenceTimestamp(): Date { return this.props.inferenceTimestamp; }

  public isHighRisk(): boolean {
    return this.props.predictedClass === "SEVERE_DR" || this.props.predictedClass === "PROLIFERATIVE_DR";
  }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      modelVersionId: this.modelVersionId,
      predictedClass: this.predictedClass,
      confidence: this.confidence,
      rawProbabilities: this.rawProbabilities,
      isHighRisk: this.isHighRisk(),
      inferenceDurationMs: this.inferenceDurationMs,
      inferenceTimestamp: this.inferenceTimestamp.toISOString(),
    };
  }
}
