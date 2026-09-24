import {
  NotificationService,
  SendNotificationDTO,
  NotificationResult,
} from "@/domain/notification/notification.interface";
import crypto from "crypto";

/**
 * MockNotificationService
 * Provider-agnostic notification adapter. Logs notifications safely without exposing credentials.
 */
export class MockNotificationService implements NotificationService {
  async send(dto: SendNotificationDTO): Promise<NotificationResult> {
    const id = crypto.randomUUID();
    console.log(
      `[NotificationService Mock]: Delivered ${dto.channel} notification to user ${dto.userId}: "${dto.title}"`
    );

    return {
      id,
      success: true,
      channel: dto.channel,
      deliveredAt: new Date(),
      providerReference: `MOCK-${dto.channel}-${Date.now()}`,
    };
  }
}
