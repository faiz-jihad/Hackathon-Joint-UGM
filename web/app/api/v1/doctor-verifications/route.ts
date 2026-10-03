import { NextRequest } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { HttpResponse } from "@/lib/http-response";
import bcrypt from "bcryptjs";

// GET /api/v1/doctor-verifications
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const status = searchParams.get("status");

    let rows: any[] = [];
    if (status && status !== "ALL") {
      rows = await prisma.$queryRaw<any[]>`
        SELECT 
          id, user_id as "userId", full_name as "fullName", email, 
          phone_number as "phoneNumber", sip_number as "sipNumber", 
          str_number as "strNumber", primary_facility as "primaryFacility", 
          sub_specialty as "subSpecialty", status, kki_check as "kkiCheck", 
          verification_notes as "verificationNotes", verified_by as "verifiedBy", 
          verified_at as "verifiedAt", str_file_name as "strFileName", 
          sip_file_name as "sipFileName", str_file_size as "strFileSize", 
          sip_file_size as "sipFileSize", submitted_at as "submittedAt"
        FROM doctor_verifications
        WHERE status::text = ${status}
        ORDER BY submitted_at DESC
      `;
    } else {
      rows = await prisma.$queryRaw<any[]>`
        SELECT 
          id, user_id as "userId", full_name as "fullName", email, 
          phone_number as "phoneNumber", sip_number as "sipNumber", 
          str_number as "strNumber", primary_facility as "primaryFacility", 
          sub_specialty as "subSpecialty", status, kki_check as "kkiCheck", 
          verification_notes as "verificationNotes", verified_by as "verifiedBy", 
          verified_at as "verifiedAt", str_file_name as "strFileName", 
          sip_file_name as "sipFileName", str_file_size as "strFileSize", 
          sip_file_size as "sipFileSize", submitted_at as "submittedAt"
        FROM doctor_verifications
        ORDER BY submitted_at DESC
      `;
    }

    return HttpResponse.success(rows, 200, {
      total: rows.length,
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

// POST /api/v1/doctor-verifications
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const {
      id,
      fullName,
      email,
      phoneNumber = "-",
      sipNumber,
      strNumber,
      primaryFacility = "-",
      subSpecialty = "Dokter Umum (Pelayanan Primer)",
      status = "PENDING",
      kkiCheck = "UNVERIFIED",
      verificationNotes,
      strFileName,
      sipFileName,
      strFileSize,
      sipFileSize,
      strDataUrl,
      sipDataUrl,
    } = body;

    if (!fullName || !email || !sipNumber || !strNumber) {
      return HttpResponse.error("Nama lengkap, email, No. SIP, dan No. STR wajib diisi.", "VALIDATION_ERROR", 400);
    }

    const recId = id || `doc-verif-${Date.now()}`;

    await prisma.$executeRaw`
      INSERT INTO doctor_verifications (
        id, full_name, email, phone_number, sip_number, str_number,
        primary_facility, sub_specialty, status, kki_check, verification_notes,
        str_file_name, sip_file_name, str_file_size, sip_file_size, str_data_url, sip_data_url,
        submitted_at, created_at, updated_at
      ) VALUES (
        ${recId}, ${fullName}, ${email}, ${phoneNumber}, ${sipNumber}, ${strNumber},
        ${primaryFacility}, ${subSpecialty}, ${status}::"DoctorVerificationStatus", ${kkiCheck}::"KKICheckStatus", ${verificationNotes || null},
        ${strFileName || null}, ${sipFileName || null}, ${strFileSize || null}, ${sipFileSize || null}, ${strDataUrl || null}, ${sipDataUrl || null},
        NOW(), NOW(), NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        sip_number = EXCLUDED.sip_number,
        str_number = EXCLUDED.str_number,
        primary_facility = EXCLUDED.primary_facility,
        sub_specialty = EXCLUDED.sub_specialty,
        status = EXCLUDED.status,
        kki_check = EXCLUDED.kki_check,
        verification_notes = EXCLUDED.verification_notes,
        str_file_name = EXCLUDED.str_file_name,
        sip_file_name = EXCLUDED.sip_file_name,
        str_file_size = EXCLUDED.str_file_size,
        sip_file_size = EXCLUDED.sip_file_size,
        str_data_url = EXCLUDED.str_data_url,
        sip_data_url = EXCLUDED.sip_data_url,
        updated_at = NOW();
    `;

    return HttpResponse.created({ id: recId, email, fullName, status });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

// PATCH /api/v1/doctor-verifications
export async function PATCH(req: NextRequest) {
  try {
    const body = await req.json();
    const { id, status, verificationNotes, verifiedBy = "Administrator RETIVA", email, fullName, phoneNumber, password } = body;

    if (!id || !status) {
      return HttpResponse.error("ID dan status verifikasi wajib disertakan.", "VALIDATION_ERROR", 400);
    }

    // Find the doctor verification record
    const existing = await prisma.doctorVerification.findFirst({
      where: {
        OR: [{ id }, { email: email ? email.toLowerCase().trim() : undefined }]
      }
    });

    const targetEmail = (email || existing?.email || "").toLowerCase().trim();
    const targetFullName = fullName || existing?.fullName || "Dokter RETIVA";
    const targetPhone = phoneNumber || existing?.phoneNumber || null;

    let createdUserId: string | null = existing?.userId || null;

    if (status === "VERIFIED" && targetEmail) {
      // Check if user exists in User table
      let user = await prisma.user.findUnique({
        where: { email: targetEmail },
      });

      if (!user) {
        const rawPassword = password || "Dokter123!";
        const passwordHash = await bcrypt.hash(rawPassword, 10);
        user = await prisma.user.create({
          data: {
            email: targetEmail,
            fullName: targetFullName,
            phoneNumber: targetPhone && targetPhone !== '-' ? targetPhone : null,
            role: "OPHTHALMOLOGIST",
            passwordHash,
            isActive: true,
          },
        });
      } else {
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            role: "OPHTHALMOLOGIST",
            isActive: true,
            fullName: targetFullName,
          },
        });
      }
      createdUserId = user.id;
    } else if (status === "REJECTED" && existing?.userId) {
      await prisma.user.update({
        where: { id: existing.userId },
        data: { isActive: false },
      }).catch(() => {});
    }

    await prisma.$executeRaw`
      UPDATE doctor_verifications
      SET 
        status = ${status}::"DoctorVerificationStatus",
        user_id = ${createdUserId},
        verification_notes = ${verificationNotes || null},
        verified_by = ${verifiedBy},
        verified_at = NOW(),
        updated_at = NOW()
      WHERE id = ${existing?.id || id} OR email = ${targetEmail}
    `;

    return HttpResponse.success({ id, status, userId: createdUserId, verifiedBy, verifiedAt: new Date().toISOString() });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
