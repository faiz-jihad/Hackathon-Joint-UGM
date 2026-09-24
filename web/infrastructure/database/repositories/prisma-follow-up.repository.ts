import { FollowUpRepository, FollowUpSearchParams } from "@/domain/follow-up/follow-up.repository";
import { FollowUp, FollowUpStatus } from "@/domain/follow-up/follow-up.entity";
import { prisma } from "../prisma/client";

export class PrismaFollowUpRepository implements FollowUpRepository {
  async findById(id: string): Promise<FollowUp | null> {
    const record = await prisma.followUp.findUnique({
      where: { id },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByPatientId(patientId: string): Promise<FollowUp[]> {
    const records = await prisma.followUp.findMany({
      where: { patientId },
      orderBy: { dueDate: "asc" },
    });
    return records.map((r) => this.toDomain(r));
  }

  async findByScreeningId(screeningId: string): Promise<FollowUp | null> {
    const record = await prisma.followUp.findFirst({
      where: { screeningId },
      orderBy: { createdAt: "desc" },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async search(params: FollowUpSearchParams): Promise<{ followUps: FollowUp[]; total: number }> {
    const limit = params.limit || 20;
    const offset = params.offset || 0;

    const whereClause: any = {};
    if (params.patientId) whereClause.patientId = params.patientId;
    if (params.status) whereClause.status = params.status;
    if (params.dueBefore) whereClause.dueDate = { lte: params.dueBefore };

    const [records, total] = await Promise.all([
      prisma.followUp.findMany({
        where: whereClause,
        take: limit,
        skip: offset,
        orderBy: { dueDate: "asc" },
      }),
      prisma.followUp.count({ where: whereClause }),
    ]);

    return {
      followUps: records.map((r) => this.toDomain(r)),
      total,
    };
  }

  async create(followUp: FollowUp): Promise<FollowUp> {
    const record = await prisma.followUp.create({
      data: {
        id: followUp.id,
        patientId: followUp.patientId,
        screeningId: followUp.screeningId,
        dueDate: followUp.dueDate,
        status: followUp.status,
        completionNotes: followUp.completionNotes,
      },
    });
    return this.toDomain(record);
  }

  async update(followUp: FollowUp): Promise<FollowUp> {
    const record = await prisma.followUp.update({
      where: { id: followUp.id },
      data: {
        status: followUp.status,
        completionNotes: followUp.completionNotes,
        completedAt: followUp.completedAt,
      },
    });
    return this.toDomain(record);
  }

  private toDomain(record: any): FollowUp {
    return FollowUp.reconstitute({
      id: record.id,
      patientId: record.patientId,
      screeningId: record.screeningId,
      dueDate: record.dueDate,
      status: record.status as FollowUpStatus,
      completionNotes: record.completionNotes,
      completedAt: record.completedAt,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
