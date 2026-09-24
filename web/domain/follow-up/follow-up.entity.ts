export type FollowUpStatus =
  | "SCHEDULED"
  | "REMINDER_SENT"
  | "COMPLETED"
  | "MISSED"
  | "CANCELLED";

export interface FollowUpProps {
  id: string;
  patientId: string;
  screeningId?: string | null;
  dueDate: Date;
  status: FollowUpStatus;
  completionNotes?: string | null;
  completedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export class FollowUp {
  private constructor(private readonly props: FollowUpProps) {}

  public static create(
    props: Omit<FollowUpProps, "id" | "status" | "createdAt" | "updatedAt"> & {
      id?: string;
      status?: FollowUpStatus;
    }
  ): FollowUp {
    if (!props.patientId) throw new Error("Patient ID is required for follow-up.");

    return new FollowUp({
      id: props.id || crypto.randomUUID(),
      patientId: props.patientId,
      screeningId: props.screeningId ?? null,
      dueDate: new Date(props.dueDate),
      status: props.status || "SCHEDULED",
      completionNotes: props.completionNotes ?? null,
      completedAt: props.completedAt ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: FollowUpProps): FollowUp {
    return new FollowUp(props);
  }

  public get id(): string { return this.props.id; }
  public get patientId(): string { return this.props.patientId; }
  public get screeningId(): string | null | undefined { return this.props.screeningId; }
  public get dueDate(): Date { return this.props.dueDate; }
  public get status(): FollowUpStatus { return this.props.status; }
  public get completionNotes(): string | null | undefined { return this.props.completionNotes; }
  public get completedAt(): Date | null | undefined { return this.props.completedAt; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  public complete(notes?: string): void {
    this.props.status = "COMPLETED";
    this.props.completionNotes = notes ?? this.props.completionNotes;
    this.props.completedAt = new Date();
    this.props.updatedAt = new Date();
  }

  public markReminderSent(): void {
    if (this.props.status === "SCHEDULED") {
      this.props.status = "REMINDER_SENT";
      this.props.updatedAt = new Date();
    }
  }

  public toJSON() {
    return {
      id: this.id,
      patientId: this.patientId,
      screeningId: this.screeningId,
      dueDate: this.dueDate.toISOString(),
      status: this.status,
      completionNotes: this.completionNotes,
      completedAt: this.completedAt?.toISOString() ?? null,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
