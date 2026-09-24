export type RecommendedAction =
  | "ROUTINE_ANNUAL_SCREENING"
  | "FOLLOW_UP_6_MONTHS"
  | "FOLLOW_UP_3_MONTHS"
  | "SPECIALIST_OPHTHALMOLOGY_REFERRAL"
  | "URGENT_SURGICAL_CONSULTATION"
  | "IMAGE_RETAKE";

export type UrgencyLevel = "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";

export interface RecommendationProps {
  id: string;
  screeningId: string;
  summary: string;
  recommendedAction: RecommendedAction;
  urgencyLevel: UrgencyLevel;
  referralIndicated: boolean;
  clinicalGuideline?: string | null;
  generatedAt: Date;
}

export class Recommendation {
  private constructor(private readonly props: RecommendationProps) {}

  public static create(
    props: Omit<RecommendationProps, "id" | "generatedAt"> & { id?: string }
  ): Recommendation {
    if (!props.summary || props.summary.trim().length === 0) {
      throw new Error("Recommendation clinical summary is required.");
    }

    return new Recommendation({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      summary: props.summary.trim(),
      recommendedAction: props.recommendedAction,
      urgencyLevel: props.urgencyLevel,
      referralIndicated: props.referralIndicated,
      clinicalGuideline: props.clinicalGuideline ?? "Konsensus Nasional Pengelolaan Retinopati Diabetika Perdami / ADA 2024",
      generatedAt: new Date(),
    });
  }

  public static reconstitute(props: RecommendationProps): Recommendation {
    return new Recommendation(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get summary(): string { return this.props.summary; }
  public get recommendedAction(): RecommendedAction { return this.props.recommendedAction; }
  public get urgencyLevel(): UrgencyLevel { return this.props.urgencyLevel; }
  public get referralIndicated(): boolean { return this.props.referralIndicated; }
  public get clinicalGuideline(): string | null | undefined { return this.props.clinicalGuideline; }
  public get generatedAt(): Date { return this.props.generatedAt; }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      summary: this.summary,
      recommendedAction: this.recommendedAction,
      urgencyLevel: this.urgencyLevel,
      referralIndicated: this.referralIndicated,
      clinicalGuideline: this.clinicalGuideline,
      generatedAt: this.generatedAt.toISOString(),
    };
  }
}
