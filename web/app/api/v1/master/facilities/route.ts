import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";
import { BPJSStatus } from "@prisma/client";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const search = searchParams.get("search")?.toLowerCase().trim() || "";
    const category = searchParams.get("category") || "ALL"; // ALL | FKTP | FKRTL
    const bpjsStatus = searchParams.get("bpjsStatus") || "ALL";

    const allFacilities = await prisma.facility.findMany({
      include: {
        services: true,
        insurances: true,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    const enriched = allFacilities.map((f) => {
      const isFKTP =
        f.name.toLowerCase().includes("puskesmas") ||
        f.name.toLowerCase().includes("klinik") ||
        f.name.toLowerCase().includes("fktp");
      return {
        id: f.id,
        name: f.name,
        category: isFKTP ? "FKTP" : "FKRTL",
        categoryLabel: isFKTP
          ? "FKTP (Fasilitas Tingkat Pertama)"
          : "FKRTL (Faskes Rujukan Tingkat Lanjut)",
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        bpjsStatus: f.bpjsStatus,
        isVerified: f.isVerified,
        contactPhone: f.contactPhone || "-",
        services: f.services.map((s) => s.serviceName),
        insurances: f.insurances.map((i) => i.insuranceName),
        createdAt: f.createdAt.toISOString(),
        updatedAt: f.updatedAt.toISOString(),
      };
    });

    let filtered = enriched;

    if (category !== "ALL") {
      filtered = filtered.filter((f) => f.category === category);
    }

    if (bpjsStatus !== "ALL") {
      filtered = filtered.filter((f) => f.bpjsStatus === bpjsStatus);
    }

    if (search) {
      filtered = filtered.filter(
        (f) =>
          f.name.toLowerCase().includes(search) ||
          f.address.toLowerCase().includes(search) ||
          f.services.some((s) => s.toLowerCase().includes(search)) ||
          f.contactPhone.toLowerCase().includes(search)
      );
    }

    return NextResponse.json({
      success: true,
      count: filtered.length,
      total: allFacilities.length,
      data: filtered,
    });
  } catch (error: any) {
    console.error("GET /api/v1/master/facilities error:", error);
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch master facilities" },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      name,
      address,
      category = "FKRTL",
      latitude,
      longitude,
      bpjsStatus = "ACCEPTED",
      isVerified = true,
      contactPhone = "",
      services = [],
      insurances = ["BPJS_KESEHATAN"],
    } = body;

    if (!name || !address) {
      return NextResponse.json(
        { success: false, error: "Nama faskes dan alamat lengkap wajib diisi." },
        { status: 400 }
      );
    }

    const customId =
      body.id ||
      `fac-${name
        .toLowerCase()
        .replace(/[^a-z0-9]/g, "-")
        .slice(0, 15)}-${Date.now().toString().slice(-4)}`;

    let bpjsEnum: BPJSStatus = BPJSStatus.ACCEPTED;
    if (bpjsStatus === "NOT_AVAILABLE") bpjsEnum = BPJSStatus.NOT_AVAILABLE;
    if (bpjsStatus === "NEEDS_CONFIRMATION") bpjsEnum = BPJSStatus.NEEDS_CONFIRMATION;

    const lat = typeof latitude === "number" ? latitude : parseFloat(latitude) || -7.7828;
    const lng = typeof longitude === "number" ? longitude : parseFloat(longitude) || 110.3671;

    const newFacility = await prisma.facility.create({
      data: {
        id: customId,
        name: name.trim(),
        address: address.trim(),
        latitude: lat,
        longitude: lng,
        bpjsStatus: bpjsEnum,
        isVerified: Boolean(isVerified),
        contactPhone: contactPhone ? contactPhone.trim() : null,
      },
    });

    // Create services
    const serviceList = Array.isArray(services) ? services : [];
    for (const s of serviceList) {
      if (s && typeof s === "string") {
        await prisma.facilityService.create({
          data: {
            facilityId: newFacility.id,
            serviceName: s.trim().toUpperCase().replace(/\s+/g, "_"),
          },
        });
      }
    }

    // Create insurances
    const insList = Array.isArray(insurances) ? insurances : ["BPJS_KESEHATAN"];
    for (const ins of insList) {
      if (ins && typeof ins === "string") {
        await prisma.facilityInsurance.create({
          data: {
            facilityId: newFacility.id,
            insuranceName: ins.trim().toUpperCase().replace(/\s+/g, "_"),
            status: "ACTIVE",
          },
        });
      }
    }

    const result = await prisma.facility.findUnique({
      where: { id: newFacility.id },
      include: { services: true, insurances: true },
    });

    return NextResponse.json(
      {
        success: true,
        message: "Fasilitas kesehatan berhasil ditambahkan ke master data.",
        data: result,
      },
      { status: 201 }
    );
  } catch (error: any) {
    console.error("POST /api/v1/master/facilities error:", error);
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create master facility" },
      { status: 500 }
    );
  }
}
