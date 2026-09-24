import { Facility, BPJSStatus } from "./facility.entity";

export interface FacilitySearchParams {
  query?: string;
  bpjsStatus?: BPJSStatus;
  hasService?: string;
  isVerified?: boolean;
  limit?: number;
  offset?: number;
}

export interface FacilityRepository {
  findById(id: string): Promise<Facility | null>;
  search(params: FacilitySearchParams): Promise<{ facilities: Facility[]; total: number }>;
  listAll(): Promise<Facility[]>;
  create(facility: Facility): Promise<Facility>;
}
