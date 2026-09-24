import { DiabetesProfileRepository } from "@/domain/patient/diabetes-profile.repository";
import { DiabetesProfile, DiabetesType, TreatmentType } from "@/domain/patient/diabetes-profile.entity";
import { prisma } from "../prisma/client";

export class PrismaDiabetesProfileRepository implements DiabetesProfileRepository {
  async findByPatientId(patientId: string): Promise<DiabetesProfile | null> {
    const record = await prisma.diabetesProfile.findUnique({
      where: { patientId },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async create(profile: DiabetesProfile): Promise<DiabetesProfile> {
    const record = await prisma.diabetesProfile.create({
      data: {
        id: profile.id,
        patientId: profile.patientId,
        diabetesType: profile.diabetesType,
        yearOfDiagnosis: profile.yearOfDiagnosis,
        currentTreatment: profile.currentTreatment,
        lastHbA1c: profile.lastHbA1c,
        lastHbA1cDate: profile.lastHbA1cDate,
        systolicBp: profile.systolicBp,
        diastolicBp: profile.diastolicBp,
        isSmoker: profile.isSmoker,
        notes: profile.notes,
      },
    });
    return this.toDomain(record);
  }

  async update(profile: DiabetesProfile): Promise<DiabetesProfile> {
    const record = await prisma.diabetesProfile.update({
      where: { patientId: profile.patientId },
      data: {
        diabetesType: profile.diabetesType,
        yearOfDiagnosis: profile.yearOfDiagnosis,
        currentTreatment: profile.currentTreatment,
        lastHbA1c: profile.lastHbA1c,
        lastHbA1cDate: profile.lastHbA1cDate,
        systolicBp: profile.systolicBp,
        diastolicBp: profile.diastolicBp,
        isSmoker: profile.isSmoker,
        notes: profile.notes,
      },
    });
    return this.toDomain(record);
  }

  async upsert(profile: DiabetesProfile): Promise<DiabetesProfile> {
    const record = await prisma.diabetesProfile.upsert({
      where: { patientId: profile.patientId },
      create: {
        id: profile.id,
        patientId: profile.patientId,
        diabetesType: profile.diabetesType,
        yearOfDiagnosis: profile.yearOfDiagnosis,
        currentTreatment: profile.currentTreatment,
        lastHbA1c: profile.lastHbA1c,
        lastHbA1cDate: profile.lastHbA1cDate,
        systolicBp: profile.systolicBp,
        diastolicBp: profile.diastolicBp,
        isSmoker: profile.isSmoker,
        notes: profile.notes,
      },
      update: {
        diabetesType: profile.diabetesType,
        yearOfDiagnosis: profile.yearOfDiagnosis,
        currentTreatment: profile.currentTreatment,
        lastHbA1c: profile.lastHbA1c,
        lastHbA1cDate: profile.lastHbA1cDate,
        systolicBp: profile.systolicBp,
        diastolicBp: profile.diastolicBp,
        isSmoker: profile.isSmoker,
        notes: profile.notes,
      },
    });
    return this.toDomain(record);
  }

  async deleteByPatientId(patientId: string): Promise<void> {
    await prisma.diabetesProfile.delete({
      where: { patientId },
    });
  }

  private toDomain(record: {
    id: string;
    patientId: string;
    diabetesType: string;
    yearOfDiagnosis: number | null;
    currentTreatment: string;
    lastHbA1c: number | null;
    lastHbA1cDate: Date | null;
    systolicBp: number | null;
    diastolicBp: number | null;
    isSmoker: boolean;
    notes: string | null;
    createdAt: Date;
    updatedAt: Date;
  }): DiabetesProfile {
    return DiabetesProfile.reconstitute({
      id: record.id,
      patientId: record.patientId,
      diabetesType: record.diabetesType as DiabetesType,
      yearOfDiagnosis: record.yearOfDiagnosis,
      currentTreatment: record.currentTreatment as TreatmentType,
      lastHbA1c: record.lastHbA1c,
      lastHbA1cDate: record.lastHbA1cDate,
      systolicBp: record.systolicBp,
      diastolicBp: record.diastolicBp,
      isSmoker: record.isSmoker,
      notes: record.notes,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
