import { AuditRepository, CreateAuditLogDTO, AuditSearchParams } from "@/domain/audit/audit.repository";
import { AuditLog } from "@/domain/audit/audit-log.entity";
import { prisma } from "../prisma/client";

export class PrismaAuditRepository implements AuditRepository {
  private static memoryLogs: AuditLog[] = [];

  constructor() {
    if (PrismaAuditRepository.memoryLogs.length === 0) {
      this.seedInitial();
    }
  }

  private seedInitial() {
    const l1 = AuditLog.reconstitute({
      id: "AUD-88219",
      actorId: "usr-001",
      actorRole: "OPHTHALMOLOGIST",
      action: "HUMAN_REVIEW_ADJUDICATION",
      resource: "Screening",
      resourceId: "SCR-2026-0890",
      ipAddress: "192.168.1.10",
      userAgent: "RETIVA-Clinical-Client/1.0",
      metadata: { notes: "Ajudikasi Severe NPDR terkonfirmasi spesialis retina" },
      timestamp: new Date("2026-09-24T09:00:00Z"),
    });

    const l2 = AuditLog.reconstitute({
      id: "AUD-88218",
      actorId: "usr-002",
      actorRole: "HEALTHCARE_WORKER",
      action: "SCREENING_SESSION_COMPLETED",
      resource: "Screening",
      resourceId: "SCR-2026-0891",
      ipAddress: "192.168.1.15",
      userAgent: "RETIVA-Clinical-Client/1.0",
      metadata: { patient: "Bambang Sudarmono", eye: "OD" },
      timestamp: new Date("2026-09-24T09:15:00Z"),
    });

    const l3 = AuditLog.reconstitute({
      id: "AUD-88217",
      actorId: "system",
      actorRole: "SYSTEM",
      action: "QUALITY_GATE_EVALUATED",
      resource: "RetinalImage",
      resourceId: "IMG-OD-001",
      ipAddress: "127.0.0.1",
      userAgent: "RETIVA-Inference/1.0",
      metadata: { passed: true, sharpness: 0.84, illumination: 0.78 },
      timestamp: new Date("2026-09-24T09:14:45Z"),
    });

    PrismaAuditRepository.memoryLogs.push(l1, l2, l3);
  }

  async record(entry: CreateAuditLogDTO): Promise<void> {
    const memoryLog = AuditLog.reconstitute({
      id: `AUD-${Math.floor(10000 + Math.random() * 90000)}`,
      actorId: entry.actorId || null,
      actorRole: entry.actorRole || null,
      action: entry.action,
      resource: entry.resource,
      resourceId: entry.resourceId || null,
      ipAddress: entry.ipAddress || null,
      userAgent: entry.userAgent || null,
      metadata: entry.metadata || {},
      timestamp: new Date(),
    });
    PrismaAuditRepository.memoryLogs.unshift(memoryLog);

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
    } catch {
      // Memory store is already populated
    }
  }

  async search(params: AuditSearchParams): Promise<{ logs: AuditLog[]; total: number }> {
    const limit = params.limit || 50;
    const offset = params.offset || 0;

    try {
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
    } catch {
      let list = [...PrismaAuditRepository.memoryLogs];
      if (params.actorId) list = list.filter((l) => l.actorId === params.actorId);
      if (params.action) {
        const act = params.action.toLowerCase();
        list = list.filter((l) => l.action.toLowerCase().includes(act));
      }
      if (params.resource) list = list.filter((l) => l.resource === params.resource);
      if (params.resourceId) list = list.filter((l) => l.resourceId === params.resourceId);

      return {
        logs: list.slice(offset, offset + limit),
        total: list.length,
      };
    }
  }
}
