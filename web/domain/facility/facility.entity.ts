export type BPJSStatus = "ACCEPTED" | "NOT_AVAILABLE" | "NEEDS_CONFIRMATION";

export interface FacilityServiceInfo {
  id?: string;
  serviceName: string;
  description?: string | null;
}

export interface FacilityInsuranceInfo {
  id?: string;
  insuranceName: string;
  status: string;
}

export interface FacilityProps {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  bpjsStatus: BPJSStatus;
  isVerified: boolean;
  contactPhone?: string | null;
  services?: FacilityServiceInfo[];
  insurances?: FacilityInsuranceInfo[];
  createdAt: Date;
  updatedAt: Date;
}

export class Facility {
  private constructor(private readonly props: FacilityProps) {}

  public static create(
    props: Omit<FacilityProps, "id" | "createdAt" | "updatedAt"> & { id?: string }
  ): Facility {
    if (!props.name || props.name.trim().length === 0) {
      throw new Error("Facility name is required.");
    }
    if (!props.address || props.address.trim().length === 0) {
      throw new Error("Facility address is required.");
    }

    return new Facility({
      id: props.id || crypto.randomUUID(),
      name: props.name.trim(),
      address: props.address.trim(),
      latitude: props.latitude,
      longitude: props.longitude,
      bpjsStatus: props.bpjsStatus || "NEEDS_CONFIRMATION",
      isVerified: props.isVerified ?? false,
      contactPhone: props.contactPhone ?? null,
      services: props.services || [],
      insurances: props.insurances || [],
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static reconstitute(props: FacilityProps): Facility {
    return new Facility(props);
  }

  public get id(): string { return this.props.id; }
  public get name(): string { return this.props.name; }
  public get address(): string { return this.props.address; }
  public get latitude(): number { return this.props.latitude; }
  public get longitude(): number { return this.props.longitude; }
  public get bpjsStatus(): BPJSStatus { return this.props.bpjsStatus; }
  public get isVerified(): boolean { return this.props.isVerified; }
  public get contactPhone(): string | null | undefined { return this.props.contactPhone; }
  public get services(): ReadonlyArray<FacilityServiceInfo> { return this.props.services || []; }
  public get insurances(): ReadonlyArray<FacilityInsuranceInfo> { return this.props.insurances || []; }
  public get createdAt(): Date { return this.props.createdAt; }
  public get updatedAt(): Date { return this.props.updatedAt; }

  /**
   * Calculates geodesic distance to coordinate using Haversine formula (km)
   */
  public calculateDistanceKm(targetLat: number, targetLng: number): number {
    const toRad = (value: number) => (value * Math.PI) / 180;
    const R = 6371; // Earth radius in kilometers

    const dLat = toRad(targetLat - this.props.latitude);
    const dLng = toRad(targetLng - this.props.longitude);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(this.props.latitude)) *
        Math.cos(toRad(targetLat)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(R * c * 10) / 10;
  }

  public hasService(serviceName: string): boolean {
    return (this.props.services || []).some(
      (s) => s.serviceName.toLowerCase() === serviceName.toLowerCase()
    );
  }

  public toJSON() {
    return {
      id: this.id,
      name: this.name,
      address: this.address,
      latitude: this.latitude,
      longitude: this.longitude,
      bpjsStatus: this.bpjsStatus,
      isVerified: this.isVerified,
      contactPhone: this.contactPhone,
      services: this.services,
      insurances: this.insurances,
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
    };
  }
}
