import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    service: "retiva-web-core-api",
    version: "1.0.0",
    compliance: {
      permenkes_24_2022: true,
      uu_pdp_27_2022: true,
      zero_blob_storage: true,
    },
  });
}
