import { Referral, ReferralStatus } from "./referral.entity";

export interface ReferralSearchParams {
  patientId?: string;
  targetFacilityId?: string;
  status?: ReferralStatus;
  limit?: number;
  offset?: number;
}

export interface ReferralRepository {
  findById(id: string): Promise<Referral | null>;
  findByScreeningId(screeningId: string): Promise<Referral | null>;
  findByPatientId(patientId: string): Promise<Referral[]>;
  search(params: ReferralSearchParams): Promise<{ referrals: Referral[]; total: number }>;
  create(referral: Referral): Promise<Referral>;
  update(referral: Referral): Promise<Referral>;
}
