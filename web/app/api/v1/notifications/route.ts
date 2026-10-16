import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/infrastructure/database/prisma/client";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("userId");
    const limit = parseInt(searchParams.get("limit") || "20", 10);

    const whereClause: any = {};
    if (userId) {
      whereClause.userId = userId;
    }

    const notifications = await prisma.notification.findMany({
      where: whereClause,
      orderBy: { createdAt: "desc" },
      take: limit,
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            role: true,
          },
        },
      },
    });

    return NextResponse.json({
      success: true,
      data: notifications,
      total: notifications.length,
    });
  } catch (error: any) {
    console.error("Error fetching notifications:", error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to fetch notifications from database",
        details: error?.message,
      },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { userId, title, message, channel = "IN_APP", payload } = body;

    if (!title || !message) {
      return NextResponse.json(
        { success: false, error: "Title and message are required" },
        { status: 400 }
      );
    }

    // Default to the first available user if userId is not provided
    let targetUserId = userId;
    if (!targetUserId) {
      const firstUser = await prisma.user.findFirst({ select: { id: true } });
      if (firstUser) {
        targetUserId = firstUser.id;
      }
    }

    if (!targetUserId) {
      return NextResponse.json(
        { success: false, error: "No user available to assign notification" },
        { status: 400 }
      );
    }

    const notification = await prisma.notification.create({
      data: {
        userId: targetUserId,
        title,
        message,
        channel,
        status: "PENDING",
        payload: payload ?? {},
      },
    });

    return NextResponse.json(
      { success: true, data: notification },
      { status: 201 }
    );
  } catch (error: any) {
    console.error("Error creating notification:", error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to save notification to database",
        details: error?.message,
      },
      { status: 500 }
    );
  }
}
