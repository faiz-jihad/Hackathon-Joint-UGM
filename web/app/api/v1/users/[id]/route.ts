import { NextRequest } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { HttpResponse } from "@/lib/http-response";
import bcrypt from "bcryptjs";

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await req.json();
    const { email, password, fullName, role, phoneNumber, isActive, hospital, facilityId } = body;

    const existing = await prisma.user.findUnique({
      where: { id },
    });

    if (!existing) {
      return HttpResponse.error("Pengguna tidak ditemukan.", "NOT_FOUND", 404);
    }

    if (email && email.toLowerCase().trim() !== existing.email.toLowerCase()) {
      const emailConflict = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
      });
      if (emailConflict) {
        return HttpResponse.error(`Email ${email} sudah digunakan oleh akun lain.`, "CONFLICT_ERROR", 409);
      }
    }

    let userRole = role || existing.role;
    if (role === "DOKTER") userRole = "OPHTHALMOLOGIST";
    if (role === "PENGGUNA") userRole = "PATIENT";

    let resolvedFacilityId = facilityId;
    if (resolvedFacilityId === undefined && hospital) {
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

    const dataToUpdate: any = {
      fullName: fullName !== undefined ? fullName.trim() : existing.fullName,
      email: email ? email.toLowerCase().trim() : existing.email,
      role: userRole,
      phoneNumber: phoneNumber !== undefined ? (phoneNumber?.trim() || null) : existing.phoneNumber,
      isActive: isActive !== undefined ? isActive : existing.isActive,
    };

    if (resolvedFacilityId !== undefined) {
      dataToUpdate.facilityId = resolvedFacilityId;
    }

    if (password && password.trim() !== "") {
      dataToUpdate.passwordHash = await bcrypt.hash(password.trim(), 10);
    }

    if (body.action === 'restore' || body.restore === true) {
      await prisma.$executeRaw`
        UPDATE users
        SET is_active = true, deleted_at = NULL, updated_at = NOW()
        WHERE id = ${id}
      `;
      return HttpResponse.success({ id, restored: true });
    }

    const updated = await prisma.user.update({
      where: { id },
      data: dataToUpdate,
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        phoneNumber: true,
        isActive: true,
        updatedAt: true,
      },
    });

    return HttpResponse.success(updated);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;

    const existing = await prisma.user.findUnique({
      where: { id },
    });

    if (!existing) {
      return HttpResponse.error("Pengguna tidak ditemukan.", "NOT_FOUND", 404);
    }

    // Soft delete: deactive account & set deletedAt timestamp
    // Preserves foreign key integrity (doctorVerification, patient, reviewsConducted, auditLogs)
    await prisma.$executeRaw`
      UPDATE users
      SET is_active = false, deleted_at = NOW(), updated_at = NOW()
      WHERE id = ${id}
    `;

    return HttpResponse.success({ id, deleted: true, softDelete: true });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
