import { FacilityRepository, FacilitySearchParams } from "@/domain/facility/facility.repository";
import { Facility, BPJSStatus } from "@/domain/facility/facility.entity";
import { prisma } from "../prisma/client";

export class PrismaFacilityRepository implements FacilityRepository {
  private static memoryFacilities: Map<string, Facility> = new Map();

  constructor() {
    if (PrismaFacilityRepository.memoryFacilities.size === 0) {
      this.seedInitial();
    }
  }

  private seedInitial() {
    const f1 = Facility.reconstitute({
      id: "FAC-001",
      name: "RSUP Dr. Sardjito",
      address: "Jl. Kesehatan No. 1, Sekip, Sinduadi, Mlati, Sleman, D.I. Yogyakarta",
      latitude: -7.7684,
      longitude: 110.3734,
      bpjsStatus: "ACCEPTED",
      isVerified: true,
      contactPhone: "(0274) 631190",
      services: [
        { id: "srv-1", serviceName: "Vitreoretina", description: "Sub-spesialis Vitreoretina, Laser Fotokoagulasi, Bedah Retina Kompleks" },
      ],
      insurances: [
        { id: "ins-1", insuranceName: "BPJS Kesehatan", status: "ACTIVE" },
      ],
      createdAt: new Date("2024-01-01"),
      updatedAt: new Date("2024-01-01"),
    });

    const f2 = Facility.reconstitute({
      id: "FAC-002",
      name: "RS Khusus Mata Dr. Yap",
      address: "Jl. Cik Di Tiro No. 5, Terban, Gondokusuman, Yogyakarta",
      latitude: -7.7818,
      longitude: 110.3753,
      bpjsStatus: "ACCEPTED",
      isVerified: true,
      contactPhone: "(0274) 562054",
      services: [
        { id: "srv-2", serviceName: "Poli Retinopati Diabetik", description: "Injeksi Anti-VEGF Intravitreal, Angiografi Fluoresens, OCT Makula" },
      ],
      insurances: [
        { id: "ins-2", insuranceName: "BPJS Kesehatan", status: "ACTIVE" },
      ],
      createdAt: new Date("2024-01-01"),
      updatedAt: new Date("2024-01-01"),
    });

    const f3 = Facility.reconstitute({
      id: "FAC-003",
      name: "RS Bethesda Yogyakarta",
      address: "Jl. Jend. Sudirman No. 70, Kotabaru, Gondokusuman, Yogyakarta",
      latitude: -7.7836,
      longitude: 110.3776,
      bpjsStatus: "NEEDS_CONFIRMATION",
      isVerified: false,
      contactPhone: "(0274) 586688",
      services: [
        { id: "srv-3", serviceName: "Poli Mata Umum", description: "Skrining Komplikasi Diabetes Melitus Terpadu" },
      ],
      insurances: [
        { id: "ins-3", insuranceName: "BPJS Kesehatan", status: "VERIFICATION_REQUIRED" },
      ],
      createdAt: new Date("2024-01-01"),
      updatedAt: new Date("2024-01-01"),
    });

    const f4 = Facility.reconstitute({
      id: "FAC-004",
      name: "RS Panti Rapih",
      address: "Jl. Cik Di Tiro No. 30, Samirono, Terban, Gondokusuman, Yogyakarta",
      latitude: -7.7778,
      longitude: 110.3768,
      bpjsStatus: "NEEDS_CONFIRMATION",
      isVerified: false,
      contactPhone: "(0274) 514014",
      services: [
        { id: "srv-4", serviceName: "Poli Spesialis Mata", description: "Manajemen Diabetes Komprehensif" },
      ],
      insurances: [
        { id: "ins-4", insuranceName: "BPJS Kesehatan", status: "VERIFICATION_REQUIRED" },
      ],
      createdAt: new Date("2024-01-01"),
      updatedAt: new Date("2024-01-01"),
    });

    PrismaFacilityRepository.memoryFacilities.set(f1.id, f1);
    PrismaFacilityRepository.memoryFacilities.set(f2.id, f2);
    PrismaFacilityRepository.memoryFacilities.set(f3.id, f3);
    PrismaFacilityRepository.memoryFacilities.set(f4.id, f4);
  }

  async findById(id: string): Promise<Facility | null> {
    try {
      const record = await prisma.facility.findUnique({
        where: { id },
        include: {
          services: true,
          insurances: true,
        },
      });
      if (!record) return PrismaFacilityRepository.memoryFacilities.get(id) || null;
      return this.toDomain(record);
    } catch {
      return PrismaFacilityRepository.memoryFacilities.get(id) || null;
    }
  }

  async search(params: FacilitySearchParams): Promise<{ facilities: Facility[]; total: number }> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

    try {
      const whereClause: any = {};
      if (params.query) {
        whereClause.OR = [
          { name: { contains: params.query, mode: "insensitive" } },
          { address: { contains: params.query, mode: "insensitive" } },
        ];
      }
      if (params.bpjsStatus) whereClause.bpjsStatus = params.bpjsStatus;
      if (params.isVerified !== undefined) whereClause.isVerified = params.isVerified;
      if (params.hasService) {
        whereClause.services = {
          some: {
            serviceName: { contains: params.hasService, mode: "insensitive" },
          },
        };
      }

      const [records, total] = await Promise.all([
        prisma.facility.findMany({
          where: whereClause,
          include: { services: true, insurances: true },
          take: limit,
          skip: offset,
          orderBy: { name: "asc" },
        }),
        prisma.facility.count({ where: whereClause }),
      ]);

      return {
        facilities: records.map((r) => this.toDomain(r)),
        total,
      };
    } catch {
      let list = Array.from(PrismaFacilityRepository.memoryFacilities.values());
      if (params.query) {
        const q = params.query.toLowerCase();
        list = list.filter((f) => f.name.toLowerCase().includes(q) || f.address.toLowerCase().includes(q));
      }
      if (params.bpjsStatus) {
        list = list.filter((f) => f.bpjsStatus === params.bpjsStatus);
      }
      if (params.isVerified !== undefined) {
        list = list.filter((f) => f.isVerified === params.isVerified);
      }
      if (params.hasService) {
        const s = params.hasService.toLowerCase();
        list = list.filter((f) => f.services.some((srv) => srv.serviceName.toLowerCase().includes(s)));
      }
      return {
        facilities: list.slice(offset, offset + limit),
        total: list.length,
      };
    }
  }

  async listAll(): Promise<Facility[]> {
    try {
      const records = await prisma.facility.findMany({
        include: { services: true, insurances: true },
        orderBy: { name: "asc" },
      });
      return records.map((r) => this.toDomain(r));
    } catch {
      return Array.from(PrismaFacilityRepository.memoryFacilities.values());
    }
  }

  async create(facility: Facility): Promise<Facility> {
    PrismaFacilityRepository.memoryFacilities.set(facility.id, facility);
    try {
      const record = await prisma.facility.create({
        data: {
          id: facility.id,
          name: facility.name,
          address: facility.address,
          latitude: facility.latitude,
          longitude: facility.longitude,
          bpjsStatus: facility.bpjsStatus,
          isVerified: facility.isVerified,
          contactPhone: facility.contactPhone,
          services: {
            create: facility.services.map((s) => ({
              serviceName: s.serviceName,
              description: s.description,
            })),
          },
          insurances: {
            create: facility.insurances.map((i) => ({
              insuranceName: i.insuranceName,
              status: i.status,
            })),
          },
        },
        include: { services: true, insurances: true },
      });
      return this.toDomain(record);
    } catch {
      return facility;
    }
  }

  private toDomain(record: any): Facility {
    return Facility.reconstitute({
      id: record.id,
      name: record.name,
      address: record.address,
      latitude: record.latitude,
      longitude: record.longitude,
      bpjsStatus: record.bpjsStatus as BPJSStatus,
      isVerified: record.isVerified,
      contactPhone: record.contactPhone,
      services: record.services || [],
      insurances: record.insurances || [],
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
