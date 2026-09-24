export type Gender = "MALE" | "FEMALE";

export interface PatientProps {
  id: string;
  userId?: string | null;
  nik: string; // 16 digit Indonesian ID
  fullName: string;
  birthDate: Date;
  gender: Gender;
  phone?: string | null;
  address?: string | null;
  emergencyContact?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export class Patient {
  private constructor(private readonly props: PatientProps) {}

  public static create(props: Omit<PatientProps, "id" | "createdAt" | "updatedAt"> & { id?: string }): Patient {
    if (!props.nik || props.nik.trim().length !== 16 || !/^\d{16}$/.test(props.nik.trim())) {
      throw new Error("NIK must be a valid 16-digit numeric string.");
    }

    if (!props.fullName || props.fullName.trim().length < 2) {
      throw new Error("Full name must be at least 2 characters.");
    }

    return new Patient({
      id: props.id || crypto.randomUUID(),
      userId: props.userId ?? null,
      nik: props.nik.trim(),
      fullName: props.fullName.trim(),
      birthDate: new Date(props.birthDate),
      gender: props.gender,
      phone: props.phone ?? null,
      address: props.address ?? null,
      emergencyContact: props.emergencyContact ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: PatientProps): Patient {
    return new Patient(props);
  }

  public get id(): string { return this.props.id; }
  public get userId(): string | null | undefined { return this.props.userId; }
  public get nik(): string { return this.props.nik; }
  public get fullName(): string { return this.props.fullName; }
  public get birthDate(): Date { return this.props.birthDate; }
  public get gender(): Gender { return this.props.gender; }
  public get phone(): string | null | undefined { return this.props.phone; }
  public get address(): string | null | undefined { return this.props.address; }
  public get emergencyContact(): string | null | undefined { return this.props.emergencyContact; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  public getAge(): number {
    const today = new Date();
    const birth = new Date(this.props.birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  public updateDetails(updates: {
    fullName?: string;
    phone?: string | null;
    address?: string | null;
    emergencyContact?: string | null;
  }): void {
    if (updates.fullName !== undefined) {
      if (updates.fullName.trim().length < 2) throw new Error("Full name must be at least 2 characters.");
      this.props.fullName = updates.fullName.trim();
    }
    if (updates.phone !== undefined) this.props.phone = updates.phone;
    if (updates.address !== undefined) this.props.address = updates.address;
    if (updates.emergencyContact !== undefined) this.props.emergencyContact = updates.emergencyContact;
    this.props.updatedAt = new Date();
  }

  public toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      nik: this.nik,
      fullName: this.fullName,
      birthDate: this.birthDate.toISOString(),
      age: this.getAge(),
      gender: this.gender,
      phone: this.phone,
      address: this.address,
      emergencyContact: this.emergencyContact,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
