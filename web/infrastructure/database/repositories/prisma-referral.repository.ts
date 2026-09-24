import { ReferralRepository, ReferralSearchParams } from "@/domain/referral/referral.repository";
import { Referral, ReferralStatus } from "@/domain/referral/referral.entity";
import { UrgencyLevel } from "@/domain/recommendation/recommendation.entity";
import { prisma } from "../prisma/client";

export class PrismaReferralRepository implements ReferralRepository {
  async findById(id: string): Promise<Referral | null> {
    const record = await prisma.referral.findUnique({
      where: { id },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByScreeningId(screeningId: string): Promise<Referral | null> {
    const record = await prisma.referral.findFirst({
      where: { screeningId },
      orderBy: { createdAt: "desc" },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByPatientId(patientId: string): Promise<Referral[]> {
    const records = await prisma.referral.findMany({
      where: { patientId },
      orderBy: { createdAt: "desc" },
    });
    return records.map((r) => this.toDomain(r));
  }

  async search(params: ReferralSearchParams): Promise<{ referrals: Referral[]; total: number }> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

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
  }

  async create(referral: Referral): Promise<Referral> {
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
  }

  async update(referral: Referral): Promise<Referral> {
    const record = await prisma.referral.update({
      where: { id: referral.id },
      data: {
        status: referral.status,
        issuedAt: referral.issuedAt,
        expiresAt: referral.expiresAt,
      },
    });
    return this.toDomain(record);
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
