import { ReferralRepository, ReferralSearchParams } from "@/domain/referral/referral.repository";
import { Referral, ReferralStatus } from "@/domain/referral/referral.entity";
import { UrgencyLevel } from "@/domain/recommendation/recommendation.entity";
import { prisma } from "../prisma/client";

export class PrismaReferralRepository implements ReferralRepository {
  private static memoryReferrals: Map<string, Referral> = new Map();

  constructor() {
    if (PrismaReferralRepository.memoryReferrals.size === 0) {
      this.seedInitial();
    }
  }

  private seedInitial() {
    const r1 = Referral.reconstitute({
      id: "RUJ-20260924-0041",
      screeningId: "SCR-2026-0890",
      patientId: "P-002",
      targetFacilityId: "FAC-002",
      urgency: "HIGH",
      reason: "E11.319 - Type 2 diabetes with severe nonproliferative diabetic retinopathy",
      clinicalSummary: "Tampak perdarahan intraretina difus 4 kuadran. Rujukan prioritas cito untuk evaluasi PRP dan OCT makula.",
      status: "ISSUED",
      issuedAt: new Date("2026-09-24T09:05:00Z"),
      expiresAt: new Date("2026-10-08T09:05:00Z"),
      createdAt: new Date("2026-09-24T09:05:00Z"),
      updatedAt: new Date("2026-09-24T09:05:00Z"),
    });

    PrismaReferralRepository.memoryReferrals.set(r1.id, r1);
  }

  async findById(id: string): Promise<Referral | null> {
    try {
      const record = await prisma.referral.findUnique({
        where: { id },
      });
      if (!record) return PrismaReferralRepository.memoryReferrals.get(id) || null;
      return this.toDomain(record);
    } catch {
      return PrismaReferralRepository.memoryReferrals.get(id) || null;
    }
  }

  async findByScreeningId(screeningId: string): Promise<Referral | null> {
    try {
      const record = await prisma.referral.findFirst({
        where: { screeningId },
        orderBy: { createdAt: "desc" },
      });
      if (!record) {
        return (
          Array.from(PrismaReferralRepository.memoryReferrals.values()).find(
            (r) => r.screeningId === screeningId
          ) || null
        );
      }
      return this.toDomain(record);
    } catch {
      return (
        Array.from(PrismaReferralRepository.memoryReferrals.values()).find(
          (r) => r.screeningId === screeningId
        ) || null
      );
    }
  }

  async findByPatientId(patientId: string): Promise<Referral[]> {
    try {
      const records = await prisma.referral.findMany({
        where: { patientId },
        orderBy: { createdAt: "desc" },
      });
      return records.map((r) => this.toDomain(r));
    } catch {
      return Array.from(PrismaReferralRepository.memoryReferrals.values()).filter(
        (r) => r.patientId === patientId
      );
    }
  }

  async search(params: ReferralSearchParams): Promise<{ referrals: Referral[]; total: number }> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

    try {
      const whereClause: any = {};
      if (params.patientId) whereClause.patientId = params.patientId;
      if (params.targetFacilityId) whereClause.targetFacilityId = params.targetFacilityId;
      if (params.status) whereClause.status = params.status;

      const [records, total] = await Promise.all([
        prisma.referral.findMany({
          where: whereClause,
          take: limit,
          skip: offset,
          orderBy: { createdAt: "desc" },
        }),
        prisma.referral.count({ where: whereClause }),
      ]);

      return {
        referrals: records.map((r) => this.toDomain(r)),
        total,
      };
    } catch {
      let list = Array.from(PrismaReferralRepository.memoryReferrals.values());
      if (params.patientId) list = list.filter((r) => r.patientId === params.patientId);
      if (params.targetFacilityId) list = list.filter((r) => r.targetFacilityId === params.targetFacilityId);
      if (params.status) list = list.filter((r) => r.status === params.status);

      return {
        referrals: list.slice(offset, offset + limit),
        total: list.length,
      };
    }
  }

  async create(referral: Referral): Promise<Referral> {
    PrismaReferralRepository.memoryReferrals.set(referral.id, referral);
    try {
      const record = await prisma.referral.create({
        data: {
          id: referral.id,
          screeningId: referral.screeningId,
          patientId: referral.patientId,
          targetFacilityId: referral.targetFacilityId,
          urgency: referral.urgency,
          reason: referral.reason,
          clinicalSummary: referral.clinicalSummary,
          status: referral.status,
          issuedAt: referral.issuedAt,
          expiresAt: referral.expiresAt,
        },
      });
      return this.toDomain(record);
    } catch {
      return referral;
    }
  }

  async update(referral: Referral): Promise<Referral> {
    PrismaReferralRepository.memoryReferrals.set(referral.id, referral);
    try {
      const record = await prisma.referral.update({
        where: { id: referral.id },
        data: {
          status: referral.status,
          issuedAt: referral.issuedAt,
          expiresAt: referral.expiresAt,
        },
      });
      return this.toDomain(record);
    } catch {
      return referral;
    }
  }

  private toDomain(record: any): Referral {
    return Referral.reconstitute({
      id: record.id,
      screeningId: record.screeningId,
      patientId: record.patientId,
      targetFacilityId: record.targetFacilityId,
      urgency: record.urgency as UrgencyLevel,
      reason: record.reason,
      clinicalSummary: record.clinicalSummary,
      status: record.status as ReferralStatus,
      issuedAt: record.issuedAt,
      expiresAt: record.expiresAt,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
