import { z } from "zod";

export const createReferralSchema = z.object({
  screeningId: z.string().uuid("Invalid screeningId format"),
  patientId: z.string().uuid("Invalid patientId format"),
  targetFacilityId: z.string().uuid("Invalid targetFacilityId format"),
  urgency: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).default("MEDIUM"),
  reason: z.string().min(5, "Referral reason must be at least 5 characters"),
  clinicalSummary: z.string().min(10, "Clinical summary must be at least 10 characters"),
});

export const updateReferralStatusSchema = z.object({
  status: z.enum([
    "RECOMMENDED",
    "ISSUED",
    "ACCEPTED_BY_FACILITY",
    "PATIENT_ATTENDED",
    "EXPIRED",
    "CANCELLED",
  ]),
});
