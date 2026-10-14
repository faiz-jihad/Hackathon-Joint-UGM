import { NextRequest } from "next/server";
import { EmergencyStore, EmergencyIncidentDto } from "@/infrastructure/database/emergency-store";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    start(controller) {
      // Send initial heartbeat
      controller.enqueue(encoder.encode(`data: ${JSON.stringify({ type: "CONNECTED", timestamp: new Date().toISOString() })}\n\n`));

      // Subscribe to EmergencyStore broadcasts
      const unsubscribe = EmergencyStore.subscribe((incident: EmergencyIncidentDto) => {
        try {
          const payload = JSON.stringify({
            type: "INCIDENT_UPDATE",
            incident,
            timestamp: new Date().toISOString(),
          });
          controller.enqueue(encoder.encode(`data: ${payload}\n\n`));
        } catch (err) {
          console.error("SSE stream enqueue error:", err);
        }
      });

      // Heartbeat interval to prevent socket timeout
      const intervalId = setInterval(() => {
        try {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ type: "HEARTBEAT", timestamp: new Date().toISOString() })}\n\n`));
        } catch {
          clearInterval(intervalId);
          unsubscribe();
        }
      }, 15000);

      req.signal.addEventListener("abort", () => {
        clearInterval(intervalId);
        unsubscribe();
        try {
          controller.close();
        } catch {
          // Stream already closed
        }
      });
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
    },
  });
}
