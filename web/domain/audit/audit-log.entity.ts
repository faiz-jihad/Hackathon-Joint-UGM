export interface AuditLogProps {
  id: string;
  actorId?: string | null;
  actorRole?: string | null;
  action: string;
  resource: string;
  resourceId?: string | null;
  ipAddress?: string | null;
  userAgent?: string | null;
  metadata?: Record<string, any> | null;
  timestamp: Date;
}

export class AuditLog {
  private constructor(private readonly props: AuditLogProps) {}

  public static create(
    props: Omit<AuditLogProps, "id" | "timestamp"> & { id?: string }
  ): AuditLog {
    return new AuditLog({
      id: props.id || crypto.randomUUID(),
      actorId: props.actorId ?? null,
      actorRole: props.actorRole ?? null,
      action: props.action,
      resource: props.resource,
      resourceId: props.resourceId ?? null,
      ipAddress: props.ipAddress ?? null,
      userAgent: props.userAgent ?? null,
      metadata: props.metadata ?? {},
      timestamp: new Date(),
    });
  }

  public static reconstitute(props: AuditLogProps): AuditLog {
    return new AuditLog(props);
  }

  public get id(): string { return this.props.id; }
  public get actorId(): string | null | undefined { return this.props.actorId; }
  public get actorRole(): string | null | undefined { return this.props.actorRole; }
  public get action(): string { return this.props.action; }
  public get resource(): string { return this.props.resource; }
  public get resourceId(): string | null | undefined { return this.props.resourceId; }
  public get ipAddress(): string | null | undefined { return this.props.ipAddress; }
  public get userAgent(): string | null | undefined { return this.props.userAgent; }
  public get metadata(): Record<string, any> | null | undefined { return this.props.metadata; }
  public get timestamp(): Date { return this.props.timestamp; }

  public toJSON() {
    return {
      id: this.id,
      actorId: this.actorId,
      actorRole: this.actorRole,
      action: this.action,
      resource: this.resource,
      resourceId: this.resourceId,
      ipAddress: this.ipAddress,
      userAgent: this.userAgent,
      metadata: this.metadata,
      timestamp: this.timestamp.toISOString(),
    };
  }
}
