import { z } from "zod";

export const registerModelSchema = z.object({
  modelName: z.string().min(2),
  version: z.string().min(3),
  pipelineVersion: z.string().min(3),
  weightsHash: z.string().startsWith("sha256:"),
  isActive: z.boolean().default(true),
});

export const searchAuditLogSchema = z.object({
  actorId: z.string().uuid().optional(),
  action: z.string().optional(),
  resource: z.string().optional(),
  resourceId: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});
