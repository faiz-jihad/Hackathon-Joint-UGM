import { z } from "zod";

export const registerSchema = z.object({
  email: z.string().email("Format penulisan email tidak valid"),
  password: z.string().min(6, "Password minimal 6 karakter"),
  fullName: z.string().min(2, "Nama lengkap minimal 2 karakter"),
  role: z.enum(["PATIENT", "HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN", "DOKTER", "PENGGUNA"]).optional(),
  phoneNumber: z.string().optional(),
  facilityId: z.string().uuid().optional(),
  nik: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email("Format penulisan email tidak valid"),
  password: z.string().min(1, "Kata sandi wajib diisi"),
  role: z.enum(["PATIENT", "HEALTHCARE_WORKER", "OPHTHALMOLOGIST", "ADMIN", "DOKTER", "PENGGUNA"]).optional(),
});
