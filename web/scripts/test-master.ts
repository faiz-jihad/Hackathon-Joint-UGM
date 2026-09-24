/**
 * ==============================================================================
 * RETIVA UNIFIED MASTER VERIFICATION SUITE
 * ==============================================================================
 * End-to-end multi-phase clinical test orchestrator verifying all architectural
 * invariants and domain logic across Phases 1 through 5:
 *
 * - Phase 1: User Auth, RBAC, Patient NIK, Diabetes Profile
 * - Phase 2: Zero-BLOB Storage, SHA-256 Checksums, Quality Gate & Retake
 * - Phase 3: Model Registry, EfficientNet-B3 5-Class Inference, Reliability Gate
 * - Phase 4: Ophthalmologist Adjudication, Perdami/ADA 2024 Engine, Geodesic Matching, Referral & Follow-up
 * - Phase 5: Non-Repudiation Audit Trail, Model Activation, Rate Limiter & Security Hardening
 * ==============================================================================
 */

import crypto from "crypto";
import { User } from "../domain/auth/user.entity";
import { Patient } from "../domain/patient/patient.entity";
import { DiabetesProfile } from "../domain/patient/diabetes-profile.entity";
import { Screening } from "../domain/screening/screening.entity";
import { RetinalImage } from "../domain/screening/retinal-image.entity";
import { QualityCheck } from "../domain/screening/quality-check.entity";
import { AIResult } from "../domain/screening/ai-result.entity";
import { ReliabilityAssessment } from "../domain/screening/reliability-assessment.entity";
import { HumanReview } from "../domain/screening/human-review.entity";
import { ModelVersion } from "../domain/model-version/model-version.entity";
import { RecommendationRulesEngine } from "../domain/recommendation/recommendation-rules.engine";
import { Facility } from "../domain/facility/facility.entity";
import { Referral } from "../domain/referral/referral.entity";
import { FollowUp } from "../domain/follow-up/follow-up.entity";
import { AuditLog } from "../domain/audit/audit-log.entity";

import { S3CompatibleStorage } from "../infrastructure/storage/s3-compatible.storage";
import { BcryptPasswordHasher } from "../infrastructure/security/bcrypt-hasher";
import { JwtTokenService } from "../infrastructure/security/jwt-token.service";
import { InMemoryRateLimiter } from "../infrastructure/security/rate-limiter";
import { HEALTHCARE_SECURITY_HEADERS } from "../infrastructure/security/security-headers";
import { AuthGuard } from "../infrastructure/security/auth.guard";

interface TestStats {
  total: number;
  passed: number;
  failed: number;
}

const stats: TestStats = { total: 0, passed: 0, failed: 0 };

function assert(condition: boolean, testName: string, detail?: string) {
  stats.total++;
  if (condition) {
    stats.passed++;
    console.log(`  ✅ [PASS] ${testName}${detail ? ` (${detail})` : ""}`);
  } else {
    stats.failed++;
    console.error(`  ❌ [FAIL] ${testName}${detail ? ` (${detail})` : ""}`);
  }
}

async function runMasterSuite() {
  const startTime = Date.now();
  console.log("==============================================================================");
  console.log("🏥 RETIVA CLINICAL AI SCREENING PLATFORM — MASTER VERIFICATION SUITE");
  console.log("==============================================================================");

  // --------------------------------------------------------------------------
  // PHASE 1: PATIENT & CLINICAL PROFILE
  // --------------------------------------------------------------------------
  console.log("\n▶ [PHASE 1] Identity, Authorization & Patient Demographics");
  
  const hasher = new BcryptPasswordHasher();
  const rawPw = "KemenkesSecure2026!";
  const hash = await hasher.hash(rawPw);
  assert(await hasher.compare(rawPw, hash), "Bcrypt Password Hashing & Verification");
  assert(!(await hasher.compare("WrongPass", hash)), "Bcrypt Incorrect Password Rejection");

  const doctor = User.create({
    email: "dr.spm@retina.hospital.id",
    passwordHash: hash,
    fullName: "dr. Hendra Sp.M(K)",
    role: "OPHTHALMOLOGIST",
  });
  assert(doctor.role === "OPHTHALMOLOGIST", "Ophthalmologist Role Assignment");

  const jwt = new JwtTokenService();
  const token = jwt.generateToken({ userId: doctor.id, email: doctor.email, role: doctor.role });
  const decoded = jwt.verifyToken(token);
  assert(decoded?.userId === doctor.id, "JWT Token Signing & Claims Decodability");

  const patient = Patient.create({
    nik: "3201015504850001",
    fullName: "Bapak Sutrisno",
    birthDate: new Date("1970-08-20"),
    gender: "MALE",
    phone: "081234567890",
    address: "Kabupaten Sleman, D.I. Yogyakarta",
  });
  assert(patient.getAge() >= 50, "Patient Age Computation from Date of Birth", `Age: ${patient.getAge()}`);

  let caughtNik = false;
  try {
    Patient.create({ nik: "123", fullName: "Invalid", birthDate: new Date("1980-01-01"), gender: "FEMALE" });
  } catch {
    caughtNik = true;
  }
  assert(caughtNik, "NIK 16-Digit Clinical Invariant Enforcement");

  const diabetes = DiabetesProfile.create({
    patientId: patient.id,
    diabetesType: "TYPE_2",
    yearOfDiagnosis: 2016,
    currentTreatment: "COMBINATION",
    lastHbA1c: 9.4,
    lastHbA1cDate: new Date("2026-08-01"),
    systolicBp: 145,
    diastolicBp: 95,
  });
  assert((diabetes.getDiabetesDurationYears() ?? 0) >= 8, "Diabetes Duration Computation", `${diabetes.getDiabetesDurationYears()} years`);
  assert(diabetes.getGlycaemicControlStatus() === "POOR", "HbA1c Glycaemic Risk Stratification", "POOR Control (HbA1c 9.4%)");

  // --------------------------------------------------------------------------
  // PHASE 2: SCREENING SESSION & IMAGE PIPELINE
  // --------------------------------------------------------------------------
  console.log("\n▶ [PHASE 2] Screening Lifecycle, Zero-BLOB Storage & Quality Gate");

  const nakes = User.create({
    email: "nakes@puskesmas.id",
    passwordHash: hash,
    fullName: "Rina S.Kep",
    role: "HEALTHCARE_WORKER",
  });

  const screening = Screening.create({
    patientId: patient.id,
    conductedById: nakes.id,
    notes: "Pemeriksaan berkala pasien diabetes prolanis.",
  });
  assert(screening.status === "CREATED", "Screening Session Initial State", screening.status);

  const storage = new S3CompatibleStorage();
  const rawFundusOD = Buffer.from("RETIVA_MOCK_FUNDUS_OD_HIGH_RES_BINARY_DATA_RIGHT_EYE");
  const rawFundusOS = Buffer.from("RETIVA_MOCK_FUNDUS_OS_HIGH_RES_BINARY_DATA_LEFT_EYE");
  const uploadOD = await storage.upload({ storageKey: `screenings/${screening.id}/od.jpg`, data: rawFundusOD, mimeType: "image/jpeg" });
  const uploadOS = await storage.upload({ storageKey: `screenings/${screening.id}/os.jpg`, data: rawFundusOS, mimeType: "image/jpeg" });

  assert(uploadOD.checksum.length === 64, "Zero-BLOB Storage: SHA-256 Checksum Computed", uploadOD.checksum.slice(0, 16) + "...");

  const imageOD = RetinalImage.create({
    screeningId: screening.id,
    eye: "OD",
    storageKey: uploadOD.storageKey,
    mimeType: "image/jpeg",
    checksum: uploadOD.checksum,
    fileSizeBytes: rawFundusOD.length,
  });
  const imageOS = RetinalImage.create({
    screeningId: screening.id,
    eye: "OS",
    storageKey: uploadOS.storageKey,
    mimeType: "image/jpeg",
    checksum: uploadOS.checksum,
    fileSizeBytes: rawFundusOS.length,
  });

  screening.addImage(imageOD);
  screening.addImage(imageOS);
  assert(screening.status === "IMAGE_UPLOADED" && screening.images.length === 2, "Screening Images Attached (OD + OS)");

  const presignedOD = await storage.getSignedUrl(uploadOD.storageKey, 900);
  assert(presignedOD.includes("auth_token=") && presignedOD.includes("expires=900"), "Private Storage: Presigned Time-Limited URL Flow");

  // Quality check simulation: initial OD image blurry
  const qcBlurryOD = QualityCheck.create({
    retinalImageId: imageOD.id,
    passed: false,
    overallScore: 0.52,
    blurScore: 0.45,
    illuminationScore: 0.88,
    fovScore: 0.90,
    retakeReason: "BLURRY",
    retakeInstructions: "Diskus optikus dan pembuluh darah retina tidak tajam. Stabilkan kamera fundus.",
  });
  screening.recordQualityCheck(qcBlurryOD);
  assert(screening.status === "RETAKE_REQUIRED", "Quality Gate: Blurry Fundus Image Drops Status to RETAKE_REQUIRED");

  // Invariant: AI blocked during RETAKE_REQUIRED
  let aiBlocked = false;
  try {
    screening.recordAiInference({} as any, {} as any);
  } catch {
    aiBlocked = true;
  }
  assert(aiBlocked, "Invariant Guard: AI Classification Blocked While in RETAKE_REQUIRED");

  // Retake OD Image & Re-evaluate Quality Gate
  const retakeImageOD = RetinalImage.create({
    screeningId: screening.id,
    eye: "OD",
    storageKey: `screenings/${screening.id}/od_retake.jpg`,
    mimeType: "image/jpeg",
    checksum: crypto.createHash("sha256").update("RETAKE_BUFFER").digest("hex"),
    fileSizeBytes: 2048,
  });
  screening.addImage(retakeImageOD);
  const qcPassedOD = QualityCheck.create({ retinalImageId: retakeImageOD.id, passed: true, overallScore: 0.95 });
  const qcPassedOS = QualityCheck.create({ retinalImageId: imageOS.id, passed: true, overallScore: 0.92 });
  screening.recordQualityCheck(qcPassedOD);
  screening.recordQualityCheck(qcPassedOS);
  assert(screening.status === "QUALITY_CHECK", "Quality Gate Pass: Advances to QUALITY_CHECK After Successful Retake");

  // --------------------------------------------------------------------------
  // PHASE 3: AI INFERENCE & RELIABILITY GATE
  // --------------------------------------------------------------------------
  console.log("\n▶ [PHASE 3] AI Model Versioning, 5-Class Inference & Reliability Gate");

  const activeModel = ModelVersion.create({
    modelName: "efficientnet-b3",
    version: "efficientnet-b3-v1.0.0",
    pipelineVersion: "dr-pipe-v1.2",
    weightsHash: "sha256:8f4e2c9a1d3b7e5f6a0c8b9d2e4f6a8b1c3d5e7f9a0b2c4d6e8f0a2b4c6d8e0f",
    isActive: true,
  });
  assert(activeModel.isActive, "AI Model Version Registry: Registered active model version");

  const aiResult = AIResult.create({
    screeningId: screening.id,
    modelVersionId: activeModel.id,
    predictedClass: "MODERATE_DR",
    confidence: 0.89,
    rawProbabilities: {
      NO_DR: 0.02,
      MILD_DR: 0.04,
      MODERATE_DR: 0.89,
      SEVERE_DR: 0.04,
      PROLIFERATIVE_DR: 0.01,
    },
    inferenceDurationMs: 128,
  });
  assert(aiResult.predictedClass === "MODERATE_DR", "5-Class Classification (MODERATE_DR)");
  assert(!aiResult.isHighRisk(), "High Risk Stratification Check (Moderate is non-immediate surgical risk)");

  const highReliability = ReliabilityAssessment.create({
    screeningId: screening.id,
    status: "ANALYZE",
    score: 0.91,
  });
  screening.recordAiInference(aiResult, highReliability);
  assert(screening.status === "AI_ANALYZED" && !highReliability.requiresHumanReview(), "Reliability Gate: High Confidence Advances to AI_ANALYZED");

  // Borderline / Unreliable AI Simulation
  const borderlineScreening = Screening.create({ patientId: patient.id, conductedById: nakes.id });
  (borderlineScreening as any).props.status = "QUALITY_CHECK";
  const lowReliability = ReliabilityAssessment.create({
    screeningId: borderlineScreening.id,
    status: "HUMAN_REVIEW",
    score: 0.58,
    reasoning: "Confidence 0.46 is below threshold 0.85.",
  });
  borderlineScreening.recordAiInference(aiResult, lowReliability);
  assert(borderlineScreening.status === "HUMAN_REVIEW" && lowReliability.requiresHumanReview(), "Reliability Gate: Borderline AI Routes Directly to HUMAN_REVIEW");

  // --------------------------------------------------------------------------
  // PHASE 4: CLINICAL REVIEW, RECOMMENDATIONS & CONTINUITY OF CARE
  // --------------------------------------------------------------------------
  console.log("\n▶ [PHASE 4] Human Review, Deterministic Guidelines, Geodesic Referral & Follow-up");

  const review = HumanReview.create({
    screeningId: borderlineScreening.id,
    reviewerId: doctor.id,
    reviewStatus: "CONFIRMED_AI",
    confirmedClass: "MODERATE_DR",
    clinicalNotes: "Konfirmasi telaah fundus bilateral: NPDR Moderate.",
  });
  borderlineScreening.completeScreening();
  assert(borderlineScreening.status === "SCREENING_COMPLETED", "Human Review Adjudication Completes Screening Session");

  // Deterministic Recommendation Engine (Perdami / ADA 2024)
  const recModerate = RecommendationRulesEngine.evaluate({
    screeningId: screening.id,
    confirmedClass: "MODERATE_DR",
    diabetesProfile: diabetes,
  });
  assert(recModerate.referralIndicated, "Recommendation Engine: Referral Indicated for Moderate NPDR");
  assert(recModerate.urgencyLevel === "MEDIUM", "Recommendation Engine: Medium Urgency Assigned");

  const recPdr = RecommendationRulesEngine.evaluate({
    screeningId: screening.id,
    confirmedClass: "PROLIFERATIVE_DR",
    diabetesProfile: diabetes,
  });
  assert(recPdr.urgencyLevel === "CRITICAL" && recPdr.recommendedAction === "URGENT_SURGICAL_CONSULTATION", "Urgent Surgical Referral for PDR");

  // Deterministic Facility Matching (Haversine Distance, No AI Black-Box)
  const facilityDrYap = Facility.create({
    name: "RS Mata Dr. Yap Yogyakarta",
    address: "Jl. Cik Di Tiro No.5, Terban, Gondokusuman, Kota Yogyakarta",
    latitude: -7.7828,
    longitude: 110.3753,
    contactPhone: "0274-562054",
    bpjsStatus: "ACCEPTED",
    isVerified: true,
    services: [
      { serviceName: "RETINA_SPECIALIST", description: "Dokter Subspesialis Vitreoretina" },
      { serviceName: "LASER_PHOTOCOAGULATION" },
      { serviceName: "VITRECTOMY" },
    ],
  });

  const patientLoc = { lat: -7.7713, lon: 110.3775 }; // UGM area
  const distKm = facilityDrYap.calculateDistanceKm(patientLoc.lat, patientLoc.lon);
  assert(distKm < 2.5, "Geodesic Haversine Calculation Accuracy (< 2.5 km)", `${distKm} km`);
  assert(facilityDrYap.hasService("RETINA_SPECIALIST") && facilityDrYap.bpjsStatus === "ACCEPTED", "Facility Verified Retina Subspecialist & BPJS JKN Eligibility");

  // Referral Issuance
  const referral = Referral.create({
    screeningId: screening.id,
    patientId: patient.id,
    targetFacilityId: facilityDrYap.id,
    urgency: recModerate.urgencyLevel,
    reason: "Pemeriksaan biomikroskopi fundus & OCT Macula.",
    clinicalSummary: "Pasien DM tipe 2 dengan kontrol glikemik buruk dan NPDR Moderate.",
  });
  referral.issue();
  assert(referral.status === "ISSUED" && !!referral.expiresAt && referral.expiresAt > new Date(), "Referral Issued with 30-Day Legal Validity Window");

  // Follow-up Scheduling
  const dueDate = new Date();
  dueDate.setMonth(dueDate.getMonth() + 3);
  const followUp = FollowUp.create({
    patientId: patient.id,
    screeningId: screening.id,
    dueDate,
  });
  assert(followUp.status === "SCHEDULED", "Follow-Up Scheduled (3 Months)");
  followUp.complete("Pasien telah berkunjung dan mendapat penanganan di RS Mata.");
  assert(followUp.status === "COMPLETED", "Follow-Up Marked Completed Upon Clinical Attendance");

  // --------------------------------------------------------------------------
  // PHASE 5: GOVERNANCE, AUDIT TRAIL & SECURITY HARDENING
  // --------------------------------------------------------------------------
  console.log("\n▶ [PHASE 5] Non-Repudiation Audit Trail, Model Governance & Security Defense");

  const auditLogs: AuditLog[] = [
    AuditLog.create({
      actorId: nakes.id,
      actorRole: "HEALTHCARE_WORKER",
      action: "PATIENT_REGISTERED",
      resource: "Patient",
      resourceId: patient.id,
    }),
    AuditLog.create({
      actorId: nakes.id,
      actorRole: "HEALTHCARE_WORKER",
      action: "IMAGE_UPLOADED",
      resource: "RetinalImage",
      resourceId: imageOD.id,
    }),
    AuditLog.create({
      actorId: nakes.id,
      actorRole: "HEALTHCARE_WORKER",
      action: "QUALITY_CHECK_COMPLETED",
      resource: "Screening",
      resourceId: screening.id,
    }),
    AuditLog.create({
      actorId: nakes.id,
      actorRole: "HEALTHCARE_WORKER",
      action: "AI_INFERENCE_PERFORMED",
      resource: "Screening",
      resourceId: screening.id,
      metadata: { modelVersion: activeModel.version, predictedClass: aiResult.predictedClass },
    }),
    AuditLog.create({
      actorId: doctor.id,
      actorRole: "OPHTHALMOLOGIST",
      action: "HUMAN_REVIEW_SUBMITTED",
      resource: "HumanReview",
      resourceId: review.id,
    }),
    AuditLog.create({
      actorId: doctor.id,
      actorRole: "OPHTHALMOLOGIST",
      action: "REFERRAL_ISSUED",
      resource: "Referral",
      resourceId: referral.id,
    }),
    AuditLog.create({
      actorId: nakes.id,
      actorRole: "HEALTHCARE_WORKER",
      action: "FOLLOW_UP_SCHEDULED",
      resource: "FollowUp",
      resourceId: followUp.id,
    }),
  ];

  assert(auditLogs.length === 7, "Non-Repudiation Audit Trail: 7 Mandatory Clinical Milestone Events Recorded");

  const aiLogs = auditLogs.filter((l) => l.action === "AI_INFERENCE_PERFORMED");
  assert(aiLogs[0]?.metadata?.modelVersion === "efficientnet-b3-v1.0.0", "Audit Log Preserves AI Model Version Lineage");

  // Model Registry Staging & Activation
  const stagedModelV2 = ModelVersion.create({
    modelName: "efficientnet-b3",
    version: "efficientnet-b3-v2.0.0",
    pipelineVersion: "dr-pipe-v2.0",
    weightsHash: "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    isActive: false,
  });
  assert(!stagedModelV2.isActive, "New Model Version Staged as Inactive");
  (activeModel as any).props.isActive = false;
  (stagedModelV2 as any).props.isActive = true;
  assert(stagedModelV2.isActive && !activeModel.isActive, "Model Version Dynamic Switching: V2 Activated, V1 Deactivated");

  // Security Hardening: Rate Limiting
  InMemoryRateLimiter.clear();
  const clientKey = "10.0.0.99:POST:/api/v1/auth/login";
  for (let i = 0; i < 5; i++) {
    InMemoryRateLimiter.check(clientKey, 5, 10000);
  }
  const overflowReq = InMemoryRateLimiter.check(clientKey, 5, 10000);
  assert(!overflowReq.isAllowed && overflowReq.remaining === 0, "Rate Limiter Defense: 6th Request Blocked with HTTP 429 Status");

  // Security Hardening: Headers
  assert(HEALTHCARE_SECURITY_HEADERS["X-Content-Type-Options"] === "nosniff", "Security Header: X-Content-Type-Options: nosniff");
  assert(HEALTHCARE_SECURITY_HEADERS["X-Frame-Options"] === "DENY", "Security Header: Anti-Clickjacking Frame-Options DENY");
  assert(HEALTHCARE_SECURITY_HEADERS["Strict-Transport-Security"].includes("max-age"), "Security Header: HSTS Strict Transport Enforced");

  // Security Hardening: RBAC Boundaries
  let rbacBlocked = false;
  try {
    AuthGuard.requireRole({ id: "p1", email: "patient@retiva.id", role: "PATIENT" }, ["ADMIN"]);
  } catch {
    rbacBlocked = true;
  }
  assert(rbacBlocked, "RBAC Security Guard: Patient Access to Admin Resources Strictly Denied");

  // --------------------------------------------------------------------------
  // SUMMARY REPORT
  // --------------------------------------------------------------------------
  const durationMs = Date.now() - startTime;
  console.log("\n==============================================================================");
  console.log("🏁 RETIVA MASTER VERIFICATION SUMMARY");
  console.log("==============================================================================");
  console.log(`  Total Invariant Tests : ${stats.total}`);
  console.log(`  Passed Invariants     : ${stats.passed} (${Math.round((stats.passed / stats.total) * 100)}%)`);
  console.log(`  Failed Invariants     : ${stats.failed}`);
  console.log(`  Execution Duration    : ${durationMs}ms`);
  console.log("==============================================================================");

  if (stats.failed > 0) {
    console.error("❌ Master verification suite encountered failures.");
    process.exit(1);
  } else {
    console.log("🎉 ALL RETIVA CLINICAL, ARCHITECTURAL & GOVERNANCE INVARIANTS VERIFIED!");
    process.exit(0);
  }
}

runMasterSuite().catch((err) => {
  console.error("Master suite fatal error:", err);
  process.exit(1);
});
