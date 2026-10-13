import { z } from "zod";

export const createPatientSchema = z.object({
  userId: z.string().uuid().optional().nullable(),
  nik: z
    .string()
    .length(16, "NIK must be exactly 16 digits")
    .regex(/^\d{16}$/, "NIK must contain only numbers"),
  fullName: z.string().min(2, "Full name must be at least 2 characters"),
  birthDate: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: "Invalid birth date ISO string (e.g. 1980-05-15)",
  }),
  gender: z.enum(["MALE", "FEMALE"]),
  phone: z.string().optional().nullable(),
  address: z.string().optional().nullable(),
  emergencyContact: z.string().optional().nullable(),
  diabetesProfile: z
    .object({
      diabetesType: z.enum(["TYPE_1", "TYPE_2", "GESTATIONAL", "UNKNOWN"]).optional().default("TYPE_2"),
      yearOfDiagnosis: z.number().int().optional().nullable(),
      currentTreatment: z
        .enum(["INSULIN", "ORAL_MEDICATION", "DIET_AND_LIFESTYLE", "COMBINATION", "NONE", "UNKNOWN"])
        .optional()
        .default("ORAL_MEDICATION"),
      lastHbA1c: z.number().optional().nullable(),
      systolicBp: z.number().int().optional().nullable(),
      diastolicBp: z.number().int().optional().nullable(),
      isSmoker: z.boolean().optional().default(false),
      notes: z.string().optional().nullable(),
    })
    .optional()
    .nullable(),
});

export const updatePatientSchema = z.object({
  fullName: z.string().min(2, "Full name must be at least 2 characters").optional(),
  phone: z.string().optional().nullable(),
  address: z.string().optional().nullable(),
  emergencyContact: z.string().optional().nullable(),
});

export const searchPatientSchema = z.object({
  query: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
