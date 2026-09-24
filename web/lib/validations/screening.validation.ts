import { z } from "zod";

export const initiateScreeningSchema = z.object({
  patientId: z.string().uuid("Invalid patientId format"),
  notes: z.string().max(1000).optional(),
  metadata: z.record(z.any()).optional(),
});

export const searchScreeningSchema = z.object({
  patientId: z.string().uuid().optional(),
  status: z
    .enum([
      "CREATED",
      "IMAGE_UPLOADED",
      "QUALITY_CHECK",
      "RETAKE_REQUIRED",
      "AI_ANALYZED",
      "HUMAN_REVIEW",
      "SCREENING_COMPLETED",
      "FOLLOW_UP_REQUIRED",
      "REFERRAL_RECOMMENDED",
      "FOLLOW_UP_COMPLETED",
    ])
    .optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export const uploadRetinalImageSchema = z.object({
  eye: z.enum(["OD", "OS"]),
});
