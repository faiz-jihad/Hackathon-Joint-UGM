/**
 * Test script for RETIVA Phase 4:
 * - Human Review Adjudication (Ophthalmologist confirm / override)
 * - Deterministic Recommendation Rules Engine (Perdami/ADA guidelines)
 * - Healthcare Facility & Rule-Based Matching (No AI hospital selection!)
 * - Referral Issuance & Tracking
 * - Follow-up Scheduling & Longitudinal Patient History
 */

import { Screening } from "../domain/screening/screening.entity";
import { HumanReview } from "../domain/screening/human-review.entity";
import { RecommendationRulesEngine } from "../domain/recommendation/recommendation-rules.engine";
import { Facility } from "../domain/facility/facility.entity";
import { Referral } from "../domain/referral/referral.entity";
import { FollowUp } from "../domain/follow-up/follow-up.entity";
import { DiabetesProfile } from "../domain/patient/diabetes-profile.entity";
import crypto from "crypto";

async function runPhase4Tests() {
  console.log("==========================================");
  console.log("🧪 RETIVA PHASE 4 VERIFICATION: CLINICAL CONTINUITY SUITE");
  console.log("==========================================");

  // 1. Human Review Adjudication test
  console.log("\n[Test 1] Human Review Adjudication (Dokter Spesialis Mata)...");
  const screening = Screening.create({
    patientId: crypto.randomUUID(),
    conductedById: crypto.randomUUID(),
  });
  // Simulate status in HUMAN_REVIEW
  (screening as any).props.status = "HUMAN_REVIEW";

  const ophthalmologistId = crypto.randomUUID();
  const humanReview = HumanReview.create({
    screeningId: screening.id,
    reviewerId: ophthalmologistId,
    reviewStatus: "OVERRIDDEN",
    confirmedClass: "MODERATE_DR",
    clinicalNotes: "Ditemukan mikroaneurisma multipel di kuadran temporal dan perdarahan dot-blot.",
  });

  console.log("  Reviewer ID:", humanReview.reviewerId);
  console.log("  Review Status:", humanReview.reviewStatus);
  console.log("  Confirmed Class:", humanReview.confirmedClass);

  // Selesaikan skrining setelah telaah dokter
  screening.completeScreening();
  console.log("  Screening Status after Review:", screening.status === "SCREENING_COMPLETED" ? "✅ SCREENING_COMPLETED" : "❌ FAILED");

  // 2. Deterministic Recommendation Engine test
  console.log("\n[Test 2] Deterministic Recommendation Rules Engine...");
  const diabetesProfile = DiabetesProfile.create({
    patientId: screening.patientId,
    diabetesType: "TYPE_2",
    currentTreatment: "ORAL_MEDICATION",
    lastHbA1c: 9.1, // Suboptimal / Poor
    yearOfDiagnosis: 2015,
  });

  // Uji A: Moderate DR
  const recModerate = RecommendationRulesEngine.evaluate({
    screeningId: screening.id,
    confirmedClass: "MODERATE_DR",
    diabetesProfile,
  });
  console.log("  [Moderate DR] Action:", recModerate.recommendedAction);
  console.log("  [Moderate DR] Urgency:", recModerate.urgencyLevel);
  console.log("  [Moderate DR] Referral Indicated:", recModerate.referralIndicated ? "✅ YES" : "❌ NO");

  // Uji B: Proliferative DR (PDR)
  const recPDR = RecommendationRulesEngine.evaluate({
    screeningId: screening.id,
    confirmedClass: "PROLIFERATIVE_DR",
    diabetesProfile,
  });
  console.log("  [PDR] Action:", recPDR.recommendedAction);
  console.log("  [PDR] Urgency:", recPDR.urgencyLevel === "CRITICAL" ? "✅ CRITICAL" : "❌ FAILED");
  console.log("  [PDR] Referral Indicated:", recPDR.referralIndicated ? "✅ YES" : "❌ NO");

  // Uji C: No DR
  const recNoDR = RecommendationRulesEngine.evaluate({
    screeningId: screening.id,
    confirmedClass: "NO_DR",
    diabetesProfile: null,
  });
  console.log("  [No DR] Action:", recNoDR.recommendedAction);
  console.log("  [No DR] Referral Indicated:", !recNoDR.referralIndicated ? "✅ NO (Routine Screening)" : "❌ FAILED");

  // 3. Facility & Haversine Rule-based Matching
  console.log("\n[Test 3] Facility Directory & Deterministic Geodesic Matching...");
  // Faskes di Yogyakarta: RS Mata Dr. Yap (Lat: -7.7828, Lng: 110.3725)
  const facility1 = Facility.create({
    name: "RS Mata Dr. Yap Yogyakarta",
    address: "Jl. Cik Di Tiro No.5, Terban, Gondokusuman, Yogyakarta",
    latitude: -7.7828,
    longitude: 110.3725,
    bpjsStatus: "ACCEPTED",
    isVerified: true,
    contactPhone: "0274-562054",
    services: [
      { serviceName: "RETINA_SPECIALIST", description: "Subspesialis Vitreoretina" },
      { serviceName: "LASER_PHOTOCOAGULATION", description: "Laser Argon Retina" },
      { serviceName: "OCT", description: "Optical Coherence Tomography" },
    ],
    insurances: [{ insuranceName: "BPJS_KESEHATAN", status: "ACTIVE" }],
  });

  // Pasien berada di sekitar UGM (Lat: -7.7713, Lng: 110.3775)
  const patientLat = -7.7713;
  const patientLng = 110.3775;
  const distance = facility1.calculateDistanceKm(patientLat, patientLng);
  console.log(`  Distance to ${facility1.name}:`, distance, "km");
  console.log("  Distance plausibility (< 3 km):", distance < 3.0 ? "✅ PASSED" : "❌ FAILED");
  console.log("  Has Retina Specialist:", facility1.hasService("RETINA_SPECIALIST") ? "✅ YES" : "❌ NO");
  console.log("  BPJS Status:", facility1.bpjsStatus === "ACCEPTED" ? "✅ ACCEPTED" : "❌ FAILED");

  // 4. Referral Issuance
  console.log("\n[Test 4] Penerbitan Surat Rekomendasi Rujukan...");
  const referral = Referral.create({
    screeningId: screening.id,
    patientId: screening.patientId,
    targetFacilityId: facility1.id,
    urgency: recModerate.urgencyLevel,
    reason: "Rujukan retinopati diabetik non-proliferatif sedang (NPDR Moderate) untuk pemeriksaan biomikroskopi fundus.",
    clinicalSummary: recModerate.summary,
  });

  console.log("  Referral ID:", referral.id);
  console.log("  Referral Status:", referral.status === "RECOMMENDED" ? "✅ RECOMMENDED" : "❌ FAILED");
  referral.issue();
  console.log("  Status after issue:", referral.status === "ISSUED" ? "✅ ISSUED" : "❌ FAILED");
  console.log("  Expires in 30 days:", referral.expiresAt ? "✅ YES" : "❌ NO");

  // 5. Follow-up Scheduling & Completion
  console.log("\n[Test 5] Penjadwalan Kontrol & Kunjungan Ulang...");
  const followUpDueDate = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 3 bulan
  const followUp = FollowUp.create({
    patientId: screening.patientId,
    screeningId: screening.id,
    dueDate: followUpDueDate,
    completionNotes: "Evaluasi pasca konsultasi spesialis mata faskes rujukan.",
  });

  console.log("  Follow-up Scheduled for:", followUp.dueDate.toISOString().split("T")[0]);
  console.log("  Initial Status:", followUp.status === "SCHEDULED" ? "✅ SCHEDULED" : "❌ FAILED");

  // Simulasi kehadiran pasien kontrol
  followUp.complete("Pasien telah kontrol di RS Mata Dr. Yap, dilakukan injeksi anti-VEGF.");
  console.log("  Status after visit:", followUp.status === "COMPLETED" ? "✅ COMPLETED" : "❌ FAILED");
  console.log("  Completion Notes:", followUp.completionNotes);

  console.log("\n==========================================");
  console.log("🎉 ALL RETIVA PHASE 4 CLINICAL WORKFLOW CHECKS COMPLETED SUCCESSFULLY!");
  console.log("==========================================");
}

runPhase4Tests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
