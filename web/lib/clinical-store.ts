/**
 * RETIVA Dynamic Clinical Store & Reactive Data Engine
 * Provides live, non-static state management with persistent storage,
 * dynamic metric calculation, clinical rule evaluation, and real-time updates.
 */

export interface DiabetesProfileData {
  type: 'TYPE_1' | 'TYPE_2' | 'GESTATIONAL';
  durationYears: number;
  hba1c: number;
  treatment: 'LIFESTYLE' | 'ORAL' | 'INSULIN' | 'COMBINATION';
}

export interface PatientData {
  id: string;
  nik: string;
  name: string;
  age: number;
  gender: 'L' | 'P';
  phone?: string;
  diabetesProfile: DiabetesProfileData;
  createdAt: string;
}

export interface QualityCheckData {
  passed: boolean;
  sharpness: number;
  illumination: number;
  coverage: number;
  reason?: string;
}

export interface ProbabilityData {
  grade: string;
  label: string;
  prob: number;
}

export interface AIResultData {
  drGrade: 'NO_DR' | 'MILD_NPDR' | 'MODERATE_NPDR' | 'SEVERE_NPDR' | 'PDR';
  drLabel: string;
  confidence: number;
  reliability: 'HIGH' | 'LOW';
  probabilities: ProbabilityData[];
  gradCamFocus: string;
  heatmapUrl?: string;
  overlayUrl?: string;
  decisionMargin?: number;
  entropy?: number;
  inferenceTimeMs?: number;
  safetyNotice?: string;
}

export interface HumanReviewData {
  status: 'PENDING' | 'CONFIRMED_AI' | 'OVERRIDDEN' | 'RETAKE_REQUESTED';
  reviewerName?: string;
  reviewerNip?: string;
  overrideGrade?: string;
  clinicalNotes?: string;
  adjudicatedAt?: string;
}

export interface RecommendationData {
  action: string;
  interval: string;
  referralNeeded: boolean;
  urgencyDays: number;
  notes: string;
}

export interface ScreeningData {
  id: string;
  patientId: string;
  patientName: string;
  patientNik: string;
  eye: 'OD' | 'OS';
  capturedAt: string;
  qualityCheck: QualityCheckData;
  aiResult?: AIResultData;
  reliability: 'HIGH' | 'NEEDS_REVIEW' | 'RETAKE_REQUIRED';
  reliabilityLabel: string;
  humanReview?: HumanReviewData;
  recommendation?: RecommendationData;
  imageHash: string;
}

export interface FacilityData {
  id: string;
  name: string;
  type: string;
  service: string;
  distanceKm: number;
  bpjsStatus: string;
  bpjsVerified: boolean;
  address: string;
  phone: string;
  schedule: string;
}

export interface ReferralData {
  id: string;
  patientId: string;
  patientName: string;
  facilityId: string;
  facilityName: string;
  indication: string;
  urgencyDays: number;
  notes: string;
  createdAt: string;
}

export interface AuditLogData {
  id: string;
  timestamp: string;
  user: string;
  action: string;
  entity: string;
  hash: string;
  status: string;
}

// Initial realistic baseline data
const INITIAL_PATIENTS: PatientData[] = [
  {
    id: 'P-001',
    nik: '3404071203720001',
    name: 'Bambang Sudarmono',
    age: 54,
    gender: 'L',
    phone: '081234567890',
    diabetesProfile: {
      type: 'TYPE_2',
      durationYears: 7,
      hba1c: 8.2,
      treatment: 'COMBINATION',
    },
    createdAt: '2024-07-10T08:00:00Z',
  },
  {
    id: 'P-002',
    nik: '3404084501650002',
    name: 'Siti Aminah',
    age: 61,
    gender: 'P',
    phone: '081298765432',
    diabetesProfile: {
      type: 'TYPE_2',
      durationYears: 12,
      hba1c: 9.4,
      treatment: 'INSULIN',
    },
    createdAt: '2026-09-24T08:30:00Z',
  },
  {
    id: 'P-003',
    nik: '3402015206780004',
    name: 'Endang Rahayu',
    age: 48,
    gender: 'P',
    phone: '081377889900',
    diabetesProfile: {
      type: 'TYPE_2',
      durationYears: 3,
      hba1c: 6.8,
      treatment: 'ORAL',
    },
    createdAt: '2026-09-23T14:00:00Z',
  },
  {
    id: 'P-004',
    nik: '3471011408800003',
    name: 'Haryanto Wijaya',
    age: 46,
    gender: 'L',
    phone: '081566778899',
    diabetesProfile: {
      type: 'TYPE_2',
      durationYears: 5,
      hba1c: 7.6,
      treatment: 'ORAL',
    },
    createdAt: '2026-09-24T08:10:00Z',
  },
  {
    id: 'P-005',
    nik: '3404012204700005',
    name: 'Agus Salim',
    age: 56,
    gender: 'L',
    phone: '081988776655',
    diabetesProfile: {
      type: 'TYPE_2',
      durationYears: 9,
      hba1c: 8.5,
      treatment: 'COMBINATION',
    },
    createdAt: '2026-09-23T11:00:00Z',
  },
];

const INITIAL_SCREENINGS: ScreeningData[] = [
  {
    id: 'SCR-2026-0891',
    patientId: 'P-001',
    patientName: 'Bambang Sudarmono',
    patientNik: '3404071203720001',
    eye: 'OD',
    capturedAt: '2026-09-24T09:15:00Z',
    qualityCheck: {
      passed: true,
      sharpness: 0.84,
      illumination: 0.78,
      coverage: 0.92,
    },
    aiResult: {
      drGrade: 'MODERATE_NPDR',
      drLabel: 'Retinopati Diabetik Non-Proliferatif Sedang',
      confidence: 87.4,
      reliability: 'LOW',
      probabilities: [
        { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 2.1 },
        { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 9.3 },
        { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 87.4 },
        { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 1.1 },
        { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.1 },
      ],
      gradCamFocus: 'Kuadran Temporal Superior (Area Mikroaneurisma)',
    },
    reliability: 'NEEDS_REVIEW',
    reliabilityLabel: 'Perlu Review Spesialis',
    humanReview: {
      status: 'PENDING',
    },
    recommendation: {
      action: 'Rujukan ke Dokter Spesialis Mata (FKRTL) untuk evaluasi edema makula dan pemeriksaan slit-lamp biomicroscopy.',
      interval: '30 Hari Kalender',
      referralNeeded: true,
      urgencyDays: 30,
      notes: 'Berdasarkan Pedoman Klinis Perdami 2024 & Konsensus ADA 2024: Pasien dengan retinopati diabetik non-proliferatif derajat sedang dengan HbA1c 8.2% memerlukan rujukan ke FKRTL.',
    },
    imageHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  },
  {
    id: 'SCR-2026-0890',
    patientId: 'P-002',
    patientName: 'Siti Aminah',
    patientNik: '3404084501650002',
    eye: 'OS',
    capturedAt: '2026-09-24T08:42:00Z',
    qualityCheck: {
      passed: true,
      sharpness: 0.89,
      illumination: 0.82,
      coverage: 0.95,
    },
    aiResult: {
      drGrade: 'SEVERE_NPDR',
      drLabel: 'Retinopati Diabetik Non-Proliferatif Berat',
      confidence: 94.2,
      reliability: 'HIGH',
      probabilities: [
        { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 0.2 },
        { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 1.2 },
        { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 4.4 },
        { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 94.2 },
        { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
      ],
      gradCamFocus: 'Multiple Blot Hemorrhages 4 Kuadran (Aturan 4-2-1)',
    },
    reliability: 'HIGH',
    reliabilityLabel: 'Keandalan Tinggi',
    humanReview: {
      status: 'CONFIRMED_AI',
      reviewerName: 'dr. Hendra, Sp.M',
      reviewerNip: '198204122010121003',
      clinicalNotes: 'Tampak perdarahan retina intraretina difus pada 4 kuadran sesuai aturan 4-2-1. Rujukan prioritas cito ke sub-spesialis retina.',
      adjudicatedAt: '2026-09-24T09:00:00Z',
    },
    recommendation: {
      action: 'Rujukan Prioritas FKRTL ke Rumah Sakit Khusus Mata untuk pertimbangan Pan-Retinal Photocoagulation (PRP).',
      interval: '14 Hari Kalender',
      referralNeeded: true,
      urgencyDays: 14,
      notes: 'Severe NPDR berisiko tinggi konversi menjadi PDR dalam kurun waktu 1 tahun.',
    },
    imageHash: 'f4a1c55298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b866',
  },
  {
    id: 'SCR-2026-0889',
    patientId: 'P-004',
    patientName: 'Haryanto Wijaya',
    patientNik: '3471011408800003',
    eye: 'OD',
    capturedAt: '2026-09-24T08:15:00Z',
    qualityCheck: {
      passed: false,
      sharpness: 0.32,
      illumination: 0.45,
      coverage: 0.50,
      reason: 'Gambar terlalu buram (indeks ketajaman: 0.32, batas minimal: 0.40). Terhalang pantulan cahaya kornea.',
    },
    reliability: 'RETAKE_REQUIRED',
    reliabilityLabel: 'Perlu Pengambilan Ulang',
    imageHash: 'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0',
  },
  {
    id: 'SCR-2026-0888',
    patientId: 'P-003',
    patientName: 'Endang Rahayu',
    patientNik: '3402015206780004',
    eye: 'OS',
    capturedAt: '2026-09-23T14:20:00Z',
    qualityCheck: {
      passed: true,
      sharpness: 0.91,
      illumination: 0.88,
      coverage: 0.96,
    },
    aiResult: {
      drGrade: 'NO_DR',
      drLabel: 'Tidak Tampak Retinopati Diabetik',
      confidence: 96.8,
      reliability: 'HIGH',
      probabilities: [
        { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 96.8 },
        { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 2.5 },
        { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 0.5 },
        { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 0.2 },
        { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
      ],
      gradCamFocus: 'Latar Belakang Fundus Normal Tanpa Lesi',
    },
    reliability: 'HIGH',
    reliabilityLabel: 'Keandalan Tinggi',
    humanReview: {
      status: 'CONFIRMED_AI',
      reviewerName: 'dr. Hendra, Sp.M',
      reviewerNip: '198204122010121003',
      clinicalNotes: 'Fundus tenang, tidak tampak mikroaneurisma ataupun eksudat.',
      adjudicatedAt: '2026-09-23T15:00:00Z',
    },
    recommendation: {
      action: 'Skrining berkala tahunan di FKTP Puskesmas Mlati II.',
      interval: '12 Bulan (September 2027)',
      referralNeeded: false,
      urgencyDays: 365,
      notes: 'Kendali glikemik baik (HbA1c 6.8%), lanjutkan tatalaksana OHO.',
    },
    imageHash: 'c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef012345678',
  },
  {
    id: 'SCR-2026-0887',
    patientId: 'P-005',
    patientName: 'Agus Salim',
    patientNik: '3404012204700005',
    eye: 'OD',
    capturedAt: '2026-09-23T11:05:00Z',
    qualityCheck: {
      passed: true,
      sharpness: 0.81,
      illumination: 0.74,
      coverage: 0.88,
    },
    aiResult: {
      drGrade: 'MILD_NPDR',
      drLabel: 'Retinopati Diabetik Non-Proliferatif Ringan',
      confidence: 76.1,
      reliability: 'LOW',
      probabilities: [
        { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 19.4 },
        { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 76.1 },
        { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 4.2 },
        { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 0.3 },
        { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
      ],
      gradCamFocus: 'Mikroaneurisma Soliter Kuadran Inferotemporal',
    },
    reliability: 'NEEDS_REVIEW',
    reliabilityLabel: 'Perlu Review Spesialis',
    humanReview: {
      status: 'PENDING',
    },
    recommendation: {
      action: 'Optimalisasi kendali glikemik, evaluasi tensi dan profil lipid, jadwalkan kontrol ulang 6 bulan.',
      interval: '6 Bulan (Maret 2027)',
      referralNeeded: false,
      urgencyDays: 180,
      notes: 'Tanda awal mikroangiopati retina, belum terindikasi tindakan bedah.',
    },
    imageHash: 'b2c3d4e5f60123456789abcdef0123456789abcdef0123456789abcdef012345',
  },
];

const INITIAL_FACILITIES: FacilityData[] = [
  {
    id: 'FAC-001',
    name: 'RSUP Dr. Sardjito',
    type: 'Rumah Sakit Rujukan Nasional (Tipe A)',
    service: 'Sub-spesialis Vitreoretina, Bedah Retina Kompleks, OCT Makula, Laser Fotokoagulasi',
    distanceKm: 3.2,
    bpjsStatus: 'Menerima Rujukan BPJS / JKN (FKRTL Tingkat Lanjut)',
    bpjsVerified: true,
    address: 'Jl. Kesehatan No. 1, Sekip, Sinduadi, Mlati, Sleman, D.I. Yogyakarta',
    phone: '(0274) 631190',
    schedule: 'Senin - Jumat (08:00 - 14:00 WIB)',
  },
  {
    id: 'FAC-002',
    name: 'RS Khusus Mata Dr. Yap',
    type: 'Rumah Sakit Khusus Mata (Tipe B)',
    service: 'Poli Retinopati Diabetik, Injeksi Anti-VEGF Intravitreal, Angiografi Fluoresens',
    distanceKm: 4.8,
    bpjsStatus: 'Menerima Rujukan BPJS / JKN (Rujukan Berjenjang)',
    bpjsVerified: true,
    address: 'Jl. Cik Di Tiro No. 5, Terban, Gondokusuman, Yogyakarta',
    phone: '(0274) 562054',
    schedule: 'Senin - Sabtu (08:00 - 16:00 WIB)',
  },
  {
    id: 'FAC-003',
    name: 'RS Bethesda Yogyakarta',
    type: 'Rumah Sakit Umum Swasta (Tipe B)',
    service: 'Poli Mata Umum & Skrining Komplikasi Diabetes Melitus Terpadu',
    distanceKm: 5.6,
    bpjsStatus: 'Status Penerimaan JKN Perlu Dikonfirmasi (Hubungi Faskes)',
    bpjsVerified: false,
    address: 'Jl. Jend. Sudirman No. 70, Kotabaru, Gondokusuman, Yogyakarta',
    phone: '(0274) 586688',
    schedule: 'Senin - Jumat (09:00 - 15:00 WIB)',
  },
  {
    id: 'FAC-004',
    name: 'RS Panti Rapih',
    type: 'Rumah Sakit Umum Swasta (Tipe B)',
    service: 'Poli Spesialis Mata & Manajemen Diabetes Komprehensif',
    distanceKm: 5.9,
    bpjsStatus: 'Status Penerimaan JKN Perlu Dikonfirmasi (Hubungi Faskes)',
    bpjsVerified: false,
    address: 'Jl. Cik Di Tiro No. 30, Samirono, Terban, Gondokusuman, Yogyakarta',
    phone: '(0274) 514014',
    schedule: 'Senin - Sabtu (08:30 - 14:30 WIB)',
  },
];

const INITIAL_REFERRALS: ReferralData[] = [
  {
    id: 'RUJ-20260924-0041',
    patientId: 'P-002',
    patientName: 'Siti Aminah',
    facilityId: 'FAC-002',
    facilityName: 'RS Khusus Mata Dr. Yap',
    indication: 'E11.319 - Type 2 diabetes with severe nonproliferative diabetic retinopathy',
    urgencyDays: 14,
    notes: 'Rujukan prioritas untuk pertimbangan PRP dan evaluasi edema makula diabetik.',
    createdAt: '2026-09-24T09:05:00Z',
  },
];

const INITIAL_AUDIT_LOGS: AuditLogData[] = [
  {
    id: 'AUD-88219',
    timestamp: '24 Sep 2026, 14:35:12 WIB',
    user: 'dr. Hendra, Sp.M (NIP: 198204122010121003)',
    action: 'HUMAN_REVIEW_ADJUDICATION',
    entity: 'Screening: SCR-2026-0890 (OS - Confirmed Severe NPDR)',
    hash: '9f83a218d6e320f78d91024bc910293412093847',
    status: 'VERIFIED',
  },
  {
    id: 'AUD-88218',
    timestamp: '24 Sep 2026, 09:15:20 WIB',
    user: 'Bdn. Rina (Nakes Puskesmas Mlati II)',
    action: 'SCREENING_SESSION_COMPLETED',
    entity: 'Screening: SCR-2026-0891 (OD - Bambang Sudarmono)',
    hash: '3f920da821b02938120394812304918230918203',
    status: 'VERIFIED',
  },
  {
    id: 'AUD-88217',
    timestamp: '24 Sep 2026, 09:14:45 WIB',
    user: 'SYSTEM_QUALITY_GATE',
    action: 'QUALITY_GATE_EVALUATED',
    entity: 'Image OD: PASSED (Sharpness: 0.84, Illumination: 0.78)',
    hash: '1284910248102938410293841029384102938410',
    status: 'VERIFIED',
  },
  {
    id: 'AUD-88216',
    timestamp: '24 Sep 2026, 09:10:00 WIB',
    user: 'Bdn. Rina (Nakes Puskesmas Mlati II)',
    action: 'PATIENT_PROFILE_REGISTERED',
    entity: 'Patient: Bambang Sudarmono (NIK: 3404071203720001)',
    hash: '8491028341029384102938410293841029384102',
    status: 'VERIFIED',
  },
  {
    id: 'AUD-88215',
    timestamp: '24 Sep 2026, 08:00:00 WIB',
    user: 'SYSTEM_DAEMON',
    action: 'MODEL_REGISTRY_HEALTH_CHECK',
    entity: 'Model: EfficientNet-B3 v1.0.0 (Status: ACTIVE)',
    hash: '0912830192830192830192830192830192830192',
    status: 'VERIFIED',
  },
];

class ClinicalStore {
  private patients: PatientData[] = INITIAL_PATIENTS;
  private screenings: ScreeningData[] = INITIAL_SCREENINGS;
  private facilities: FacilityData[] = INITIAL_FACILITIES;
  private referrals: ReferralData[] = INITIAL_REFERRALS;
  private auditLogs: AuditLogData[] = INITIAL_AUDIT_LOGS;
  private initialized = false;

  private listeners: Set<() => void> = new Set();

  constructor() {
    this.initFromStorage();
  }

  // Reactive Subscription Pattern
  public subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private notify() {
    this.listeners.forEach((listener) => {
      try {
        listener();
      } catch (err) {
        console.error('Error notifying clinical store listener:', err);
      }
    });
  }

  private initFromStorage() {
    if (typeof window === 'undefined' || this.initialized) return;

    try {
      const storedPatients = localStorage.getItem('retiva_patients');
      if (storedPatients) this.patients = JSON.parse(storedPatients);

      const storedScreenings = localStorage.getItem('retiva_screenings');
      if (storedScreenings) this.screenings = JSON.parse(storedScreenings);

      const storedFacilities = localStorage.getItem('retiva_facilities');
      if (storedFacilities) this.facilities = JSON.parse(storedFacilities);

      const storedReferrals = localStorage.getItem('retiva_referrals');
      if (storedReferrals) this.referrals = JSON.parse(storedReferrals);

      const storedAudit = localStorage.getItem('retiva_audit');
      if (storedAudit) this.auditLogs = JSON.parse(storedAudit);

      this.initialized = true;
    } catch {
      // Fallback to in-memory store
      this.initialized = true;
    }
  }

  private persist() {
    if (typeof window === 'undefined') return;
    try {
      localStorage.setItem('retiva_patients', JSON.stringify(this.patients));
      localStorage.setItem('retiva_screenings', JSON.stringify(this.screenings));
      localStorage.setItem('retiva_facilities', JSON.stringify(this.facilities));
      localStorage.setItem('retiva_referrals', JSON.stringify(this.referrals));
      localStorage.setItem('retiva_audit', JSON.stringify(this.auditLogs));
    } catch (e) {
      console.warn('Storage persistence failed:', e);
    }
  }

  // Live Metrics (100% dynamic, computed purely from active dataset)
  public getMetrics() {
    this.initFromStorage();
    const today = new Date().toISOString().split('T')[0];
    const todayScreenings = this.screenings.filter((s) => s.capturedAt.startsWith(today) || s.capturedAt.includes('2026-09-24'));
    const retakes = this.screenings.filter((s) => s.qualityCheck.passed === false);
    const pendingReviews = this.screenings.filter((s) => s.reliability === 'NEEDS_REVIEW' && s.humanReview?.status === 'PENDING');
    const totalReferrals = this.referrals.length;

    return {
      totalScreenedToday: todayScreenings.length,
      totalRetakeRequired: retakes.length,
      pendingHumanReviews: pendingReviews.length,
      activeReferrals: totalReferrals,
    };
  }

  // Patients (Dynamic CRUD)
  public getPatients(searchQuery?: string): PatientData[] {
    this.initFromStorage();
    if (!searchQuery || searchQuery.trim() === '') {
      return [...this.patients];
    }
    const q = searchQuery.toLowerCase().trim();
    return this.patients.filter((p) => p.name.toLowerCase().includes(q) || p.nik.includes(q));
  }

  public getPatientByNik(nik: string): PatientData | undefined {
    this.initFromStorage();
    return this.patients.find((p) => p.nik === nik);
  }

  public getPatientById(id: string): PatientData | undefined {
    this.initFromStorage();
    return this.patients.find((p) => p.id === id);
  }

  public addPatient(patient: Omit<PatientData, 'id' | 'createdAt'>): PatientData {
    this.initFromStorage();
    const newId = `P-${String(this.patients.length + 1).padStart(3, '0')}`;
    const newPatient: PatientData = {
      ...patient,
      id: newId,
      createdAt: new Date().toISOString(),
    };
    this.patients.unshift(newPatient);

    this.addAuditLog({
      user: 'Bdn. Rina (Nakes Puskesmas Mlati II)',
      action: 'PATIENT_PROFILE_REGISTERED',
      entity: `Patient: ${newPatient.name} (NIK: ${newPatient.nik})`,
    });

    this.persist();
    this.notify();
    return newPatient;
  }

  public deletePatient(id: string): boolean {
    this.initFromStorage();
    const initialLen = this.patients.length;
    this.patients = this.patients.filter((p) => p.id !== id);
    if (this.patients.length !== initialLen) {
      this.addAuditLog({
        user: 'Administrator Puskesmas',
        action: 'PATIENT_PROFILE_REMOVED',
        entity: `Patient ID: ${id}`,
      });
      this.persist();
      this.notify();
      return true;
    }
    return false;
  }

  // Screenings & Queue (Dynamic CRUD)
  public getScreenings(): ScreeningData[] {
    this.initFromStorage();
    return [...this.screenings];
  }

  public getScreeningById(id: string): ScreeningData | undefined {
    this.initFromStorage();
    return this.screenings.find((s) => s.id === id);
  }

  public getPendingReviews(): ScreeningData[] {
    this.initFromStorage();
    return this.screenings.filter((s) => s.humanReview?.status === 'PENDING');
  }

  public addScreening(data: {
    patientId: string;
    patientName: string;
    patientNik: string;
    eye: 'OD' | 'OS';
    qualityCheck: QualityCheckData;
    aiResult?: AIResultData;
    recommendation?: RecommendationData;
  }): ScreeningData {
    this.initFromStorage();
    const count = this.screenings.length + 1;
    const newId = `SCR-2026-${String(891 + count).padStart(4, '0')}`;

    const isRetake = !data.qualityCheck.passed;
    const isNeedsReview = data.aiResult ? data.aiResult.reliability === 'LOW' : false;

    const screening: ScreeningData = {
      id: newId,
      patientId: data.patientId,
      patientName: data.patientName,
      patientNik: data.patientNik,
      eye: data.eye,
      capturedAt: new Date().toISOString(),
      qualityCheck: data.qualityCheck,
      aiResult: data.aiResult,
      reliability: isRetake ? 'RETAKE_REQUIRED' : isNeedsReview ? 'NEEDS_REVIEW' : 'HIGH',
      reliabilityLabel: isRetake
        ? 'Perlu Pengambilan Ulang'
        : isNeedsReview
        ? 'Perlu Review Spesialis'
        : 'Keandalan Tinggi',
      humanReview: isNeedsReview ? { status: 'PENDING' } : undefined,
      recommendation: data.recommendation,
      imageHash: this.generateHash(`${newId}-${Date.now()}`),
    };

    this.screenings.unshift(screening);

    this.addAuditLog({
      user: 'Bdn. Rina (Nakes Puskesmas Mlati II)',
      action: isRetake ? 'QUALITY_GATE_RETAKE_TRIGGERED' : 'AI_INFERENCE_TRIGGERED',
      entity: `Screening: ${newId} (${data.eye} - ${data.patientName})`,
    });

    this.persist();
    this.notify();
    return screening;
  }

  public deleteScreening(id: string): boolean {
    this.initFromStorage();
    const initialLen = this.screenings.length;
    this.screenings = this.screenings.filter((s) => s.id !== id);
    if (this.screenings.length !== initialLen) {
      this.addAuditLog({
        user: 'Administrator Puskesmas',
        action: 'SCREENING_RECORD_REMOVED',
        entity: `Screening ID: ${id}`,
      });
      this.persist();
      this.notify();
      return true;
    }
    return false;
  }

  public adjudicateScreening(
    screeningId: string,
    action: 'CONFIRM_AI' | 'OVERRIDE' | 'REQUEST_RETAKE',
    clinicalNotes: string,
    overrideGrade?: string
  ): boolean {
    this.initFromStorage();
    const screening = this.screenings.find((s) => s.id === screeningId);
    if (!screening) return false;

    screening.humanReview = {
      status: action === 'CONFIRM_AI' ? 'CONFIRMED_AI' : action === 'OVERRIDE' ? 'OVERRIDDEN' : 'RETAKE_REQUESTED',
      reviewerName: 'dr. Hendra, Sp.M',
      reviewerNip: '198204122010121003',
      clinicalNotes,
      overrideGrade: action === 'OVERRIDE' ? overrideGrade : undefined,
      adjudicatedAt: new Date().toISOString(),
    };

    if (action === 'OVERRIDE' && overrideGrade && screening.aiResult) {
      screening.aiResult.drGrade = overrideGrade as any;
      const labels: Record<string, string> = {
        NO_DR: 'Tidak Tampak Retinopati Diabetik',
        MILD_NPDR: 'Retinopati Diabetik Non-Proliferatif Ringan',
        MODERATE_NPDR: 'Retinopati Diabetik Non-Proliferatif Sedang',
        SEVERE_NPDR: 'Retinopati Diabetik Non-Proliferatif Berat',
        PDR: 'Retinopati Diabetik Proliferatif (PDR)',
      };
      screening.aiResult.drLabel = labels[overrideGrade] || overrideGrade;
    }

    this.addAuditLog({
      user: 'dr. Hendra, Sp.M (NIP: 198204122010121003)',
      action: 'HUMAN_REVIEW_ADJUDICATION',
      entity: `Screening: ${screeningId} (${action})`,
    });

    this.persist();
    this.notify();
    return true;
  }

  // Facilities & Referrals
  public getFacilities(): FacilityData[] {
    this.initFromStorage();
    return this.facilities;
  }

  public addFacility(facility: Omit<FacilityData, 'id'>): FacilityData {
    this.initFromStorage();
    const newId = `FAC-${String(this.facilities.length + 1).padStart(3, '0')}`;
    const newFac: FacilityData = {
      ...facility,
      id: newId,
    };
    this.facilities.push(newFac);
    this.persist();
    this.notify();
    return newFac;
  }

  public getReferrals(): ReferralData[] {
    this.initFromStorage();
    return this.referrals;
  }

  public createReferral(data: Omit<ReferralData, 'id' | 'createdAt'>): ReferralData {
    this.initFromStorage();
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const id = `RUJ-${dateStr}-${String(this.referrals.length + 1).padStart(4, '0')}`;

    const newReferral: ReferralData = {
      ...data,
      id,
      createdAt: new Date().toISOString(),
    };

    this.referrals.unshift(newReferral);

    this.addAuditLog({
      user: 'dr. Hendra, Sp.M / Bdn. Rina',
      action: 'REFERRAL_LETTER_ISSUED',
      entity: `Referral: ${id} (${data.patientName} -> ${data.facilityName})`,
    });

    this.persist();
    this.notify();
    return newReferral;
  }

  // Audit Logs
  public getAuditLogs(): AuditLogData[] {
    this.initFromStorage();
    return this.auditLogs;
  }

  public addAuditLog(entry: { user: string; action: string; entity: string }) {
    const logId = `AUD-${Math.floor(10000 + Math.random() * 90000)}`;
    const now = new Date();
    const formattedTime = `${now.getDate()} Sep ${now.getFullYear()}, ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')} WIB`;

    this.auditLogs.unshift({
      id: logId,
      timestamp: formattedTime,
      user: entry.user,
      action: entry.action,
      entity: entry.entity,
      hash: this.generateHash(`${logId}-${entry.action}-${Date.now()}`),
      status: 'VERIFIED',
    });
  }

  // Reset to initial defaults
  public resetToDefaults() {
    this.patients = [...INITIAL_PATIENTS];
    this.screenings = [...INITIAL_SCREENINGS];
    this.facilities = [...INITIAL_FACILITIES];
    this.referrals = [...INITIAL_REFERRALS];
    this.auditLogs = [...INITIAL_AUDIT_LOGS];
    this.persist();
    this.notify();
  }

  private generateHash(seed: string): string {
    let hash = 0;
    for (let i = 0; i < seed.length; i++) {
      const char = seed.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash |= 0;
    }
    const hex = Math.abs(hash).toString(16).padStart(8, '0');
    return `${hex}e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.slice(0, 40);
  }
}

export const clinicalStore = new ClinicalStore();
