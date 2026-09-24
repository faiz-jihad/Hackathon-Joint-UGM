import { Patient } from "./patient.entity";

export interface PatientSearchParams {
  query?: string;
  limit?: number;
  offset?: number;
}

export interface PatientSearchResult {
  patients: Patient[];
  total: number;
}

export interface PatientRepository {
  findById(id: string): Promise<Patient | null>;
  findByNik(nik: string): Promise<Patient | null>;
  findByUserId(userId: string): Promise<Patient | null>;
  search(params: PatientSearchParams): Promise<PatientSearchResult>;
  create(patient: Patient): Promise<Patient>;
  update(patient: Patient): Promise<Patient>;
  delete(id: string): Promise<void>;
}
