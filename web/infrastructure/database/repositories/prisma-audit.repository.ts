import { AuditRepository, CreateAuditLogDTO, AuditSearchParams } from "@/domain/audit/audit.repository";
import { AuditLog } from "@/domain/audit/audit-log.entity";
import { prisma } from "../prisma/client";

export class PrismaAuditRepository implements AuditRepository {
  async record(entry: CreateAuditLogDTO): Promise<void> {
    try {
      await prisma.auditLog.create({
        data: {
          actorId: entry.actorId || null,
          actorRole: entry.actorRole || null,
          action: entry.action,
          resource: entry.resource,
          resourceId: entry.resourceId || null,
          ipAddress: entry.ipAddress || null,
          userAgent: entry.userAgent || null,
          metadata: entry.metadata || {},
        },
      });
    } catch (err) {
      console.error("[AuditRepository]: Failed to write audit log entry:", err);
    }
  }

  async search(params: AuditSearchParams): Promise<{ logs: AuditLog[]; total: number }> {
    const limit = params.limit || 50;
    const offset = params.offset || 0;

    const whereClause: any = {};
    if (params.actorId) whereClause.actorId = params.actorId;
    if (params.action) whereClause.action = { contains: params.action, mode: "insensitive" };
    if (params.resource) whereClause.resource = params.resource;
    if (params.resourceId) whereClause.resourceId = params.resourceId;

    if (params.startDate || params.endDate) {
      whereClause.timestamp = {};
      if (params.startDate) whereClause.timestamp.gte = params.startDate;
      if (params.endDate) whereClause.timestamp.lte = params.endDate;
    }

    const [records, total] = await Promise.all([
      prisma.auditLog.findMany({
        where: whereClause,
        take: limit,
        skip: offset,
        orderBy: { timestamp: "desc" },
      }),
      prisma.auditLog.count({ where: whereClause }),
    ]);

    return {
      logs: records.map((r) =>
        AuditLog.reconstitute({
          id: r.id,
          actorId: r.actorId,
          actorRole: r.actorRole,
          action: r.action,
          resource: r.resource,
          resourceId: r.resourceId,
          ipAddress: r.ipAddress,
          userAgent: r.userAgent,
          metadata: (r.metadata as Record<string, any>) || {},
          timestamp: r.timestamp,
        })
      ),
      total,
    };
  }
}
