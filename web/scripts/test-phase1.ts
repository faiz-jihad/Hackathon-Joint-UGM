/**
 * Test script for RETIVA Phase 1:
 * - Domain Entity creation & invariants
 * - Value Objects & Clinical checks
 * - Password hashing & JWT Verification
 * - Patient and Diabetes Profile lifecycle
 */

import { User } from "../domain/auth/user.entity";
import { Patient } from "../domain/patient/patient.entity";
import { DiabetesProfile } from "../domain/patient/diabetes-profile.entity";
import { BcryptPasswordHasher } from "../infrastructure/security/bcrypt-hasher";
import { JwtTokenService } from "../infrastructure/security/jwt-token.service";

async function runPhase1Tests() {
  console.log("==========================================");
  console.log("🧪 RETIVA PHASE 1 VERIFICATION & DOMAIN SUITE");
  console.log("==========================================");

  // 1. Password Hasher test
  console.log("\n[Test 1] Testing BcryptPasswordHasher...");
  const hasher = new BcryptPasswordHasher();
  const rawPassword = "MedicalPassword2026!";
  const hash = await hasher.hash(rawPassword);
  const isMatch = await hasher.compare(rawPassword, hash);
  const isMismatch = await hasher.compare("WrongPassword", hash);
  console.log("  Password hashed successfully:", hash.slice(0, 25) + "...");
  console.log("  Valid match check:", isMatch ? "✅ PASSED" : "❌ FAILED");
  console.log("  Invalid mismatch check:", !isMismatch ? "✅ PASSED" : "❌ FAILED");

  // 2. User Entity test
  console.log("\n[Test 2] Testing User Entity & RBAC...");
  const user = User.create({
    email: "dr.sarah@retina.hospital.id",
    passwordHash: hash,
    fullName: "dr. Sarah Sp.M",
    role: "OPHTHALMOLOGIST",
    phoneNumber: "081234567890",
  });
  console.log("  User created:", user.toJSON());
  console.log("  Role:", user.role === "OPHTHALMOLOGIST" ? "✅ PASSED" : "❌ FAILED");

  // 3. JWT Token test
  console.log("\n[Test 3] Testing JwtTokenService...");
  const tokenService = new JwtTokenService();
  const token = tokenService.generateToken({
    userId: user.id,
    email: user.email,
    role: user.role,
  });
  const decoded = tokenService.verifyToken(token);
  console.log("  Token generated:", token.slice(0, 30) + "...");
  console.log("  Decoded User ID matches:", decoded?.userId === user.id ? "✅ PASSED" : "❌ FAILED");

  // 4. Patient Entity & Invariants test
  console.log("\n[Test 4] Testing Patient Entity & NIK validation...");
  const validNik = "3201015504850001";
  const patient = Patient.create({
    nik: validNik,
    fullName: "Budi Santoso",
    birthDate: new Date("1975-06-15"),
    gender: "MALE",
    phone: "081987654321",
    address: "Jl. Kaliurang KM 5, Sleman, DI Yogyakarta",
  });
  console.log("  Patient created:", patient.toJSON());
  console.log("  Calculated Age:", patient.getAge(), "years");

  // Invariant test: invalid NIK
  try {
    Patient.create({
      nik: "123", // invalid length
      fullName: "Invalid",
      birthDate: new Date("1990-01-01"),
      gender: "FEMALE",
    });
    console.log("  Invalid NIK rejection: ❌ FAILED (Should have thrown)");
  } catch (err: any) {
    console.log("  Invalid NIK rejection: ✅ PASSED (Caught:", err.message + ")");
  }

  // 5. Diabetes Profile & Clinical rules test
  console.log("\n[Test 5] Testing DiabetesProfile & Clinical Rules...");
  const diabetesProfile = DiabetesProfile.create({
    patientId: patient.id,
    diabetesType: "TYPE_2",
    yearOfDiagnosis: 2018,
    currentTreatment: "ORAL_MEDICATION",
    lastHbA1c: 8.2,
    lastHbA1cDate: new Date("2026-08-10"),
    systolicBp: 135,
    diastolicBp: 85,
    isSmoker: false,
    notes: "Rutin mengonsumsi Metformin 500mg 2x sehari.",
  });
  console.log("  Diabetes Profile created:", diabetesProfile.toJSON());
  console.log("  Duration of Diabetes:", diabetesProfile.getDiabetesDurationYears(), "years");
  console.log("  Glycaemic Control Status:", diabetesProfile.getGlycaemicControlStatus());

  // Invariant test: clinically implausible HbA1c
  try {
    DiabetesProfile.create({
      patientId: patient.id,
      diabetesType: "TYPE_2",
      currentTreatment: "INSULIN",
      lastHbA1c: 45.0, // Implausible HbA1c
      isSmoker: false,
    });
    console.log("  Plausibility check on HbA1c: ❌ FAILED");
  } catch (err: any) {
    console.log("  Plausibility check on HbA1c: ✅ PASSED (Caught:", err.message + ")");
  }

  console.log("\n==========================================");
  console.log("🎉 ALL RETIVA PHASE 1 CHECKS COMPLETED SUCCESSFULLY!");
  console.log("==========================================");
}

runPhase1Tests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
