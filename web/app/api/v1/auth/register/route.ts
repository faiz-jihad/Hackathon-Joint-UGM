import { NextRequest } from "next/server";
import { authService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { registerSchema } from "@/lib/validations/auth.validation";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const validated = registerSchema.safeParse(body);

    if (!validated.success) {
      return HttpResponse.error(
        "Validation failed",
        "VALIDATION_ERROR",
        400,
        validated.error.flatten().fieldErrors
      );
    }

    const result = await authService.register(validated.data);

    if (validated.data.nik && result?.user?.id) {
      try {
        await prisma.patient.upsert({
          where: { nik: validated.data.nik },
          create: {
            userId: result.user.id,
            nik: validated.data.nik,
            fullName: validated.data.fullName,
            phone: validated.data.phoneNumber || null,
            gender: "FEMALE",
            birthDate: new Date("1990-01-01"),
          },
          update: {
            userId: result.user.id,
          },
        });
      } catch (err) {
        console.warn("Could not upsert patient record during user registration:", err);
      }
    }

    return HttpResponse.created(result);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
