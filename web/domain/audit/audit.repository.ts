import { AuditLog } from "./audit-log.entity";

export interface CreateAuditLogDTO {
  actorId?: string | null;
  actorRole?: string | null;
  action: string;
  resource: string;
  resourceId?: string | null;
  ipAddress?: string | null;
  userAgent?: string | null;
  metadata?: Record<string, any> | null;
}

export interface AuditSearchParams {
  actorId?: string;
  action?: string;
  resource?: string;
  resourceId?: string;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
  offset?: number;
}

export interface AuditRepository {
  record(entry: CreateAuditLogDTO): Promise<void>;
  search(params: AuditSearchParams): Promise<{ logs: AuditLog[]; total: number }>;
}
