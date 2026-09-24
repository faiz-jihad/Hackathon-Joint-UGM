/**
 * Healthcare Integration Abstraction Port
 * Ensures RETIVA is 100% provider-agnostic and ready for future SATUSEHAT / FHIR / JKN integration.
 * DO NOT create fake or unauthorized direct integrations.
 */

export interface PatientDemographicsSync {
  nik: string;
  fullName: string;
  birthDate: Date;
  gender: string;
  ihsNumber?: string | null; // SATUSEHAT SatuSehat ID
}

export interface ScreeningObservationPayload {
  screeningId: string;
  patientIhsNumber?: string | null;
  encounterId?: string | null;
  status: string;
  findingClass: string;
  confidence: number;
  performedAt: Date;
  performerId: string;
}

export interface HealthcareSyncResult {
  success: boolean;
  externalTransactionId?: string | null;
  syncedAt: Date;
  message?: string;
}

export interface HealthcareIntegrationAdapter {
  verifyPatientIHS(nik: string): Promise<string | null>;
  sendScreeningObservation(payload: ScreeningObservationPayload): Promise<HealthcareSyncResult>;
}
