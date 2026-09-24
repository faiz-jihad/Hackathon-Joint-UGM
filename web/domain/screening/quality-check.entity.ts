export type QualityRetakeReason =
  | "BLURRY"
  | "TOO_DARK"
  | "TOO_BRIGHT"
  | "INSUFFICIENT_FOV"
  | "CATARACT_OPACITY"
  | "OTHER";

export interface QualityCheckProps {
  id: string;
  retinalImageId: string;
  passed: boolean;
  overallScore: number;
  blurScore?: number | null;
  illuminationScore?: number | null;
  fovScore?: number | null;
  retakeReason?: QualityRetakeReason | null;
  retakeInstructions?: string | null;
  checkedAt: Date;
}

export class QualityCheck {
  private constructor(private readonly props: QualityCheckProps) {}

  public static create(
    props: Omit<QualityCheckProps, "id" | "checkedAt"> & { id?: string }
  ): QualityCheck {
    if (props.overallScore < 0.0 || props.overallScore > 1.0) {
      throw new Error("Overall quality score must be between 0.0 and 1.0.");
    }

    if (!props.passed && !props.retakeReason) {
      throw new Error("A retake reason is mandatory when quality check fails.");
    }

    return new QualityCheck({
      id: props.id || crypto.randomUUID(),
      retinalImageId: props.retinalImageId,
      passed: props.passed,
      overallScore: props.overallScore,
      blurScore: props.blurScore ?? null,
      illuminationScore: props.illuminationScore ?? null,
      fovScore: props.fovScore ?? null,
      retakeReason: props.retakeReason ?? null,
      retakeInstructions: props.retakeInstructions ?? null,
      checkedAt: new Date(),
    });
  }

  public static reconstitute(props: QualityCheckProps): QualityCheck {
    return new QualityCheck(props);
  }

  public get id(): string { return this.props.id; }
  public get retinalImageId(): string { return this.props.retinalImageId; }
  public get passed(): boolean { return this.props.passed; }
  public get overallScore(): number { return this.props.overallScore; }
  public get blurScore(): number | null | undefined { return this.props.blurScore; }
  public get illuminationScore(): number | null | undefined { return this.props.illuminationScore; }
  public get fovScore(): number | null | undefined { return this.props.fovScore; }
  public get retakeReason(): QualityRetakeReason | null | undefined { return this.props.retakeReason; }
  public get retakeInstructions(): string | null | undefined { return this.props.retakeInstructions; }
  public get checkedAt(): Date { return this.props.checkedAt; }

  public toJSON() {
    return {
      id: this.id,
      retinalImageId: this.retinalImageId,
      passed: this.passed,
      overallScore: this.overallScore,
      blurScore: this.blurScore,
      illuminationScore: this.illuminationScore,
      fovScore: this.fovScore,
      retakeReason: this.retakeReason,
      retakeInstructions: this.retakeInstructions,
      checkedAt: this.checkedAt.toISOString(),
    };
  }
}
