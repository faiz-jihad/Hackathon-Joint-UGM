import { DiabetesProfileRepository } from "@/domain/patient/diabetes-profile.repository";
import { PatientRepository } from "@/domain/patient/patient.repository";
import { DiabetesProfile, DiabetesType, TreatmentType } from "@/domain/patient/diabetes-profile.entity";
import { NotFoundError, ForbiddenError } from "@/domain/common/errors";
import { UserRole } from "@/domain/auth/user.entity";

export interface UpsertDiabetesProfileDTO {
  diabetesType: DiabetesType;
  yearOfDiagnosis?: number | null;
  currentTreatment: TreatmentType;
  lastHbA1c?: number | null;
  lastHbA1cDate?: string | null; // ISO Date string
  systolicBp?: number | null;
  diastolicBp?: number | null;
  isSmoker: boolean;
  notes?: string | null;
}

export class DiabetesProfileService {
  constructor(
    private readonly diabetesProfileRepository: DiabetesProfileRepository,
    private readonly patientRepository: PatientRepository
  ) {}

  async getProfileByPatientId(
    patientId: string,
    actor: { id: string; role: UserRole }
  ): Promise<DiabetesProfile | null> {
    const patient = await this.patientRepository.findById(patientId);
    if (!patient) {
      throw new NotFoundError("Patient", patientId);
    }

    if (actor.role === "PATIENT" && patient.userId !== actor.id) {
      throw new ForbiddenError("Patients can only view their own diabetes profile.");
    }

    return this.diabetesProfileRepository.findByPatientId(patientId);
  }

  async upsertProfile(
    patientId: string,
    dto: UpsertDiabetesProfileDTO,
    actor: { id: string; role: UserRole }
  ): Promise<DiabetesProfile> {
    const patient = await this.patientRepository.findById(patientId);
    if (!patient) {
      throw new NotFoundError("Patient", patientId);
    }

    // Only healthcare workers or admins can update clinical diabetes parameters
    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Only healthcare workers can record or update clinical diabetes profiles.");
    }

    const existing = await this.diabetesProfileRepository.findByPatientId(patientId);

    if (existing) {
      existing.update({
        diabetesType: dto.diabetesType,
        yearOfDiagnosis: dto.yearOfDiagnosis,
        currentTreatment: dto.currentTreatment,
        lastHbA1c: dto.lastHbA1c,
        lastHbA1cDate: dto.lastHbA1cDate ? new Date(dto.lastHbA1cDate) : null,
        systolicBp: dto.systolicBp,
        diastolicBp: dto.diastolicBp,
        isSmoker: dto.isSmoker,
        notes: dto.notes,
      });
      return this.diabetesProfileRepository.update(existing);
    }

    const profile = DiabetesProfile.create({
      patientId,
      diabetesType: dto.diabetesType,
      yearOfDiagnosis: dto.yearOfDiagnosis,
      currentTreatment: dto.currentTreatment,
      lastHbA1c: dto.lastHbA1c,
      lastHbA1cDate: dto.lastHbA1cDate ? new Date(dto.lastHbA1cDate) : null,
      systolicBp: dto.systolicBp,
      diastolicBp: dto.diastolicBp,
      isSmoker: dto.isSmoker,
      notes: dto.notes,
    });

    return this.diabetesProfileRepository.create(profile);
  }
}
