import { PrismaUserRepository } from "@/infrastructure/database/repositories/prisma-user.repository";
import { PrismaPatientRepository } from "@/infrastructure/database/repositories/prisma-patient.repository";
import { PrismaDiabetesProfileRepository } from "@/infrastructure/database/repositories/prisma-diabetes-profile.repository";
import { PrismaScreeningRepository } from "@/infrastructure/database/repositories/prisma-screening.repository";
import { PrismaAuditRepository } from "@/infrastructure/database/repositories/prisma-audit.repository";
import { PrismaModelVersionRepository } from "@/infrastructure/database/repositories/prisma-model-version.repository";
import { PrismaFacilityRepository } from "@/infrastructure/database/repositories/prisma-facility.repository";
import { PrismaReferralRepository } from "@/infrastructure/database/repositories/prisma-referral.repository";
import { PrismaFollowUpRepository } from "@/infrastructure/database/repositories/prisma-follow-up.repository";

import { S3CompatibleStorage } from "@/infrastructure/storage/s3-compatible.storage";
import { FastAPIAIClient } from "@/infrastructure/ai/fastapi-ai.client";
import { BcryptPasswordHasher } from "@/infrastructure/security/bcrypt-hasher";
import { JwtTokenService } from "@/infrastructure/security/jwt-token.service";
import { MockHealthcareIntegration } from "@/infrastructure/healthcare/mock-healthcare.integration";
import { MockNotificationService } from "@/infrastructure/notifications/mock-notification.service";

import { AuthService } from "@/application/auth/auth.service";
import { PatientService } from "@/application/patient/patient.service";
import { DiabetesProfileService } from "@/application/patient/diabetes-profile.service";
import { ScreeningService } from "@/application/screening/screening.service";
import { HumanReviewService } from "@/application/review/human-review.service";
import { RecommendationService } from "@/application/recommendation/recommendation.service";
import { FacilityService } from "@/application/facility/facility.service";
import { ReferralService } from "@/application/referral/referral.service";
import { FollowUpService } from "@/application/follow-up/follow-up.service";
import { ModelVersionService } from "@/application/model/model-version.service";

// Infrastructure singletons (Adapters)
export const userRepository = new PrismaUserRepository();
export const patientRepository = new PrismaPatientRepository();
export const diabetesProfileRepository = new PrismaDiabetesProfileRepository();
export const screeningRepository = new PrismaScreeningRepository();
export const auditRepository = new PrismaAuditRepository();
export const modelVersionRepository = new PrismaModelVersionRepository();
export const facilityRepository = new PrismaFacilityRepository();
export const referralRepository = new PrismaReferralRepository();
export const followUpRepository = new PrismaFollowUpRepository();

export const imageStorage = new S3CompatibleStorage();
export const aiClient = new FastAPIAIClient();
export const passwordHasher = new BcryptPasswordHasher();
export const tokenService = new JwtTokenService();
export const healthcareIntegration = new MockHealthcareIntegration();
export const notificationService = new MockNotificationService();

// Application use-cases
export const authService = new AuthService(userRepository, passwordHasher, tokenService);
export const patientService = new PatientService(patientRepository);
export const diabetesProfileService = new DiabetesProfileService(diabetesProfileRepository, patientRepository);
export const screeningService = new ScreeningService(
  screeningRepository,
  patientRepository,
  modelVersionRepository,
  imageStorage,
  aiClient,
  auditRepository
);

export const humanReviewService = new HumanReviewService(
  screeningRepository,
  diabetesProfileRepository,
  auditRepository
);

export const recommendationService = new RecommendationService(
  screeningRepository,
  diabetesProfileRepository
);

export const facilityService = new FacilityService(facilityRepository);

export const referralService = new ReferralService(
  referralRepository,
  facilityRepository,
  patientRepository,
  screeningRepository,
  auditRepository
);

export const followUpService = new FollowUpService(
  followUpRepository,
  patientRepository,
  screeningRepository,
  referralRepository,
  diabetesProfileRepository,
  auditRepository
);

export const modelVersionService = new ModelVersionService(
  modelVersionRepository,
  auditRepository
);
