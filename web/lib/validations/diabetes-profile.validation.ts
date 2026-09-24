import { z } from "zod";

export const upsertDiabetesProfileSchema = z.object({
  diabetesType: z.enum(["TYPE_1", "TYPE_2", "GESTATIONAL", "UNKNOWN"]),
  yearOfDiagnosis: z
    .number()
    .int()
    .min(1920)
    .max(new Date().getFullYear())
    .optional()
    .nullable(),
  currentTreatment: z.enum([
    "INSULIN",
    "ORAL_MEDICATION",
    "DIET_AND_LIFESTYLE",
    "COMBINATION",
    "NONE",
    "UNKNOWN",
  ]),
  lastHbA1c: z.number().min(3.0).max(25.0).optional().nullable(),
  lastHbA1cDate: z
    .string()
    .refine((val) => !val || !isNaN(Date.parse(val)), {
      message: "Invalid lastHbA1cDate ISO string",
    })
    .optional()
    .nullable(),
  systolicBp: z.number().int().min(50).max(300).optional().nullable(),
  diastolicBp: z.number().int().min(30).max(200).optional().nullable(),
  isSmoker: z.boolean().default(false),
  notes: z.string().max(1000).optional().nullable(),
});
