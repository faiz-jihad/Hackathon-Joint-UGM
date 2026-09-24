import { UrgencyLevel } from "../recommendation/recommendation.entity";

export type ReferralStatus =
  | "RECOMMENDED"
  | "ISSUED"
  | "ACCEPTED_BY_FACILITY"
  | "PATIENT_ATTENDED"
  | "EXPIRED"
  | "CANCELLED";

export interface ReferralProps {
  id: string;
  screeningId: string;
  patientId: string;
  targetFacilityId: string;
  urgency: UrgencyLevel;
  reason: string;
  clinicalSummary: string;
  status: ReferralStatus;
  issuedAt?: Date | null;
  expiresAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export class Referral {
  private constructor(private readonly props: ReferralProps) {}

  public static create(
    props: Omit<ReferralProps, "id" | "status" | "createdAt" | "updatedAt"> & {
      id?: string;
      status?: ReferralStatus;
    }
  ): Referral {
    if (!props.patientId) throw new Error("Patient ID is required for referral.");
    if (!props.targetFacilityId) throw new Error("Target facility ID is required for referral.");
    if (!props.reason || props.reason.trim().length === 0) {
      throw new Error("Clinical referral reason is required.");
    }

    const issuedAt = props.issuedAt || new Date();
    // Default expiration: 30 days from issuance
    const expiresAt = props.expiresAt || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    return new Referral({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      patientId: props.patientId,
      targetFacilityId: props.targetFacilityId,
      urgency: props.urgency || "MEDIUM",
      reason: props.reason.trim(),
      clinicalSummary: props.clinicalSummary.trim(),
      status: props.status || "RECOMMENDED",
      issuedAt,
      expiresAt,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: ReferralProps): Referral {
    return new Referral(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get patientId(): string { return this.props.patientId; }
  public get targetFacilityId(): string { return this.props.targetFacilityId; }
  public get urgency(): UrgencyLevel { return this.props.urgency; }
  public get reason(): string { return this.props.reason; }
  public get clinicalSummary(): string { return this.props.clinicalSummary; }
  public get status(): ReferralStatus { return this.props.status; }
  public get issuedAt(): Date | null | undefined { return this.props.issuedAt; }
  public get expiresAt(): Date | null | undefined { return this.props.expiresAt; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  public issue(): void {
    this.props.status = "ISSUED";
    this.props.issuedAt = new Date();
    this.props.updatedAt = new Date();
  }

  public markAttended(): void {
    this.props.status = "PATIENT_ATTENDED";
    this.props.updatedAt = new Date();
  }

  public cancel(reason?: string): void {
    this.props.status = "CANCELLED";
    this.props.updatedAt = new Date();
  }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      patientId: this.patientId,
      targetFacilityId: this.targetFacilityId,
      urgency: this.urgency,
      reason: this.reason,
      clinicalSummary: this.clinicalSummary,
      status: this.status,
      issuedAt: this.issuedAt?.toISOString() ?? null,
      expiresAt: this.expiresAt?.toISOString() ?? null,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
