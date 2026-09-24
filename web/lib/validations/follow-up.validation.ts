import { z } from "zod";

export const scheduleFollowUpSchema = z.object({
  patientId: z.string().uuid("Invalid patientId format"),
  screeningId: z.string().uuid("Invalid screeningId format").optional(),
  dueDate: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: "Invalid due date format",
  }),
  notes: z.string().max(1000).optional(),
});

export const completeFollowUpSchema = z.object({
  notes: z.string().max(1000).optional(),
});
