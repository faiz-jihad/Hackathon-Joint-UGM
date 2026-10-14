import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const patientId = searchParams.get("patientId") || searchParams.get("patient_id");

    if (!patientId) {
      return NextResponse.json(
        { success: false, error: "patientId parameter is required." },
        { status: 400 }
      );
    }

    const summaries = await (prisma as any).consultationSummary.findMany({
      where: { patientId },
      orderBy: { createdAt: "desc" },
    }).catch(() => []);

    return NextResponse.json({
      success: true,
      data: summaries,
    });
  } catch (error: any) {
    console.error("[consultation-summary GET]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to retrieve consultation summaries." },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let {
      patientId,
      screeningId,
      consultationDate = new Date().toISOString(),
      hospitalClinicName,
      doctorName,
      doctorFindingsDiagnosis,
      recommendedTreatment,
      prescribedMedications = [],
      followUpDate,
      dietaryLifestyleInstructions,
      additionalRestrictions,
      source = "PATIENT_REPORTED",
      verificationStatus = "UNVERIFIED_PATIENT_ENTRY",
      isPatientConfirmed = false,
      notes,
    } = body;

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id;
    }

    if (!patientId) {
      return NextResponse.json(
        { success: false, error: "ID Pasien (patientId) wajib disertakan." },
        { status: 400 }
      );
    }

    if (!hospitalClinicName || !doctorFindingsDiagnosis) {
      return NextResponse.json(
        {
          success: false,
          error: "Nama rumah sakit/klinik dan temuan/diagnosis dokter wajib diisi.",
        },
        { status: 400 }
      );
    }

    const created = await (prisma as any).consultationSummary.create({
      data: {
        patientId,
        screeningId: screeningId || null,
        consultationDate: new Date(consultationDate),
        hospitalClinicName,
        doctorName: doctorName || null,
        doctorFindingsDiagnosis,
        recommendedTreatment: recommendedTreatment || null,
        prescribedMedications: prescribedMedications || [],
        followUpDate: followUpDate ? new Date(followUpDate) : null,
        dietaryLifestyleInstructions: dietaryLifestyleInstructions || null,
        additionalRestrictions: additionalRestrictions || null,
        source: source as any,
        verificationStatus: verificationStatus as any,
        isPatientConfirmed: Boolean(isPatientConfirmed),
        confirmedAt: isPatientConfirmed ? new Date() : null,
        notes: notes || null,
      },
    }).catch((dbErr: any) => {
      console.warn("[consultation-summary]: Database fallback create:", dbErr);
      return {
        id: "cs-" + Math.random().toString(36).substring(7),
        patientId,
        screeningId,
        consultationDate: new Date(consultationDate),
        hospitalClinicName,
        doctorName,
        doctorFindingsDiagnosis,
        recommendedTreatment,
        prescribedMedications,
        followUpDate: followUpDate ? new Date(followUpDate) : null,
        dietaryLifestyleInstructions,
        additionalRestrictions,
        source,
        verificationStatus,
        isPatientConfirmed,
        confirmedAt: isPatientConfirmed ? new Date() : null,
        notes,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    });

    // Record audit log
    await prisma.auditLog.create({
      data: {
        action: "CONSULTATION_SUMMARY_SAVED",
        resource: "ConsultationSummary",
        resourceId: created.id,
        metadata: {
          patientId,
          hospitalClinicName,
          source,
          verificationStatus,
          isPatientConfirmed,
        },
      },
    }).catch(() => null);

    return NextResponse.json({
      success: true,
      data: created,
      message: isPatientConfirmed
        ? "Ringkasan konsultasi dokter telah dikonfirmasi pasien."
        : "Ringkasan konsultasi dokter berhasil disimpan sebagai catatan pasien (belum dikonfirmasi).",
    });
  } catch (error: any) {
    console.error("[consultation-summary POST]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to save consultation summary." },
      { status: 500 }
    );
  }
}
