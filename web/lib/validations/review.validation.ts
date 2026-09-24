import { z } from "zod";

export const submitReviewSchema = z.object({
  reviewStatus: z.enum(["CONFIRMED_AI", "OVERRIDDEN"]),
  confirmedClass: z.enum([
    "NO_DR",
    "MILD_DR",
    "MODERATE_DR",
    "SEVERE_DR",
    "PROLIFERATIVE_DR",
  ]),
  clinicalNotes: z.string().max(2000).optional(),
});
