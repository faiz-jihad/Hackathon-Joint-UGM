import { z } from "zod";

export const matchFacilitySchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  maxDistanceKm: z.number().positive().max(500).default(50),
  requiredService: z.string().optional(),
  requireBpjs: z.boolean().default(false),
});

export const searchFacilitySchema = z.object({
  query: z.string().optional(),
  bpjsStatus: z.enum(["ACCEPTED", "NOT_AVAILABLE", "NEEDS_CONFIRMATION"]).optional(),
  hasService: z.string().optional(),
  isVerified: z
    .string()
    .transform((val) => val === "true")
    .optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
