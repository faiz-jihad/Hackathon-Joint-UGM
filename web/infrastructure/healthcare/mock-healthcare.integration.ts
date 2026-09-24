import {
  HealthcareIntegrationAdapter,
  ScreeningObservationPayload,
  HealthcareSyncResult,
} from "@/domain/healthcare/healthcare-integration.interface";

/**
 * MockHealthcareIntegration
 * Provider-agnostic mock adapter for local testing and initial prototype deployment.
 */
export class MockHealthcareIntegration implements HealthcareIntegrationAdapter {
  async verifyPatientIHS(nik: string): Promise<string | null> {
    // Generates simulated SATUSEHAT IHS number deterministically from NIK
    if (nik.length === 16) {
      return `IHS-P-${nik.slice(0, 10)}`;
    }
    return null;
  }

  async sendScreeningObservation(
    payload: ScreeningObservationPayload
  ): Promise<HealthcareSyncResult> {
    console.log(`[Healthcare Integration Mock]: Dispatched observation for screening ${payload.screeningId} (Class: ${payload.findingClass})`);
    return {
      success: true,
      externalTransactionId: `SATUSEHAT-OBS-${Date.now()}`,
      syncedAt: new Date(),
      message: "Observation successfully recorded in local interoperability mock.",
    };
  }
}
