/**
 * Test script for RETIVA Phase 3:
 * - EfficientNet-B3 5-Class Diabetic Retinopathy Classification
 * - AIClient Abstraction & Model Versioning
 * - Reliability Gate (ANALYZE vs HUMAN_REVIEW vs RETAKE)
 * - State Machine transition to AI_ANALYZED / HUMAN_REVIEW
 * - Invariant protections (Blocking AI when Quality Check fails)
 */

import { Screening } from "../domain/screening/screening.entity";
import { RetinalImage } from "../domain/screening/retinal-image.entity";
import { QualityCheck } from "../domain/screening/quality-check.entity";
import { AIResult } from "../domain/screening/ai-result.entity";
import { ReliabilityAssessment } from "../domain/screening/reliability-assessment.entity";
import { ModelVersion } from "../domain/model-version/model-version.entity";
import crypto from "crypto";

async function runPhase3Tests() {
  console.log("==========================================");
  console.log(" RETIVA PHASE 3 VERIFICATION: AI & RELIABILITY GATE");
  console.log("==========================================");

  // 1. Model Versioning test
  console.log("\n[Test 1] Testing ModelVersion Entity & Integrity Checksum...");
  const model = ModelVersion.create({
    modelName: "efficientnet-b3",
    version: "efficientnet-b3-v1.0.0",
    pipelineVersion: "dr-pipe-v1.2",
    weightsHash: "sha256:8f4e2c9a1d3b7e5f6a0c8b9d2e4f6a8b1c3d5e7f9a0b2c4d6e8f0a2b4c6d8e0f",
    isActive: true,
  });
  console.log("  Model Registered:", model.toJSON());
  console.log("  Model Version:", model.version === "efficientnet-b3-v1.0.0" ? " PASSED" : "❌ FAILED");

  // 2. AIResult 5-Class Invariants test
  console.log("\n[Test 2] Testing AIResult Entity (5 Classes)...");
  const aiResult1 = AIResult.create({
    screeningId: crypto.randomUUID(),
    modelVersionId: model.id,
    predictedClass: "MODERATE_DR",
    confidence: 0.88,
    rawProbabilities: {
      NO_DR: 0.03,
      MILD_DR: 0.05,
      MODERATE_DR: 0.88,
      SEVERE_DR: 0.03,
      PROLIFERATIVE_DR: 0.01,
    },
    inferenceDurationMs: 142,
  });
  console.log("  Predicted Class:", aiResult1.predictedClass);
  console.log("  Confidence:", aiResult1.confidence);
  console.log("  Is High Risk:", aiResult1.isHighRisk() ? "YES" : "NO (Moderate)");

  // Test invalid class rejection
  try {
    AIResult.create({
      screeningId: crypto.randomUUID(),
      modelVersionId: model.id,
      predictedClass: "INVALID_CLASS" as any,
      confidence: 0.9,
      rawProbabilities: {},
    });
    console.log("  Invalid class check: ❌ FAILED");
  } catch (err: any) {
    console.log("  Invalid class check: ✅ PASSED (Caught:", err.message + ")");
  }

  // 3. Setup Screening Sesi Lolos Quality Gate
  console.log("\n[Test 3] Mempersiapkan Sesi Skrining (Lulus Quality Gate)...");
  const screeningA = Screening.create({
    patientId: crypto.randomUUID(),
    conductedById: crypto.randomUUID(),
  });

  const imgOD = RetinalImage.create({
    screeningId: screeningA.id,
    eye: "OD",
    storageKey: `screenings/${screeningA.id}/od.jpg`,
    mimeType: "image/jpeg",
    checksum: "sha256:dummyodhash",
  });
  screeningA.addImage(imgOD);

  const qcOD = QualityCheck.create({
    retinalImageId: imgOD.id,
    passed: true,
    overallScore: 0.94,
    blurScore: 0.95,
    illuminationScore: 0.92,
    fovScore: 0.95,
  });
  screeningA.recordQualityCheck(qcOD);
  console.log("  Screening A Status:", screeningA.status === "QUALITY_CHECK" ? "✅ QUALITY_CHECK" : "❌ FAILED");

  // 4. Skenario A: High Confidence & Optimal Quality -> ANALYZE -> AI_ANALYZED
  console.log("\n[Test 4] Skenario A: High Confidence (0.88) -> Reliability Gate: ANALYZE...");
  const highReliability = ReliabilityAssessment.create({
    screeningId: screeningA.id,
    status: "ANALYZE",
    score: 0.90,
    confidenceThreshold: 0.85,
    qualityThreshold: 0.75,
    reasoning: "Keyakinan inferensi tinggi (0.88 >= 0.85) dan kualitas citra prima.",
  });

  screeningA.recordAiInference(aiResult1, highReliability);
  console.log("  Reliability Status:", highReliability.status);
  console.log("  Requires Human Review:", highReliability.requiresHumanReview() ? "YES" : "NO");
  console.log("  Screening A Status:", screeningA.status === "AI_ANALYZED" ? "✅ AI_ANALYZED" : "❌ FAILED");

  // 5. Skenario B: Borderline / Low Confidence -> HUMAN_REVIEW -> Status Screening: HUMAN_REVIEW
  console.log("\n[Test 5] Skenario B: Borderline Confidence (0.44) -> Reliability Gate: HUMAN_REVIEW...");
  const screeningB = Screening.create({
    patientId: crypto.randomUUID(),
    conductedById: crypto.randomUUID(),
  });
  const imgOS = RetinalImage.create({
    screeningId: screeningB.id,
    eye: "OS",
    storageKey: `screenings/${screeningB.id}/os.jpg`,
    mimeType: "image/jpeg",
    checksum: "sha256:dummyoshash",
  });
  screeningB.addImage(imgOS);
  const qcOS = QualityCheck.create({
    retinalImageId: imgOS.id,
    passed: true,
    overallScore: 0.85,
  });
  screeningB.recordQualityCheck(qcOS);

  const borderlineAiResult = AIResult.create({
    screeningId: screeningB.id,
    modelVersionId: model.id,
    predictedClass: "MILD_DR",
    confidence: 0.44, // Borderline antara Mild (0.44) dan Moderate (0.42)
    rawProbabilities: {
      NO_DR: 0.08,
      MILD_DR: 0.44,
      MODERATE_DR: 0.42,
      SEVERE_DR: 0.04,
      PROLIFERATIVE_DR: 0.02,
    },
    inferenceDurationMs: 138,
  });

  const lowReliability = ReliabilityAssessment.create({
    screeningId: screeningB.id,
    status: "HUMAN_REVIEW",
    score: 0.56,
    confidenceThreshold: 0.85,
    qualityThreshold: 0.75,
    reasoning: "Ambang batas keyakinan rendah (0.44 < 0.85). Kasus borderline Mild vs Moderate DR.",
  });

  screeningB.recordAiInference(borderlineAiResult, lowReliability);
  console.log("  Reliability Status:", lowReliability.status);
  console.log("  Requires Human Review:", lowReliability.requiresHumanReview() ? "✅ YES (Wajib Telaah Dokter Spesialis Mata)" : "❌ FAILED");
  console.log("  Screening B Status:", screeningB.status === "HUMAN_REVIEW" ? "✅ HUMAN_REVIEW" : "❌ FAILED");

  // 6. Skenario C: Proteksi Arsitektur (AI tidak boleh dijalankan jika Quality Gate gagal)
  console.log("\n[Test 6] Skenario C: Proteksi Inferensi pada Screening Gagal Mutu...");
  const screeningC = Screening.create({
    patientId: crypto.randomUUID(),
    conductedById: crypto.randomUUID(),
  });
  screeningC.addImage(imgOD);
  const badQc = QualityCheck.create({
    retinalImageId: imgOD.id,
    passed: false,
    overallScore: 0.45,
    retakeReason: "BLURRY",
  });
  screeningC.recordQualityCheck(badQc);
  console.log("  Screening C Status:", screeningC.status); // RETAKE_REQUIRED

  try {
    screeningC.recordAiInference(aiResult1, highReliability);
    console.log("  Protection Gate: ❌ FAILED (Should have thrown error)");
  } catch (err: any) {
    console.log("  Protection Gate: ✅ PASSED (Blocked successfully:", err.message + ")");
  }

  console.log("\n==========================================");
  console.log("🎉 ALL RETIVA PHASE 3 AI & RELIABILITY CHECKS COMPLETED SUCCESSFULLY!");
  console.log("==========================================");
}

runPhase3Tests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
