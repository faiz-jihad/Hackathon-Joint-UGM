import { NextRequest, NextResponse } from "next/server";
import { EmergencyStore } from "@/infrastructure/database/emergency-store";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    let patientId = searchParams.get("patientId");

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "patient-demo-01";
    }

    const contacts = await EmergencyStore.getContactsByPatientId(patientId);

    return NextResponse.json({
      success: true,
      data: contacts,
    });
  } catch (error: any) {
    console.error("[api/sos/contacts] GET Error:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal mengambil daftar kontak darurat." },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    let { patientId, name, relationship, phoneNumber, isPrimary, preferredChannel } = body;

    if (!name || !phoneNumber) {
      return NextResponse.json(
        { success: false, error: "Nama dan nomor telepon kontak darurat wajib diisi." },
        { status: 400 }
      );
    }

    if (!patientId) {
      const firstPatient = await prisma.patient.findFirst().catch(() => null);
      patientId = firstPatient?.id || "patient-demo-01";
    }

    const contact = await EmergencyStore.createContact({
      patientId,
      name,
      relationship: relationship || "Keluarga",
      phoneNumber,
      isPrimary: Boolean(isPrimary),
      isVerified: true,
      preferredChannel: preferredChannel || "WHATSAPP",
    });

    return NextResponse.json({
      success: true,
      message: "Kontak darurat berhasil ditambahkan.",
      data: contact,
    });
  } catch (error: any) {
    console.error("[api/sos/contacts] POST Error:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal menyimpan kontak darurat." },
      { status: 500 }
    );
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json(
        { success: false, error: "ID kontak darurat wajib disertakan." },
        { status: 400 }
      );
    }

    await EmergencyStore.deleteContact(id);

    return NextResponse.json({
      success: true,
      message: "Kontak darurat berhasil dihapus.",
    });
  } catch (error: any) {
    console.error("[api/sos/contacts] DELETE Error:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Gagal menghapus kontak darurat." },
      { status: 500 }
    );
  }
}
