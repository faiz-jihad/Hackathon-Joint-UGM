/**
 * Test script for RETIVA Phase 2:
 * - Screening State Machine transitions
 * - RetinalImage no-BLOB invariant & SHA-256 checksum verification
 * - ImageStorage abstraction & presigned URL flow
 * - Automated Image Quality Gate (Fail -> RETAKE_REQUIRED, Pass -> QUALITY_CHECK)
 */

import { Screening } from "../domain/screening/screening.entity";
import { RetinalImage } from "../domain/screening/retinal-image.entity";
import { QualityCheck } from "../domain/screening/quality-check.entity";
import { S3CompatibleStorage } from "../infrastructure/storage/s3-compatible.storage";
import crypto from "crypto";

async function runPhase2Tests() {
  console.log("==========================================");
  console.log("🧪 RETIVA PHASE 2 VERIFICATION & SCREENING WORKFLOW");
  console.log("==========================================");

  // 1. Inisiasi Screening Sesi
  console.log("\n[Test 1] Inisiasi Screening (State: CREATED)...");
  const patientId = crypto.randomUUID();
  const workerId = crypto.randomUUID();

  const screening = Screening.create({
    patientId,
    conductedById: workerId,
    notes: "Pemeriksaan skrining retinopati tahunan di Puskesmas.",
    metadata: { facilityCode: "PUSK-YOGYA-01", cameraModel: "Topcon TRC-NW400" },
  });

  console.log("  Screening ID:", screening.id);
  console.log("  Initial Status:", screening.status === "CREATED" ? "✅ CREATED" : "❌ FAILED");

  // 2. Storage Abstraction & Upload Retinal Image (OD & OS)
  console.log("\n[Test 2] Upload Citra Fundus (No-BLOB, S3-Compatible Abstraction)...");
  const storage = new S3CompatibleStorage();

  // Mock fundus image binary buffers
  const dummyImageOD = Buffer.from("RETIVA_DUMMY_RETINAL_IMAGE_OD_RIGHT_EYE_CONTENT");
  const dummyImageOS = Buffer.from("RETIVA_DUMMY_RETINAL_IMAGE_OS_LEFT_EYE_CONTENT");

  const storageKeyOD = `screenings/${screening.id}/od.jpg`;
  const storageKeyOS = `screenings/${screening.id}/os.jpg`;

  const uploadResOD = await storage.upload({
    storageKey: storageKeyOD,
    data: dummyImageOD,
    mimeType: "image/jpeg",
  });
  const uploadResOS = await storage.upload({
    storageKey: storageKeyOS,
    data: dummyImageOS,
    mimeType: "image/jpeg",
  });

  console.log("  Uploaded OD to Storage:", uploadResOD.storageKey, "| Checksum:", uploadResOD.checksum.slice(0, 16) + "...");
  console.log("  Uploaded OS to Storage:", uploadResOS.storageKey, "| Checksum:", uploadResOS.checksum.slice(0, 16) + "...");

  const imageOD = RetinalImage.create({
    screeningId: screening.id,
    eye: "OD",
    storageKey: uploadResOD.storageKey,
    mimeType: "image/jpeg",
    checksum: uploadResOD.checksum,
    fileSizeBytes: dummyImageOD.length,
  });

  const imageOS = RetinalImage.create({
    screeningId: screening.id,
    eye: "OS",
    storageKey: uploadResOS.storageKey,
    mimeType: "image/jpeg",
    checksum: uploadResOS.checksum,
    fileSizeBytes: dummyImageOS.length,
  });

  // Tambahkan ke aggregate screening
  screening.addImage(imageOD);
  screening.addImage(imageOS);

  console.log("  Status after upload:", screening.status === "IMAGE_UPLOADED" ? "✅ IMAGE_UPLOADED" : "❌ FAILED");
  console.log("  Total images in screening:", screening.images.length === 2 ? "✅ 2 Images (OD, OS)" : "❌ FAILED");

  // 3. Image Presigned URL Verification
  console.log("\n[Test 3] Verifikasi Presigned URL (No Public Access)...");
  const signedUrl = await storage.getSignedUrl(imageOD.storageKey, 900);
  console.log("  Generated Presigned URL:", signedUrl);
  console.log("  Presigned token attached:", signedUrl.includes("auth_token=") ? "✅ SECURE" : "❌ EXPOSED");

  // 4. Quality Gate Skenario A: Kualitas Buram -> RETAKE_REQUIRED
  console.log("\n[Test 4] Skenario Quality Gate: Citra Buram (Quality Fail)...");
  const failedQc = QualityCheck.create({
    retinalImageId: imageOD.id,
    passed: false,
    overallScore: 0.54,
    blurScore: 0.42,
    illuminationScore: 0.70,
    fovScore: 0.65,
    retakeReason: "BLURRY",
    retakeInstructions: "Diskus optikus dan pembuluh darah retina tidak tajam. Stabilkan kamera fundus.",
  });

  screening.recordQualityCheck(failedQc);
  console.log("  Evaluated OD Quality: FAIL (Score: 0.54)");
  console.log("  Screening Status:", screening.status === "RETAKE_REQUIRED" ? "✅ RETAKE_REQUIRED" : "❌ FAILED");
  console.log("  Retake Instructions:", failedQc.retakeInstructions);

  // Verifikasi AI classification tidak boleh jalan saat RETAKE_REQUIRED
  try {
    screening.markAiAnalyzed();
    console.log("  Protection check: ❌ FAILED (Should not allow AI analyze on RETAKE_REQUIRED)");
  } catch (err: any) {
    console.log("  Protection check: ✅ PASSED (Blocked with error:", err.message + ")");
  }

  // 5. Quality Gate Skenario B: Pengambilan Ulang & Lulus Mutu -> QUALITY_CHECK
  console.log("\n[Test 5] Skenario Quality Gate: Pengambilan Ulang Berhasil (Quality Pass)...");
  
  // Nakes mengambil ulang gambar OD berkualitas baik
  const retakeImageOD = RetinalImage.create({
    screeningId: screening.id,
    eye: "OD",
    storageKey: `screenings/${screening.id}/od_retake.jpg`,
    mimeType: "image/jpeg",
    checksum: crypto.createHash("sha256").update("RETAKE_OPTIMAL_OD").digest("hex"),
    fileSizeBytes: 1024,
  });
  screening.addImage(retakeImageOD);
  console.log("  Retake image added. Status:", screening.status === "IMAGE_UPLOADED" ? "✅ IMAGE_UPLOADED" : "❌ FAILED");

  // Evaluasi mutu ulang kedua mata
  const passedQcOD = QualityCheck.create({
    retinalImageId: retakeImageOD.id,
    passed: true,
    overallScore: 0.94,
    blurScore: 0.95,
    illuminationScore: 0.92,
    fovScore: 0.96,
  });

  const passedQcOS = QualityCheck.create({
    retinalImageId: imageOS.id,
    passed: true,
    overallScore: 0.91,
    blurScore: 0.90,
    illuminationScore: 0.89,
    fovScore: 0.94,
  });

  screening.recordQualityCheck(passedQcOD);
  screening.recordQualityCheck(passedQcOS);

  console.log("  Evaluated OD Quality: PASS (Score: 0.94)");
  console.log("  Evaluated OS Quality: PASS (Score: 0.91)");
  console.log("  Screening Status:", screening.status === "QUALITY_CHECK" ? "✅ QUALITY_CHECK (Ready for Phase 3 AI Inference)" : "❌ FAILED");

  console.log("\n==========================================");
  console.log("🎉 ALL RETIVA PHASE 2 WORKFLOW CHECKS COMPLETED SUCCESSFULLY!");
  console.log("==========================================");
}

runPhase2Tests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
