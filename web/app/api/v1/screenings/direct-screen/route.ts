import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const aiServiceUrl = process.env.AI_SERVICE_URL || "http://localhost:8003";
    const contentType = req.headers.get("content-type") || "";

    if (contentType.includes("multipart/form-data")) {
      const incomingFormData = await req.formData();
      const imageFile = incomingFormData.get("image") || incomingFormData.get("file");
      const screeningId = incomingFormData.get("screening_id") || incomingFormData.get("screeningId");

      if (!imageFile || !(imageFile instanceof Blob)) {
        return NextResponse.json(
          {
            error: {
              code: "INVALID_IMAGE",
              message: "Form field 'image' or 'file' is required and must contain an image file.",
            },
          },
          { status: 400 }
        );
      }

      // Forward to FastAPI AI Service
      const outboundFormData = new FormData();
      outboundFormData.append("image", imageFile);
      if (screeningId) {
        outboundFormData.append("screening_id", String(screeningId));
      }

      const res = await fetch(`${aiServiceUrl}/api/v1/screen`, {
        method: "POST",
        headers: {
          "X-Internal-Secret": process.env.AI_INTERNAL_SECRET || "retiva-internal-secret-token",
        },
        body: outboundFormData,
      });

      if (!res.ok) {
        const errorJson = await res.json().catch(() => null);
        return NextResponse.json(
          errorJson || {
            error: {
              code: "AI_SERVICE_ERROR",
              message: `AI service returned error status: ${res.statusText}`,
            },
          },
          { status: res.status }
        );
      }

      const data = await res.json();
      return NextResponse.json(data);
    }

    if (contentType.includes("application/json")) {
      const body = await req.json();
      const res = await fetch(`${aiServiceUrl}/api/v1/screen`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Internal-Secret": process.env.AI_INTERNAL_SECRET || "retiva-internal-secret-token",
        },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const errorJson = await res.json().catch(() => null);
        return NextResponse.json(
          errorJson || {
            error: {
              code: "AI_SERVICE_ERROR",
              message: `AI service returned error status: ${res.statusText}`,
            },
          },
          { status: res.status }
        );
      }

      const data = await res.json();
      return NextResponse.json(data);
    }

    return NextResponse.json(
      {
        error: {
          code: "UNSUPPORTED_MEDIA_TYPE",
          message: "Request must be multipart/form-data or application/json.",
        },
      },
      { status: 400 }
    );
  } catch (error: any) {
    console.error("[direct-screen route]: Error calling AI service:", error);
    return NextResponse.json(
      {
        error: {
          code: "INTERNAL_SERVER_ERROR",
          message: error?.message || "Failed to process retinal screening request.",
        },
      },
      { status: 500 }
    );
  }
}
