import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { BPJSStatus } from "@prisma/client";

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await req.json();
    const {
      name,
      address,
      latitude,
      longitude,
      bpjsStatus,
      isVerified,
      contactPhone,
      services,
      insurances,
    } = body;

    const existing = await prisma.facility.findUnique({
      where: { id },
    });

    if (!existing) {
      return NextResponse.json(
        { success: false, error: "Fasilitas kesehatan tidak ditemukan." },
        { status: 404 }
      );
    }

    let bpjsEnum: BPJSStatus | undefined = undefined;
    if (bpjsStatus === "ACCEPTED") bpjsEnum = BPJSStatus.ACCEPTED;
    else if (bpjsStatus === "NOT_AVAILABLE") bpjsEnum = BPJSStatus.NOT_AVAILABLE;
    else if (bpjsStatus === "NEEDS_CONFIRMATION") bpjsEnum = BPJSStatus.NEEDS_CONFIRMATION;

    const updated = await prisma.facility.update({
      where: { id },
      data: {
        name: name !== undefined ? name.trim() : undefined,
        address: address !== undefined ? address.trim() : undefined,
        latitude: latitude !== undefined ? parseFloat(latitude) : undefined,
        longitude: longitude !== undefined ? parseFloat(longitude) : undefined,
        bpjsStatus: bpjsEnum,
        isVerified: isVerified !== undefined ? Boolean(isVerified) : undefined,
        contactPhone: contactPhone !== undefined ? (contactPhone ? contactPhone.trim() : null) : undefined,
      },
    });

    if (Array.isArray(services)) {
      await prisma.facilityService.deleteMany({ where: { facilityId: id } });
      for (const s of services) {
        if (s && typeof s === "string") {
          await prisma.facilityService.create({
            data: {
              facilityId: id,
              serviceName: s.trim().toUpperCase().replace(/\s+/g, "_"),
            },
          });
        }
      }
    }

    if (Array.isArray(insurances)) {
      await prisma.facilityInsurance.deleteMany({ where: { facilityId: id } });
      for (const ins of insurances) {
        if (ins && typeof ins === "string") {
          await prisma.facilityInsurance.create({
            data: {
              facilityId: id,
              insuranceName: ins.trim().toUpperCase().replace(/\s+/g, "_"),
              status: "ACTIVE",
            },
          });
        }
      }
    }

    const finalResult = await prisma.facility.findUnique({
      where: { id },
      include: { services: true, insurances: true },
    });

    return NextResponse.json({
      success: true,
      message: "Data fasilitas kesehatan berhasil diperbarui.",
      data: finalResult,
    });
  } catch (error: any) {
    console.error("PUT /api/v1/master/facilities/[id] error:", error);
    return NextResponse.json(
      { success: false, error: error.message || "Failed to update facility" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;

    const existing = await prisma.facility.findUnique({
      where: { id },
    });

    if (!existing) {
      return NextResponse.json(
        { success: false, error: "Fasilitas kesehatan tidak ditemukan." },
        { status: 404 }
      );
    }

    // Delete related services & insurances first
    await prisma.facilityService.deleteMany({ where: { facilityId: id } });
    await prisma.facilityInsurance.deleteMany({ where: { facilityId: id } });

    // Nullify facilityId in users to prevent foreign key errors
    await prisma.user.updateMany({
      where: { facilityId: id },
      data: { facilityId: null },
    });

    await prisma.facility.delete({
      where: { id },
    });

    return NextResponse.json({
      success: true,
      message: `Fasilitas kesehatan ${existing.name} berhasil dihapus dari master data.`,
    });
  } catch (error: any) {
    console.error("DELETE /api/v1/master/facilities/[id] error:", error);
    return NextResponse.json(
      { success: false, error: error.message || "Failed to delete facility" },
      { status: 500 }
    );
  }
}
