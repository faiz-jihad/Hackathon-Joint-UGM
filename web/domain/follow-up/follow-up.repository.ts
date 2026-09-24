import { FollowUp, FollowUpStatus } from "./follow-up.entity";

export interface FollowUpSearchParams {
  patientId?: string;
  status?: FollowUpStatus;
  dueBefore?: Date;
  limit?: number;
  offset?: number;
}

export interface FollowUpRepository {
  findById(id: string): Promise<FollowUp | null>;
  findByPatientId(patientId: string): Promise<FollowUp[]>;
  findByScreeningId(screeningId: string): Promise<FollowUp | null>;
  search(params: FollowUpSearchParams): Promise<{ followUps: FollowUp[]; total: number }>;
  create(followUp: FollowUp): Promise<FollowUp>;
  update(followUp: FollowUp): Promise<FollowUp>;
}
