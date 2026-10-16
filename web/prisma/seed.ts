import {
  PrismaClient,
  UserRole,
  Gender,
  DiabetesType,
  TreatmentType,
  ScreeningStatus,
  EyePosition,
  QualityRetakeReason,
  DRClassification,
  ReliabilityStatus,
  HumanReviewStatus,
  RecommendedAction,
  UrgencyLevel,
  BPJSStatus,
  ReferralStatus,
  FollowUpStatus,
} from "@prisma/client";
import * as bcrypt from "bcryptjs";
import { COMPREHENSIVE_MASTER_MEALS } from "../infrastructure/database/master-meals-data";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Memulai proses seeding komprehensif basis data medis RETIVA...");

  const plainPassword = "password";
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(plainPassword, saltRounds);

  // ==========================================
  // 1. FASILITAS KESEHATAN (FKTP & FKRTL)
  // ==========================================
  console.log("🏥 Seeding fasilitas kesehatan rujukan & FKTP...");

  const facilitiesData = [
    {
      id: "fac-sleman-01",
      name: "Puskesmas Sleman (FKTP)",
      address: "Jl. Bhayangkara No.27, Triharjo, Kec. Sleman, Kabupaten Sleman, D.I. Yogyakarta",
      latitude: -7.6894,
      longitude: 110.3444,
      bpjsStatus: BPJSStatus.ACCEPTED,
      isVerified: true,
      contactPhone: "(0274) 868351",
      services: ["PRIMARY_DIABETES_CARE", "FUNDUS_CAMERA_SCREENING", "CDSS_TRIAGE"],
      insurances: ["BPJS_KESEHATAN"],
    },
    {
      id: "fac-mlati-02",
      name: "Puskesmas Mlati II (FKTP)",
      address: "Jl. Kebon Agung, Cabakan, Sumberadi, Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta",
      latitude: -7.7312,
      longitude: 110.3541,
      bpjsStatus: BPJSStatus.ACCEPTED,
      isVerified: true,
      contactPhone: "(0274) 869112",
      services: ["PRIMARY_DIABETES_CARE", "CDSS_SCREENING"],
      insurances: ["BPJS_KESEHATAN"],
    },
    {
      id: "fac-yap-01",
      name: "RS Mata Dr. Yap Yogyakarta",
      address: "Jl. Cik Di Tiro No.5, Terban, Gondokusuman, Kota Yogyakarta, D.I. Yogyakarta",
      latitude: -7.7797,
      longitude: 110.3758,
      bpjsStatus: BPJSStatus.ACCEPTED,
      isVerified: true,
      contactPhone: "(0274) 562054",
      services: [
        "RETINA_SUBSPECIALIST",
        "VITREORETINAL_SURGERY",
        "LASER_PHOTOCOAGULATION_PRP",
        "OCT_MACULAR_SCAN",
        "FLUORESCEIN_ANGIOGRAPHY",
      ],
      insurances: ["BPJS_KESEHATAN", "MANDIRI_INHEALTH"],
    },
    {
      id: "fac-sardjito-01",
      name: "RSUP Dr. Sardjito (Pusat Subspesialis Retina FKRTL)",
      address: "Jl. Kesehatan No.1, Sekip, Sinduadi, Mlati, Kabupaten Sleman, D.I. Yogyakarta",
      latitude: -7.7686,
      longitude: 110.3737,
      bpjsStatus: BPJSStatus.ACCEPTED,
      isVerified: true,
      contactPhone: "(0274) 631190",
      services: [
        "VITREORETINAL_CENTER",
        "RETINA_SURGERY_COMPLEX",
        "ANTI_VEGF_INJECTION",
        "OCT_ANGIOGRAPHY",
      ],
      insurances: ["BPJS_KESEHATAN", "MANDIRI_INHEALTH"],
    },
    {
      id: "fac-rsa-ugm-01",
      name: "RS Akademik UGM (RSA UGM)",
      address: "Jl. Kabupaten, Kronggahan, Trihanggo, Gamping, Sleman, D.I. Yogyakarta",
      latitude: -7.7431,
      longitude: 110.3503,
      bpjsStatus: BPJSStatus.ACCEPTED,
      isVerified: true,
      contactPhone: "(0274) 4530404",
      services: ["OPHTHALMOLOGY_CLINIC", "DIABETIC_EYE_SCREENING", "LASER_PRP"],
      insurances: ["BPJS_KESEHATAN"],
    },
  ];

  for (const f of facilitiesData) {
    await prisma.facility.upsert({
      where: { id: f.id },
      update: {
        name: f.name,
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        bpjsStatus: f.bpjsStatus,
        isVerified: f.isVerified,
        contactPhone: f.contactPhone,
      },
      create: {
        id: f.id,
        name: f.name,
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        bpjsStatus: f.bpjsStatus,
        isVerified: f.isVerified,
        contactPhone: f.contactPhone,
      },
    });

    // Seed services
    for (const serviceName of f.services) {
      const existing = await prisma.facilityService.findFirst({
        where: { facilityId: f.id, serviceName },
      });
      if (!existing) {
        await prisma.facilityService.create({
          data: { facilityId: f.id, serviceName },
        });
      }
    }

    // Seed insurances
    for (const insuranceName of f.insurances) {
      const existing = await prisma.facilityInsurance.findFirst({
        where: { facilityId: f.id, insuranceName },
      });
      if (!existing) {
        await prisma.facilityInsurance.create({
          data: { facilityId: f.id, insuranceName, status: "ACTIVE" },
        });
      }
    }
  }

  // ==========================================
  // 2. USERS (ADMIN, NAKES, DOKTER SP.M, PASIEN)
  // ==========================================
  console.log("👤 Seeding pengguna sistem (RBAC)...");

  const usersData = [
    {
      id: "usr-admin-01",
      email: "admin@gmail.com",
      fullName: "Administrator RETIVA",
      role: UserRole.ADMIN,
      phoneNumber: "081234567890",
      facilityId: "fac-sleman-01",
    },
    {
      id: "usr-admin-02",
      email: "guntoroloa@gmail.com",
      fullName: "Guntoro Loa",
      role: UserRole.ADMIN,
      phoneNumber: "081298765432",
      facilityId: "fac-sleman-01",
    },
    {
      id: "usr-nakes-01",
      email: "nakes.siti@puskesmas.go.id",
      fullName: "Siti Nurhaliza, S.Tr.Kes",
      role: UserRole.HEALTHCARE_WORKER,
      phoneNumber: "081234567811",
      facilityId: "fac-sleman-01",
    },
    {
      id: "usr-nakes-02",
      email: "nakes.dewi@puskesmas.go.id",
      fullName: "Dewi Sartika, A.Md.Kes",
      role: UserRole.HEALTHCARE_WORKER,
      phoneNumber: "081234567822",
      facilityId: "fac-mlati-02",
    },
    {
      id: "usr-doc-01",
      email: "dr.harianto@retiva.id",
      fullName: "dr. Harianto, Sp.M(K)",
      role: UserRole.OPHTHALMOLOGIST,
      phoneNumber: "081234567833",
      facilityId: "fac-sardjito-01",
    },
    {
      id: "usr-doc-02",
      email: "dr.anindita@retiva.id",
      fullName: "dr. Anindita Putri, Sp.M",
      role: UserRole.OPHTHALMOLOGIST,
      phoneNumber: "081234567844",
      facilityId: "fac-yap-01",
    },
  ];

  const userMap: Record<string, string> = {};
  for (const u of usersData) {
    const user = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        fullName: u.fullName,
        role: u.role,
        passwordHash: passwordHash,
        phoneNumber: u.phoneNumber,
        facilityId: u.facilityId,
        isActive: true,
      },
      create: {
        id: u.id,
        email: u.email,
        fullName: u.fullName,
        role: u.role,
        passwordHash: passwordHash,
        phoneNumber: u.phoneNumber,
        facilityId: u.facilityId,
        isActive: true,
      },
    });
    userMap[u.id] = user.id;
  }

  // ==========================================
  // 3. PASIEN & PROFIL DIABETES (16-DIGIT NIK)
  // ==========================================
  console.log("🩺 Seeding profil pasien diabetes melitus...");

  const patientsData = [
    {
      id: "pat-001",
      nik: "3404015508750001",
      fullName: "Bapak Sutrisno",
      birthDate: new Date("1970-08-15"),
      gender: Gender.MALE,
      phone: "081234567890",
      address: "Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_2,
        yearOfDiagnosis: 2018,
        currentTreatment: TreatmentType.ORAL_MEDICATION,
        lastHbA1c: 8.4,
        systolicBp: 135,
        diastolicBp: 85,
        isSmoker: false,
        notes: "Konsumsi metformin 500mg 2x sehari, kontrol rutin di Puskesmas.",
      },
    },
    {
      id: "pat-002",
      nik: "3404084501650002",
      fullName: "Ny. Siti Aminah",
      birthDate: new Date("1965-01-26"),
      gender: Gender.FEMALE,
      phone: "081298765432",
      address: "Jl. Kaliurang KM 9.2, Sleman, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_2,
        yearOfDiagnosis: 2014,
        currentTreatment: TreatmentType.INSULIN,
        lastHbA1c: 9.4,
        systolicBp: 145,
        diastolicBp: 90,
        isSmoker: false,
        notes: "Terapi insulin harian & metformin, riwayat DM 12 tahun.",
      },
    },
    {
      id: "pat-003",
      nik: "3404026203800002",
      fullName: "Ibu Ratna Dewi",
      birthDate: new Date("1980-03-22"),
      gender: Gender.FEMALE,
      phone: "081987654321",
      address: "Kec. Depok, Sleman, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_2,
        yearOfDiagnosis: 2021,
        currentTreatment: TreatmentType.ORAL_MEDICATION,
        lastHbA1c: 6.8,
        systolicBp: 120,
        diastolicBp: 80,
        isSmoker: false,
        notes: "Glikemik terkontrol baik, rutin senam diabetes.",
      },
    },
    {
      id: "pat-004",
      nik: "3404071203720001",
      fullName: "Bapak Bambang Sudarmono",
      birthDate: new Date("1972-03-12"),
      gender: Gender.MALE,
      phone: "081234567899",
      address: "Ngaglik, Kabupaten Sleman, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_2,
        yearOfDiagnosis: 2019,
        currentTreatment: TreatmentType.COMBINATION,
        lastHbA1c: 8.2,
        systolicBp: 130,
        diastolicBp: 85,
        isSmoker: true,
        notes: "Kombinasi OHO dan insulin malam hari.",
      },
    },
    {
      id: "pat-005",
      nik: "3404031111650003",
      fullName: "Bapak Wahyu Hidayat",
      birthDate: new Date("1965-11-11"),
      gender: Gender.MALE,
      phone: "081345678912",
      address: "Godean, Sleman, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_1,
        yearOfDiagnosis: 2012,
        currentTreatment: TreatmentType.INSULIN,
        lastHbA1c: 9.6,
        systolicBp: 140,
        diastolicBp: 90,
        isSmoker: false,
        notes: "DM Tipe 1 dengan injeksi insulin basal-bolus.",
      },
    },
    {
      id: "pat-006",
      nik: "3402015206780004",
      fullName: "Ibu Endang Rahayu",
      birthDate: new Date("1978-06-20"),
      gender: Gender.FEMALE,
      phone: "081377889900",
      address: "Kasihan, Bantul, D.I. Yogyakarta",
      diabetesProfile: {
        diabetesType: DiabetesType.TYPE_2,
        yearOfDiagnosis: 2023,
        currentTreatment: TreatmentType.ORAL_MEDICATION,
        lastHbA1c: 6.8,
        systolicBp: 118,
        diastolicBp: 78,
        isSmoker: false,
        notes: "Diagnosis baru 1 tahun, kendali glikemik prima.",
      },
    },
  ];

  for (const p of patientsData) {
    const patient = await prisma.patient.upsert({
      where: { nik: p.nik },
      update: {
        fullName: p.fullName,
        birthDate: p.birthDate,
        gender: p.gender,
        phone: p.phone,
        address: p.address,
      },
      create: {
        id: p.id,
        nik: p.nik,
        fullName: p.fullName,
        birthDate: p.birthDate,
        gender: p.gender,
        phone: p.phone,
        address: p.address,
      },
    });

    await prisma.diabetesProfile.upsert({
      where: { patientId: patient.id },
      update: {
        diabetesType: p.diabetesProfile.diabetesType,
        yearOfDiagnosis: p.diabetesProfile.yearOfDiagnosis,
        currentTreatment: p.diabetesProfile.currentTreatment,
        lastHbA1c: p.diabetesProfile.lastHbA1c,
        systolicBp: p.diabetesProfile.systolicBp,
        diastolicBp: p.diabetesProfile.diastolicBp,
        isSmoker: p.diabetesProfile.isSmoker,
        notes: p.diabetesProfile.notes,
      },
      create: {
        patientId: patient.id,
        diabetesType: p.diabetesProfile.diabetesType,
        yearOfDiagnosis: p.diabetesProfile.yearOfDiagnosis,
        currentTreatment: p.diabetesProfile.currentTreatment,
        lastHbA1c: p.diabetesProfile.lastHbA1c,
        systolicBp: p.diabetesProfile.systolicBp,
        diastolicBp: p.diabetesProfile.diastolicBp,
        isSmoker: p.diabetesProfile.isSmoker,
        notes: p.diabetesProfile.notes,
      },
    });
  }

  // ==========================================
  // 4. MODEL VERSI INFERENSI AKTIF
  // ==========================================
  console.log("🧠 Seeding registri model AI...");

  const modelVersion = await prisma.modelVersion.upsert({
    where: { version: "efficientnet-b3-v1.0.0" },
    update: { isActive: true },
    create: {
      id: "mdl-effb3-01",
      modelName: "efficientnet-b3",
      version: "efficientnet-b3-v1.0.0",
      pipelineVersion: "dr-pipe-v1.2",
      weightsHash: "a8f5c9e2b4d1a7e3c6f8b9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",
      isActive: true,
    },
  });

  // ==========================================
  // 5. SKRINING MEDIS HISTORIS (3 CABANG FIGMA)
  // ==========================================
  console.log("📋 Seeding riwayat skrining longitudinal medis...");

  const demoScreeningIds = ["scr-2026-0891", "scr-2026-0889", "scr-2026-0890", "scr-2026-0888"];
  await prisma.referral.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.followUp.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.recommendation.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.humanReview.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.reliabilityAssessment.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.aIResult.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  const demoImages = await prisma.retinalImage.findMany({ where: { screeningId: { in: demoScreeningIds } }, select: { id: true } });
  const demoImageIds = demoImages.map((i) => i.id);
  await prisma.qualityCheck.deleteMany({ where: { retinalImageId: { in: demoImageIds } } });
  await prisma.retinalImage.deleteMany({ where: { screeningId: { in: demoScreeningIds } } });
  await prisma.screening.deleteMany({
    where: { id: { in: demoScreeningIds } },
  });

  // Screening 1: Ny. Siti Aminah -> MODERATE NPDR (Normal Flow / High Reliability)
  const scr1 = await prisma.screening.upsert({
    where: { id: "scr-2026-0891" },
    update: {},
    create: {
      id: "scr-2026-0891",
      patientId: "pat-002",
      conductedById: userMap["usr-nakes-01"] || "usr-nakes-01",
      facilityId: "fac-sleman-01",
      status: ScreeningStatus.SCREENING_COMPLETED,
      notes: "Skrining penapisan tahunan berkala. Pasien mengeluh pandangan agak buram saat membaca.",
      createdAt: new Date("2026-09-24T09:15:00Z"),
    },
  });

  const img1OD = await prisma.retinalImage.create({
    data: {
      screeningId: scr1.id,
      eye: EyePosition.OD,
      storageKey: "fundus/2026/09/scr-2026-0891-OD.jpg",
      mimeType: "image/jpeg",
      checksum: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      fileSizeBytes: 245812,
    },
  });

  await prisma.qualityCheck.create({
    data: {
      retinalImageId: img1OD.id,
      passed: true,
      overallScore: 0.88,
      blurScore: 0.84,
      illuminationScore: 0.89,
      fovScore: 0.94,
    },
  });

  await prisma.aIResult.create({
    data: {
      screeningId: scr1.id,
      modelVersionId: modelVersion.id,
      predictedClass: DRClassification.MODERATE_DR,
      confidence: 0.892,
      rawProbabilities: {
        NO_DR: 0.02,
        MILD_DR: 0.08,
        MODERATE_DR: 0.892,
        SEVERE_DR: 0.007,
        PROLIFERATIVE_DR: 0.001,
      },
      inferenceDurationMs: 420,
    },
  });

  await prisma.reliabilityAssessment.create({
    data: {
      screeningId: scr1.id,
      status: ReliabilityStatus.ANALYZE,
      score: 0.91,
      confidenceThreshold: 0.85,
      qualityThreshold: 0.75,
      reasoning: "Citra berkualitas prima dan margin keyakinan model memadai (89.2% > ambang batas 85%).",
    },
  });

  await prisma.recommendation.create({
    data: {
      screeningId: scr1.id,
      summary:
        "Retinopati Diabetik Non-Proliferatif Derajat Sedang (Moderate NPDR). Rujukan elektif ke Dokter Spesialis Mata di FKRTL disarankan dalam 3-6 bulan.",
      recommendedAction: RecommendedAction.SPECIALIST_OPHTHALMOLOGY_REFERRAL,
      urgencyLevel: UrgencyLevel.MEDIUM,
      referralIndicated: true,
      clinicalGuideline: "Pedoman Pengelolaan Retinopati Diabetika Perdami 2024 / ADA 2024",
    },
  });

  await prisma.referral.create({
    data: {
      screeningId: scr1.id,
      patientId: "pat-002",
      targetFacilityId: "fac-sardjito-01",
      urgency: UrgencyLevel.MEDIUM,
      reason: "Moderate Non-Proliferative Diabetic Retinopathy",
      clinicalSummary:
        "Mikroaneurisma multipel kuadran temporal, hard exudate perifovea. Rujukan poliklinik mata vitreoretina.",
      status: ReferralStatus.ISSUED,
      issuedAt: new Date("2026-09-24T09:30:00Z"),
      expiresAt: new Date("2026-12-24T23:59:59Z"),
    },
  });

  // Screening 2: Bapak Wahyu Hidayat -> RETAKE REQUIRED (Quality Gate Failure)
  const scr2 = await prisma.screening.upsert({
    where: { id: "scr-2026-0889" },
    update: {},
    create: {
      id: "scr-2026-0889",
      patientId: "pat-005",
      conductedById: userMap["usr-nakes-01"] || "usr-nakes-01",
      facilityId: "fac-sleman-01",
      status: ScreeningStatus.RETAKE_REQUIRED,
      notes: "Foto fundus buram karena gerakan mata pasien.",
      createdAt: new Date("2026-09-24T08:05:00Z"),
    },
  });

  const img2OD = await prisma.retinalImage.create({
    data: {
      screeningId: scr2.id,
      eye: EyePosition.OD,
      storageKey: "fundus/2026/09/scr-2026-0889-OD.jpg",
      mimeType: "image/jpeg",
      checksum: "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0",
      fileSizeBytes: 184512,
    },
  });

  await prisma.qualityCheck.create({
    data: {
      retinalImageId: img2OD.id,
      passed: false,
      overallScore: 0.28,
      blurScore: 0.24, // < 0.40 threshold fail
      illuminationScore: 0.35,
      fovScore: 0.60,
      retakeReason: QualityRetakeReason.BLURRY,
      retakeInstructions:
        "Citra retina buram (indeks ketajaman: 0.24, batas minimal: 0.40). Terhalang pantulan kornea. Pastikan jarak 1.5 - 2 cm.",
    },
  });

  await prisma.reliabilityAssessment.create({
    data: {
      screeningId: scr2.id,
      status: ReliabilityStatus.RETAKE,
      score: 0.20,
      confidenceThreshold: 0.85,
      qualityThreshold: 0.75,
      reasoning: "Gagal uji kendali mutu citra awal (Quality Gate Fail). Penolakan prediksi otonom.",
    },
  });

  // Screening 3: Bapak Bambang Sudarmono -> HUMAN REVIEW PENDING (Borderline Reliability)
  const scr3 = await prisma.screening.upsert({
    where: { id: "scr-2026-0890" },
    update: {},
    create: {
      id: "scr-2026-0890",
      patientId: "pat-004",
      conductedById: userMap["usr-nakes-02"] || "usr-nakes-02",
      facilityId: "fac-mlati-02",
      status: ScreeningStatus.HUMAN_REVIEW,
      notes: "Kasus borderline pada area makula. Diteruskan ke dokter spesialis.",
      createdAt: new Date("2026-09-24T10:00:00Z"),
    },
  });

  const img3OD = await prisma.retinalImage.create({
    data: {
      screeningId: scr3.id,
      eye: EyePosition.OD,
      storageKey: "fundus/2026/09/scr-2026-0890-OD.jpg",
      mimeType: "image/jpeg",
      checksum: "b2c3d4e5f60123456789abcdef0123456789abcdef0123456789abcdef012345",
      fileSizeBytes: 265812,
    },
  });

  await prisma.qualityCheck.create({
    data: {
      retinalImageId: img3OD.id,
      passed: true,
      overallScore: 0.81,
      blurScore: 0.79,
      illuminationScore: 0.82,
      fovScore: 0.88,
    },
  });

  await prisma.aIResult.create({
    data: {
      screeningId: scr3.id,
      modelVersionId: modelVersion.id,
      predictedClass: DRClassification.MODERATE_DR,
      confidence: 0.62,
      rawProbabilities: {
        NO_DR: 0.05,
        MILD_DR: 0.28,
        MODERATE_DR: 0.62,
        SEVERE_DR: 0.04,
        PROLIFERATIVE_DR: 0.01,
      },
      inferenceDurationMs: 410,
    },
  });

  await prisma.reliabilityAssessment.create({
    data: {
      screeningId: scr3.id,
      status: ReliabilityStatus.HUMAN_REVIEW,
      score: 0.62,
      confidenceThreshold: 0.85,
      qualityThreshold: 0.75,
      reasoning:
        "Tingkat keyakinan model berada di bawah ambang batas (62% < 85%). Alur human-in-the-loop diaktifkan.",
    },
  });

  await prisma.humanReview.create({
    data: {
      screeningId: scr3.id,
      reviewerId: userMap["usr-doc-01"] || "usr-doc-01",
      reviewStatus: HumanReviewStatus.PENDING,
    },
  });

  // Screening 4: Ibu Endang Rahayu -> NO DR (Lolos Normal Rutin)
  const scr4 = await prisma.screening.upsert({
    where: { id: "scr-2026-0888" },
    update: {},
    create: {
      id: "scr-2026-0888",
      patientId: "pat-006",
      conductedById: userMap["usr-nakes-02"] || "usr-nakes-02",
      facilityId: "fac-mlati-02",
      status: ScreeningStatus.SCREENING_COMPLETED,
      notes: "Skrining tahunan rutin. Pasien tenang.",
      createdAt: new Date("2026-09-23T14:20:00Z"),
    },
  });

  const img4OS = await prisma.retinalImage.create({
    data: {
      screeningId: scr4.id,
      eye: EyePosition.OS,
      storageKey: "fundus/2026/09/scr-2026-0888-OS.jpg",
      mimeType: "image/jpeg",
      checksum: "c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef012345678",
      fileSizeBytes: 231412,
    },
  });

  await prisma.qualityCheck.create({
    data: {
      retinalImageId: img4OS.id,
      passed: true,
      overallScore: 0.94,
      blurScore: 0.91,
      illuminationScore: 0.93,
      fovScore: 0.97,
    },
  });

  await prisma.aIResult.create({
    data: {
      screeningId: scr4.id,
      modelVersionId: modelVersion.id,
      predictedClass: DRClassification.NO_DR,
      confidence: 0.968,
      rawProbabilities: {
        NO_DR: 0.968,
        MILD_DR: 0.025,
        MODERATE_DR: 0.005,
        SEVERE_DR: 0.002,
        PROLIFERATIVE_DR: 0.0,
      },
      inferenceDurationMs: 390,
    },
  });

  await prisma.reliabilityAssessment.create({
    data: {
      screeningId: scr4.id,
      status: ReliabilityStatus.ANALYZE,
      score: 0.97,
      confidenceThreshold: 0.85,
      qualityThreshold: 0.75,
      reasoning: "Citra retina prima, keyakinan model 96.8%. Tidak tampak lesi retinopati.",
    },
  });

  await prisma.recommendation.create({
    data: {
      screeningId: scr4.id,
      summary: "Tidak tampak tanda retinopati diabetik (No DR). Skrining ulang rutin tahunan (12 bulan) di FKTP.",
      recommendedAction: RecommendedAction.ROUTINE_ANNUAL_SCREENING,
      urgencyLevel: UrgencyLevel.LOW,
      referralIndicated: false,
      clinicalGuideline: "Konsensus Nasional Perdami 2024 / ADA 2024",
    },
  });

  await prisma.followUp.create({
    data: {
      patientId: "pat-006",
      screeningId: scr4.id,
      dueDate: new Date("2027-09-23T08:00:00Z"),
      status: FollowUpStatus.SCHEDULED,
    },
  });

  // ==========================================
  // 6. JEJAK AUDIT NON-REPUDIATION (PERMENKES 24/2022)
  // ==========================================
  console.log("🛡️ Seeding log audit kepatuhan rekam medis elektronik...");

  await prisma.auditLog.deleteMany({
    where: {
      action: {
        in: [
          "PATIENT_INTAKE_VERIFIED",
          "FUNDUS_QUALITY_CHECK_PASSED",
          "AI_MODEL_ACTIVE_VERIFIED",
          "HUMAN_REVIEW_QUEUE_VIEWED",
        ],
      },
    },
  });

  const auditLogsData = [
    {
      actorId: userMap["usr-nakes-01"] || "usr-nakes-01",
      actorRole: "HEALTHCARE_WORKER",
      action: "PATIENT_INTAKE_VERIFIED",
      resource: "Patient",
      resourceId: "pat-002",
      ipAddress: "192.168.1.42",
      userAgent: "RetivaMobile/1.0.0 (Android 14; Pixel 8)",
      metadata: { nik: "3404084501650002", informedConsentSigned: true },
    },
    {
      actorId: userMap["usr-nakes-01"] || "usr-nakes-01",
      actorRole: "HEALTHCARE_WORKER",
      action: "FUNDUS_QUALITY_CHECK_PASSED",
      resource: "QualityCheck",
      resourceId: img1OD.id,
      ipAddress: "192.168.1.42",
      userAgent: "RetivaMobile/1.0.0 (Android 14; Pixel 8)",
      metadata: { blurScore: 0.84, fovScore: 0.94 },
    },
    {
      actorId: userMap["usr-admin-01"] || "usr-admin-01",
      actorRole: "ADMIN",
      action: "AI_MODEL_ACTIVE_VERIFIED",
      resource: "ModelVersion",
      resourceId: modelVersion.id,
      ipAddress: "127.0.0.1",
      userAgent: "Next.js Core Gateway Server",
      metadata: { version: "efficientnet-b3-v1.0.0", status: "HEALTHY" },
    },
    {
      actorId: userMap["usr-doc-01"] || "usr-doc-01",
      actorRole: "OPHTHALMOLOGIST",
      action: "HUMAN_REVIEW_QUEUE_VIEWED",
      resource: "HumanReview",
      resourceId: scr3.id,
      ipAddress: "10.0.1.55",
      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128",
      metadata: { pendingCount: 1 },
    },
  ];

  for (const log of auditLogsData) {
    await prisma.auditLog.create({
      data: log,
    });
  }

  // ==========================================
  // MASTER MEAL ITEMS (ANEKA LAUK & MENU NUTRISI)
  // ==========================================
  console.log("🥗 Seeding aneka master data makanan nutrisi & lauk sehat...");
  try {
    await (prisma as any).masterMealItem.deleteMany({});
    for (const meal of COMPREHENSIVE_MASTER_MEALS) {
      await (prisma as any).masterMealItem.create({
        data: {
          id: meal.id,
          name: meal.name,
          category: meal.category,
          portion: meal.portion,
          estimatedCostIdr: meal.estimatedCostIdr,
          glycemicIndex: meal.glycemicIndex,
          carbsGrams: meal.carbsGrams,
          proteinGrams: meal.proteinGrams,
          ingredients: meal.ingredients,
          preparationNotes: meal.preparationNotes,
          isActive: meal.isActive,
        },
      });
    }
    console.log(`✅ Berhasil seeding ${COMPREHENSIVE_MASTER_MEALS.length} variasi menu & aneka lauk sehat diabetes.`);
  } catch (err: any) {
    console.warn("⚠️ Lewati seeding master_meal_items (tabel belum dimigrasi di DB):", err?.message);
  }

  console.log("✨ Seeding seluruh data medis relasional RETIVA selesai dengan sukses!");
}

main()
  .catch((e) => {
    console.error("❌ Error saat seeding data medis:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
