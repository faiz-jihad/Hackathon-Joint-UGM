import { DiabetesProfile } from "./diabetes-profile.entity";

export interface DiabetesProfileRepository {
  findByPatientId(patientId: string): Promise<DiabetesProfile | null>;
  create(profile: DiabetesProfile): Promise<DiabetesProfile>;
  update(profile: DiabetesProfile): Promise<DiabetesProfile>;
  upsert(profile: DiabetesProfile): Promise<DiabetesProfile>;
  deleteByPatientId(patientId: string): Promise<void>;
}
