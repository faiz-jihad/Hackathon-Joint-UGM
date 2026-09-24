/**
 * Notification Port Abstraction
 * Supports In-App, WhatsApp, SMS, and Email notification delivery without vendor lock-in.
 */

export type NotificationChannelType = "IN_APP" | "WHATSAPP" | "SMS" | "EMAIL";

export interface SendNotificationDTO {
  userId: string;
  channel: NotificationChannelType;
  title: string;
  message: string;
  recipientPhone?: string | null;
  recipientEmail?: string | null;
  payload?: Record<string, any>;
}

export interface NotificationResult {
  id: string;
  success: boolean;
  channel: NotificationChannelType;
  deliveredAt: Date;
  providerReference?: string | null;
}

export interface NotificationService {
  send(dto: SendNotificationDTO): Promise<NotificationResult>;
}
