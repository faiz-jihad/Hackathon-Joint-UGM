import { NextRequest } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { HttpResponse } from "@/lib/http-response";
import bcrypt from "bcryptjs";

export async function GET(req: NextRequest) {
  try {
    const users = await prisma.$queryRaw<any[]>`
      SELECT 
        u.id, 
        u.email, 
        u.full_name as "fullName", 
        u.role, 
        u.phone_number as "phoneNumber", 
        u.is_active as "isActive", 
        u.facility_id as "facilityId", 
        f.name as "hospital",
        f.address as "facilityAddress",
        u.created_at as "createdAt", 
        u.updated_at as "updatedAt", 
        u.deleted_at as "deletedAt"
      FROM users u
      LEFT JOIN facilities f ON u.facility_id = f.id
      ORDER BY u.created_at ASC
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
    const { email, password, fullName, role, phoneNumber, isActive = true, hospital, facilityId } = body;

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

    let resolvedFacilityId = facilityId;
    if (!resolvedFacilityId && hospital) {
      const cleanHospName = hospital.split('(')[0].trim();
      const matchedFac = await prisma.facility.findFirst({
        where: {
          OR: [
            { name: hospital },
            { name: { contains: cleanHospName, mode: 'insensitive' } },
          ],
        },
      });
      if (matchedFac) resolvedFacilityId = matchedFac.id;
    }

    const newUser = await prisma.user.create({
      data: {
        email: email.toLowerCase().trim(),
        passwordHash,
        fullName: fullName.trim(),
        role: userRole,
        phoneNumber: phoneNumber?.trim() || null,
        facilityId: resolvedFacilityId || null,
        isActive: isActive !== false,
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        phoneNumber: true,
        facilityId: true,
        isActive: true,
        createdAt: true,
      },
    });

    return HttpResponse.created({
      ...newUser,
      hospital: hospital || null,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
