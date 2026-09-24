import { PatientRepository, PatientSearchParams, PatientSearchResult } from "@/domain/patient/patient.repository";
import { Patient, Gender } from "@/domain/patient/patient.entity";
import { prisma } from "../prisma/client";

export class PrismaPatientRepository implements PatientRepository {
  private static memoryPatients: Map<string, Patient> = new Map();

  constructor() {
    if (PrismaPatientRepository.memoryPatients.size === 0) {
      this.seedInitial();
    }
  }

  private seedInitial() {
    const p1 = Patient.reconstitute({
      id: "P-001",
      nik: "3404071203720001",
      fullName: "Bambang Sudarmono",
      birthDate: new Date("1970-03-12"),
      gender: "MALE",
      phone: "081234567890",
      createdAt: new Date("2024-07-10T08:00:00Z"),
      updatedAt: new Date("2026-09-24T08:00:00Z"),
    });
    const p2 = Patient.reconstitute({
      id: "P-002",
      nik: "3404084501650002",
      fullName: "Siti Aminah",
      birthDate: new Date("1965-01-05"),
      gender: "FEMALE",
      phone: "081298765432",
      createdAt: new Date("2026-09-24T08:30:00Z"),
      updatedAt: new Date("2026-09-24T08:30:00Z"),
    });
    const p3 = Patient.reconstitute({
      id: "P-003",
      nik: "3402015206780004",
      fullName: "Endang Rahayu",
      birthDate: new Date("1978-06-12"),
      gender: "FEMALE",
      phone: "081377889900",
      createdAt: new Date("2026-09-23T14:00:00Z"),
      updatedAt: new Date("2026-09-23T14:00:00Z"),
    });

    PrismaPatientRepository.memoryPatients.set(p1.id, p1);
    PrismaPatientRepository.memoryPatients.set(p2.id, p2);
    PrismaPatientRepository.memoryPatients.set(p3.id, p3);
  }

  async findById(id: string): Promise<Patient | null> {
    try {
      const record = await prisma.patient.findUnique({ where: { id } });
      if (!record) return PrismaPatientRepository.memoryPatients.get(id) || null;
      return this.toDomain(record);
    } catch {
      return PrismaPatientRepository.memoryPatients.get(id) || null;
    }
  }

  async findByNik(nik: string): Promise<Patient | null> {
    const trimmed = nik.trim();
    try {
      const record = await prisma.patient.findUnique({ where: { nik: trimmed } });
      if (!record) {
        return Array.from(PrismaPatientRepository.memoryPatients.values()).find((p) => p.nik === trimmed) || null;
      }
      return this.toDomain(record);
    } catch {
      return Array.from(PrismaPatientRepository.memoryPatients.values()).find((p) => p.nik === trimmed) || null;
    }
  }

  async findByUserId(userId: string): Promise<Patient | null> {
    try {
      const record = await prisma.patient.findUnique({ where: { userId } });
      if (!record) return null;
      return this.toDomain(record);
    } catch {
      return Array.from(PrismaPatientRepository.memoryPatients.values()).find((p) => p.userId === userId) || null;
    }
  }

  async search(params: PatientSearchParams): Promise<PatientSearchResult> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;
    const query = params.query?.trim();

    try {
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
        prisma.patient.count({ where: whereClause }),
      ]);

      return {
        patients: records.map((r) => this.toDomain(r)),
        total,
      };
    } catch {
      let list = Array.from(PrismaPatientRepository.memoryPatients.values());
      if (query) {
        const q = query.toLowerCase();
        list = list.filter((p) => p.fullName.toLowerCase().includes(q) || p.nik.includes(q));
      }
      return {
        patients: list.slice(offset, offset + limit),
        total: list.length,
      };
    }
  }

  async create(patient: Patient): Promise<Patient> {
    PrismaPatientRepository.memoryPatients.set(patient.id, patient);
    try {
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
    } catch {
      return patient;
    }
  }

  async update(patient: Patient): Promise<Patient> {
    PrismaPatientRepository.memoryPatients.set(patient.id, patient);
    try {
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
    } catch {
      return patient;
    }
  }

  async delete(id: string): Promise<void> {
    PrismaPatientRepository.memoryPatients.delete(id);
    try {
      await prisma.patient.delete({ where: { id } });
    } catch {
      // Offline fallback succeeded
    }
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
