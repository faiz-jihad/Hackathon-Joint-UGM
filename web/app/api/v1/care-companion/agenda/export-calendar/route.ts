import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const title = searchParams.get("title") || "Aktivitas Sehat Retiva";
    const details = searchParams.get("details") || "Pengingat perawatan mandiri diabetes & retinopati dari Retiva";
    const dateStr = searchParams.get("date") || new Date().toISOString().split("T")[0];
    const timeStr = searchParams.get("time") || "08:00";
    const format = searchParams.get("format") || "google";

    // Format ISO Dates for Calendar: YYYYMMDDTHHMMSS
    const [hours, minutes] = timeStr.split(":");
    const startDateTime = new Date(`${dateStr}T${hours || "08"}:${minutes || "00"}:00`);
    const endDateTime = new Date(startDateTime.getTime() + 30 * 60 * 1000); // 30 mins

    const formatCalDate = (d: Date) =>
      d.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";

    const dtStart = formatCalDate(startDateTime);
    const dtEnd = formatCalDate(endDateTime);

    if (format === "ics") {
      const uid = `retiva-${Date.now()}@retiva.health`;
      const icsContent = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Retiva Healthcare//Daily Care Agenda//ID",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "BEGIN:VEVENT",
        `UID:${uid}`,
        `DTSTAMP:${formatCalDate(new Date())}`,
        `DTSTART:${dtStart}`,
        `DTEND:${dtEnd}`,
        `SUMMARY:${title}`,
        `DESCRIPTION:${details}`,
        "LOCATION:Rumah / Faskes Terdekat",
        "STATUS:CONFIRMED",
        "BEGIN:VALARM",
        "TRIGGER:-PT15M",
        "ACTION:DISPLAY",
        `DESCRIPTION:Pengingat: ${title}`,
        "END:VALARM",
        "END:VEVENT",
        "END:VCALENDAR",
      ].join("\r\n");

      return new NextResponse(icsContent, {
        status: 200,
        headers: {
          "Content-Type": "text/calendar; charset=utf-8",
          "Content-Disposition": `attachment; filename="retiva-agenda-${dateStr}.ics"`,
        },
      });
    }

    // Default: Google Calendar Web URL Link
    const googleCalUrl = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(
      title
    )}&dates=${dtStart}/${dtEnd}&details=${encodeURIComponent(
      details
    )}&location=${encodeURIComponent("Rumah / Mandiri")}`;

    return NextResponse.json({
      success: true,
      data: {
        googleCalendarUrl: googleCalUrl,
        title,
        dtStart,
        dtEnd,
      },
    });
  } catch (error: any) {
    console.error("[export-calendar GET]:", error);
    return NextResponse.json(
      { success: false, error: error?.message || "Failed to generate calendar event." },
      { status: 500 }
    );
  }
}
