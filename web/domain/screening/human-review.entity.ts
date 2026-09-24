import { DRClassification } from "./ai-result.entity";

export type HumanReviewStatus = "PENDING" | "CONFIRMED_AI" | "OVERRIDDEN";

export interface HumanReviewProps {
  id: string;
  screeningId: string;
  reviewerId: string;
  reviewStatus: HumanReviewStatus;
  confirmedClass: DRClassification;
  clinicalNotes?: string | null;
  reviewedAt: Date;
}

export class HumanReview {
  private constructor(private readonly props: HumanReviewProps) {}

  public static create(
    props: Omit<HumanReviewProps, "id" | "reviewedAt"> & { id?: string }
  ): HumanReview {
    if (!props.reviewerId) {
      throw new Error("Reviewer ID (Ophthalmologist) is required.");
    }
    if (!props.confirmedClass) {
      throw new Error("Confirmed DR clinical class is required.");
    }

    return new HumanReview({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      reviewerId: props.reviewerId,
      reviewStatus: props.reviewStatus || "CONFIRMED_AI",
      confirmedClass: props.confirmedClass,
      clinicalNotes: props.clinicalNotes ?? null,
      reviewedAt: new Date(),
    });
  }

  public static reconstitute(props: HumanReviewProps): HumanReview {
    return new HumanReview(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get reviewerId(): string { return this.props.reviewerId; }
  public get reviewStatus(): HumanReviewStatus { return this.props.reviewStatus; }
  public get confirmedClass(): DRClassification { return this.props.confirmedClass; }
  public get clinicalNotes(): string | null | undefined { return this.props.clinicalNotes; }
  public get reviewedAt(): Date { return this.props.reviewedAt; }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      reviewerId: this.reviewerId,
      reviewStatus: this.reviewStatus,
      confirmedClass: this.confirmedClass,
      clinicalNotes: this.clinicalNotes,
      reviewedAt: this.reviewedAt.toISOString(),
    };
  }
}
