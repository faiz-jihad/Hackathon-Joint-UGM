import { FacilityRepository, FacilitySearchParams } from "@/domain/facility/facility.repository";
import { Facility, BPJSStatus } from "@/domain/facility/facility.entity";
import { prisma } from "../prisma/client";

export class PrismaFacilityRepository implements FacilityRepository {
  async findById(id: string): Promise<Facility | null> {
    const record = await prisma.facility.findUnique({
      where: { id },
      include: {
        services: true,
        insurances: true,
      },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async search(params: FacilitySearchParams): Promise<{ facilities: Facility[]; total: number }> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

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
  }

  async listAll(): Promise<Facility[]> {
    const records = await prisma.facility.findMany({
      include: { services: true, insurances: true },
      orderBy: { name: "asc" },
    });
    return records.map((r) => this.toDomain(r));
  }

  async create(facility: Facility): Promise<Facility> {
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
