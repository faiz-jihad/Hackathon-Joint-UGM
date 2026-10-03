import { NextRequest } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { HttpResponse } from "@/lib/http-response";
import bcrypt from "bcryptjs";

export async function GET(req: NextRequest) {
  try {
    const users = await prisma.$queryRaw<any[]>`
      SELECT 
        id, 
        email, 
        full_name as "fullName", 
        role, 
        phone_number as "phoneNumber", 
        is_active as "isActive", 
        facility_id as "facilityId", 
        created_at as "createdAt", 
        updated_at as "updatedAt", 
        deleted_at as "deletedAt"
      FROM users
      ORDER BY created_at ASC
    `;

    return HttpResponse.success(users, 200, {
      total: users.length,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email, password, fullName, role, phoneNumber, isActive = true } = body;

    if (!email || !fullName || !role) {
      return HttpResponse.error("Email, nama lengkap, dan role wajib diisi.", "VALIDATION_ERROR", 400);
    }

    const existing = await prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    if (existing) {
      return HttpResponse.error(`Email ${email} sudah terdaftar di sistem.`, "CONFLICT_ERROR", 409);
    }

    const defaultPwd = password || "Retiva123!";
    const passwordHash = await bcrypt.hash(defaultPwd, 10);

    let userRole = role;
    if (role === "DOKTER") userRole = "OPHTHALMOLOGIST";
    if (role === "PENGGUNA") userRole = "PATIENT";

    const newUser = await prisma.user.create({
      data: {
        email: email.toLowerCase().trim(),
        passwordHash,
        fullName: fullName.trim(),
        role: userRole,
        phoneNumber: phoneNumber?.trim() || null,
        isActive: isActive !== false,
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        phoneNumber: true,
        isActive: true,
        createdAt: true,
      },
    });

    return HttpResponse.created(newUser);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
