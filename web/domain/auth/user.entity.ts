export type UserRole = "PATIENT" | "HEALTHCARE_WORKER" | "OPHTHALMOLOGIST" | "ADMIN";

export interface UserProps {
  id: string;
  email: string;
  passwordHash: string;
  role: UserRole;
  fullName: string;
  phoneNumber?: string | null;
  facilityId?: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class User {
  private constructor(private readonly props: UserProps) {}

  public static create(
    props: Omit<UserProps, "id" | "createdAt" | "updatedAt" | "isActive"> & {
      id?: string;
      isActive?: boolean;
    }
  ): User {
    return new User({
      id: props.id || crypto.randomUUID(),
      email: props.email.toLowerCase().trim(),
      passwordHash: props.passwordHash,
      role: props.role,
      fullName: props.fullName.trim(),
      phoneNumber: props.phoneNumber ?? null,
      facilityId: props.facilityId ?? null,
      isActive: props.isActive ?? true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: UserProps): User {
    return new User(props);
  }

  public get id(): string { return this.props.id; }
  public get email(): string { return this.props.email; }
  public get passwordHash(): string { return this.props.passwordHash; }
  public get role(): UserRole { return this.props.role; }
  public get fullName(): string { return this.props.fullName; }
  public get phoneNumber(): string | null | undefined { return this.props.phoneNumber; }
  public get facilityId(): string | null | undefined { return this.props.facilityId; }
  public get isActive(): boolean { return this.props.isActive; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  public toJSON() {
    return {
      id: this.id,
      email: this.email,
      role: this.role,
      fullName: this.fullName,
      phoneNumber: this.phoneNumber,
      facilityId: this.facilityId,
      isActive: this.isActive,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }
}
