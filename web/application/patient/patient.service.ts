import { PatientRepository, PatientSearchParams, PatientSearchResult } from "@/domain/patient/patient.repository";
import { Patient, Gender } from "@/domain/patient/patient.entity";
import { NotFoundError, ConflictError, ForbiddenError, ValidationError } from "@/domain/common/errors";
import { UserRole } from "@/domain/auth/user.entity";

export interface CreatePatientDTO {
  userId?: string | null;
  nik: string;
  fullName: string;
  birthDate: string; // ISO date string
  gender: Gender;
  phone?: string | null;
  address?: string | null;
  emergencyContact?: string | null;
}

export interface UpdatePatientDTO {
  fullName?: string;
  phone?: string | null;
  address?: string | null;
  emergencyContact?: string | null;
}

export class PatientService {
  constructor(private readonly patientRepository: PatientRepository) {}

  async createPatient(
    dto: CreatePatientDTO,
    actor: { id: string; role: UserRole }
  ): Promise<Patient> {
    // Only healthcare workers or admins can register arbitrary patients
    // Patients can only link their own user id
    if (actor.role === "PATIENT" && dto.userId && dto.userId !== actor.id) {
      throw new ForbiddenError("Patients cannot register records for other users.");
    }

    const existingWithNik = await this.patientRepository.findByNik(dto.nik);
    if (existingWithNik) {
      throw new ConflictError(`A patient with NIK ${dto.nik} is already registered in RETIVA.`);
    }

    const birthDate = new Date(dto.birthDate);
    if (isNaN(birthDate.getTime())) {
      throw new ValidationError("Invalid birth date format.");
    }

    const patient = Patient.create({
      userId: dto.userId || (actor.role === "PATIENT" ? actor.id : null),
      nik: dto.nik,
      fullName: dto.fullName,
      birthDate,
      gender: dto.gender,
      phone: dto.phone,
      address: dto.address,
      emergencyContact: dto.emergencyContact,
    });

    return this.patientRepository.create(patient);
  }

  async getPatientById(
    id: string,
    actor: { id: string; role: UserRole }
  ): Promise<Patient> {
    const patient = await this.patientRepository.findById(id);
    if (!patient) {
      throw new NotFoundError("Patient", id);
    }

    // Role-based Access Control: Patient can only access their own record
    if (actor.role === "PATIENT" && patient.userId !== actor.id) {
      throw new ForbiddenError("Patients can only access their own medical records.");
    }

    return patient;
  }

  async getPatientByNik(
    nik: string,
    actor: { id: string; role: UserRole }
  ): Promise<Patient> {
    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Patients cannot query arbitrary NIK records.");
    }

    const patient = await this.patientRepository.findByNik(nik);
    if (!patient) {
      throw new NotFoundError("Patient with NIK", nik);
    }
    return patient;
  }

  async searchPatients(
    params: PatientSearchParams,
    actor: { id: string; role: UserRole }
  ): Promise<PatientSearchResult> {
    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Patients are not authorized to search directory records.");
    }

    return this.patientRepository.search(params);
  }

  async updatePatient(
    id: string,
    dto: UpdatePatientDTO,
    actor: { id: string; role: UserRole }
  ): Promise<Patient> {
    const patient = await this.patientRepository.findById(id);
    if (!patient) {
      throw new NotFoundError("Patient", id);
    }

    if (actor.role === "PATIENT" && patient.userId !== actor.id) {
      throw new ForbiddenError("Patients cannot update other patient records.");
    }

    patient.updateDetails({
      fullName: dto.fullName,
      phone: dto.phone,
      address: dto.address,
      emergencyContact: dto.emergencyContact,
    });

    return this.patientRepository.update(patient);
  }
}
