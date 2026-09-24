import { PatientRepository, PatientSearchParams, PatientSearchResult } from "@/domain/patient/patient.repository";
import { Patient, Gender } from "@/domain/patient/patient.entity";
import { prisma } from "../prisma/client";

export class PrismaPatientRepository implements PatientRepository {
  async findById(id: string): Promise<Patient | null> {
    const record = await prisma.patient.findUnique({
      where: { id },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByNik(nik: string): Promise<Patient | null> {
    const record = await prisma.patient.findUnique({
      where: { nik: nik.trim() },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByUserId(userId: string): Promise<Patient | null> {
    const record = await prisma.patient.findUnique({
      where: { userId },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async search(params: PatientSearchParams): Promise<PatientSearchResult> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;
    const query = params.query?.trim();

    const whereClause = query
      ? {
          OR: [
            { fullName: { contains: query, mode: "insensitive" as const } },
            { nik: { contains: query } },
            { phone: { contains: query } },
          ],
        }
      : {};

    const [records, total] = await Promise.all([
      prisma.patient.findMany({
        where: whereClause,
        take: limit,
        skip: offset,
        orderBy: { createdAt: "desc" },
      }),
      prisma.patient.count({
        where: whereClause,
      }),
    ]);

    return {
      patients: records.map((r) => this.toDomain(r)),
      total,
    };
  }

  async create(patient: Patient): Promise<Patient> {
    const record = await prisma.patient.create({
      data: {
        id: patient.id,
        userId: patient.userId,
        nik: patient.nik,
        fullName: patient.fullName,
        birthDate: patient.birthDate,
        gender: patient.gender,
        phone: patient.phone,
        address: patient.address,
        emergencyContact: patient.emergencyContact,
      },
    });
    return this.toDomain(record);
  }

  async update(patient: Patient): Promise<Patient> {
    const record = await prisma.patient.update({
      where: { id: patient.id },
      data: {
        fullName: patient.fullName,
        phone: patient.phone,
        address: patient.address,
        emergencyContact: patient.emergencyContact,
      },
    });
    return this.toDomain(record);
  }

  async delete(id: string): Promise<void> {
    await prisma.patient.delete({
      where: { id },
    });
  }

  private toDomain(record: {
    id: string;
    userId: string | null;
    nik: string;
    fullName: string;
    birthDate: Date;
    gender: string;
    phone: string | null;
    address: string | null;
    emergencyContact: string | null;
    createdAt: Date;
    updatedAt: Date;
  }): Patient {
    return Patient.reconstitute({
      id: record.id,
      userId: record.userId,
      nik: record.nik,
      fullName: record.fullName,
      birthDate: record.birthDate,
      gender: record.gender as Gender,
      phone: record.phone,
      address: record.address,
      emergencyContact: record.emergencyContact,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
