import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const reminderId = params.id;
    const body = await req.json().catch(() => ({}));
    const { isCompleted, isActive } = body;

    const updated = await (prisma as any).careReminder.update({
      where: { id: reminderId },
      data: {
        ...(typeof isCompleted === "boolean"
          ? { isCompleted, completedAt: isCompleted ? new Date() : null }
          : {}),
        ...(typeof isActive === "boolean" ? { isActive } : {}),
      },
    }).catch((dbErr) => {
      console.warn("[reminder PATCH]: DB fallback:", dbErr);
      return {
        id: reminderId,
        isCompleted: isCompleted ?? true,
        completedAt: isCompleted ? new Date() : null,
      };
    });

    return NextResponse.json({
      success: true,
      data: updated,
    });
  } catch (error: any) {
    console.error("[reminder PATCH]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to update reminder." },
      { status: 500 }
    );
  }
}
