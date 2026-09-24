export type DiabetesType = "TYPE_1" | "TYPE_2" | "GESTATIONAL" | "UNKNOWN";
export type TreatmentType = "INSULIN" | "ORAL_MEDICATION" | "DIET_AND_LIFESTYLE" | "COMBINATION" | "NONE" | "UNKNOWN";

export interface DiabetesProfileProps {
  id: string;
  patientId: string;
  diabetesType: DiabetesType;
  yearOfDiagnosis?: number | null;
  currentTreatment: TreatmentType;
  lastHbA1c?: number | null;
  lastHbA1cDate?: Date | null;
  systolicBp?: number | null;
  diastolicBp?: number | null;
  isSmoker: boolean;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export class DiabetesProfile {
  private constructor(private readonly props: DiabetesProfileProps) {}

  public static create(
    props: Omit<DiabetesProfileProps, "id" | "createdAt" | "updatedAt" | "isSmoker"> & {
      id?: string;
      isSmoker?: boolean;
    }
  ): DiabetesProfile {
    if (props.yearOfDiagnosis) {
      const currentYear = new Date().getFullYear();
      if (props.yearOfDiagnosis < 1920 || props.yearOfDiagnosis > currentYear) {
        throw new Error(`Year of diagnosis must be between 1920 and ${currentYear}.`);
      }
    }

    if (props.lastHbA1c !== undefined && props.lastHbA1c !== null) {
      if (props.lastHbA1c < 3.0 || props.lastHbA1c > 25.0) {
        throw new Error("HbA1c value must be a clinically plausible percentage (between 3.0% and 25.0%).");
      }
    }

    return new DiabetesProfile({
      id: props.id || crypto.randomUUID(),
      patientId: props.patientId,
      diabetesType: props.diabetesType,
      yearOfDiagnosis: props.yearOfDiagnosis ?? null,
      currentTreatment: props.currentTreatment,
      lastHbA1c: props.lastHbA1c ?? null,
      lastHbA1cDate: props.lastHbA1cDate ? new Date(props.lastHbA1cDate) : null,
      systolicBp: props.systolicBp ?? null,
      diastolicBp: props.diastolicBp ?? null,
      isSmoker: props.isSmoker ?? false,
      notes: props.notes ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: DiabetesProfileProps): DiabetesProfile {
    return new DiabetesProfile(props);
  }

  public get id(): string { return this.props.id; }
  public get patientId(): string { return this.props.patientId; }
  public get diabetesType(): DiabetesType { return this.props.diabetesType; }
  public get yearOfDiagnosis(): number | null | undefined { return this.props.yearOfDiagnosis; }
  public get currentTreatment(): TreatmentType { return this.props.currentTreatment; }
  public get lastHbA1c(): number | null | undefined { return this.props.lastHbA1c; }
  public get lastHbA1cDate(): Date | null | undefined { return this.props.lastHbA1cDate; }
  public get systolicBp(): number | null | undefined { return this.props.systolicBp; }
  public get diastolicBp(): number | null | undefined { return this.props.diastolicBp; }
  public get isSmoker(): boolean { return this.props.isSmoker; }
  public get notes(): string | null | undefined { return this.props.notes; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  public getDiabetesDurationYears(): number | null {
    if (!this.props.yearOfDiagnosis) return null;
    return new Date().getFullYear() - this.props.yearOfDiagnosis;
  }

  public getGlycaemicControlStatus(): "OPTIMAL" | "SUBOPTIMAL" | "POOR" | "UNKNOWN" {
    if (this.props.lastHbA1c === null || this.props.lastHbA1c === undefined) return "UNKNOWN";
    if (this.props.lastHbA1c < 7.0) return "OPTIMAL";
    if (this.props.lastHbA1c <= 8.5) return "SUBOPTIMAL";
    return "POOR";
  }

  public update(updates: Partial<Omit<DiabetesProfileProps, "id" | "patientId" | "createdAt" | "updatedAt">>): void {
    if (updates.yearOfDiagnosis !== undefined) {
      if (updates.yearOfDiagnosis) {
        const currentYear = new Date().getFullYear();
        if (updates.yearOfDiagnosis < 1920 || updates.yearOfDiagnosis > currentYear) {
          throw new Error(`Year of diagnosis must be between 1920 and ${currentYear}.`);
        }
      }
      this.props.yearOfDiagnosis = updates.yearOfDiagnosis;
    }

    if (updates.diabetesType !== undefined) this.props.diabetesType = updates.diabetesType;
    if (updates.currentTreatment !== undefined) this.props.currentTreatment = updates.currentTreatment;
    if (updates.lastHbA1c !== undefined) this.props.lastHbA1c = updates.lastHbA1c;
    if (updates.lastHbA1cDate !== undefined) this.props.lastHbA1cDate = updates.lastHbA1cDate ? new Date(updates.lastHbA1cDate) : null;
    if (updates.systolicBp !== undefined) this.props.systolicBp = updates.systolicBp;
    if (updates.diastolicBp !== undefined) this.props.diastolicBp = updates.diastolicBp;
    if (updates.isSmoker !== undefined) this.props.isSmoker = updates.isSmoker;
    if (updates.notes !== undefined) this.props.notes = updates.notes;

    this.props.updatedAt = new Date();
  }

  public toJSON() {
    return {
      id: this.id,
      patientId: this.patientId,
      diabetesType: this.diabetesType,
      yearOfDiagnosis: this.yearOfDiagnosis,
      diabetesDurationYears: this.getDiabetesDurationYears(),
      currentTreatment: this.currentTreatment,
      lastHbA1c: this.lastHbA1c,
      lastHbA1cDate: this.lastHbA1cDate?.toISOString() ?? null,
      glycaemicControlStatus: this.getGlycaemicControlStatus(),
      systolicBp: this.systolicBp,
      diastolicBp: this.diastolicBp,
      isSmoker: this.isSmoker,
      notes: this.notes,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
