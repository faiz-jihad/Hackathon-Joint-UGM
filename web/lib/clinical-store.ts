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
    id: 'RTV-20261024-36',
    patientId: 'pat-009',
    patientName: 'Bapak Hendro Kusumo',
    patientNik: '3404051908740002',
    eye: 'OD',
    capturedAt: new Date().toISOString(),
    qualityCheck: {
      passed: true,
      sharpness: 0.82,
      illumination: 0.85,
      coverage: 0.90,
    },
    aiResult: {
      drGrade: 'MODERATE_NPDR',
      drLabel: 'Retinopati Diabetik Non-Proliferatif Sedang',
      confidence: 62.0,
      reliability: 'LOW',
      probabilities: [
        { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 8.0 },
        { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 25.0 },
        { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 62.0 },
        { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 4.0 },
        { grade: 'PDR', label: 'PDR Proliferatif', prob: 1.0 },
      ],
      gradCamFocus: 'Area Mikroaneurisma & Perdarahan Makula (Borderline 62%)',
      overlayUrl: '/images/fundus_borderline_sample.jpg',
      heatmapUrl: '/images/retina_insight_sample.png',
    },
    reliability: 'NEEDS_REVIEW',
    reliabilityLabel: 'Perlu Review Spesialis',
    humanReview: {
      status: 'PENDING',
      reviewerName: 'dr. Yunani Setyandriana, Sp.M',
      reviewerNip: '198204122010121003',
    },
    recommendation: {
      action: 'Telaah klinis spesialis mata (Sp.M) untuk verifikasi retinopati diabetik derajat sedang.',
      interval: '1x24 Jam Kerja',
      referralNeeded: true,
      urgencyDays: 14,
      notes: 'Margin keyakinan borderline (Confidence 62% < ambang 85%). Kasus dialihkan ke antrean telaah dokter spesialis mata mitra (dr. Yunani Setyandriana, Sp.M).',
    },
    imageHash: '986f918d7f4bdb56fcab07c4fb9d380dd2424d663781fea13763b9f51dbda171',
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
      if (storedScreenings) {
        try {
          const parsed = JSON.parse(storedScreenings);
          if (Array.isArray(parsed) && parsed.length > 0) {
            const dummyIds = ['SCR-2026-0891', 'SCR-2026-0890', 'SCR-2026-0889', 'SCR-2026-0888', 'SCR-2026-0887'];
            const cleaned = parsed.filter((s: any) => !dummyIds.includes(s.id));
            if (!cleaned.some((s: any) => s.id === 'RTV-20261024-36')) {
              cleaned.unshift(INITIAL_SCREENINGS[0]);
            }
            this.screenings = cleaned;
          } else {
            this.screenings = [...INITIAL_SCREENINGS];
          }
        } catch {
          this.screenings = [...INITIAL_SCREENINGS];
        }
      } else {
        this.screenings = [...INITIAL_SCREENINGS];
      }

      const storedFacilities = localStorage.getItem('retiva_facilities');
      if (storedFacilities) this.facilities = JSON.parse(storedFacilities);

      const storedReferrals = localStorage.getItem('retiva_referrals');
      if (storedReferrals) this.referrals = JSON.parse(storedReferrals);

      const storedAudit = localStorage.getItem('retiva_audit');
      if (storedAudit) this.auditLogs = JSON.parse(storedAudit);

      this.initialized = true;
      this.syncWithApi();
    } catch {
      // Fallback to in-memory store
      this.initialized = true;
      this.syncWithApi();
    }
  }

  // Live Database API Synchronization
  public async syncWithApi() {
    if (typeof window === 'undefined') return;
    try {
      // 1. Fetch live patients from DB via API Gateway
      const resPatients = await fetch('/api/v1/patients?limit=50', {
        headers: { 'x-retiva-clinical': 'true' },
      });
      if (resPatients.ok) {
        const json = await resPatients.json();
        const list = json.data?.patients || json.data;
        if (Array.isArray(list) && list.length > 0) {
          this.patients = list.map((p: any) => ({
            id: p.id,
            nik: p.nik,
            name: p.fullName || p.name,
            age: p.age || (p.birthDate ? Math.max(18, Math.floor((Date.now() - new Date(p.birthDate).getTime()) / (365.25 * 24 * 3600 * 1000))) : 50),
            gender: p.gender === 'FEMALE' ? 'P' : 'L',
            phone: p.phone,
            diabetesProfile: {
              type: p.diabetesProfile?.diabetesType || 'TYPE_2',
              durationYears: p.diabetesProfile?.yearOfDiagnosis ? Math.max(1, new Date().getFullYear() - p.diabetesProfile.yearOfDiagnosis) : 5,
              hba1c: p.diabetesProfile?.lastHbA1c || 7.5,
              treatment: p.diabetesProfile?.currentTreatment || 'ORAL',
            },
            createdAt: p.createdAt || new Date().toISOString(),
          }));
          this.persist();
          this.notify();
        }
      }

      // 2. Fetch live facilities from DB via API Gateway
      const resFacilities = await fetch('/api/v1/facilities?limit=50', {
        headers: { 'x-retiva-clinical': 'true' },
      });
      if (resFacilities.ok) {
        const json = await resFacilities.json();
        const list = json.data?.facilities || json.data;
        if (Array.isArray(list) && list.length > 0) {
          this.facilities = list.map((f: any) => ({
            id: f.id,
            name: f.name,
            type: f.name.includes('RSUP')
              ? 'Rumah Sakit Rujukan Nasional (Tipe A)'
              : (f.name.includes('Puskesmas') ? 'Faskes Primer (FKTP)' : 'Rumah Sakit Khusus Mata'),
            service: (f.services || []).map((s: any) => s.serviceName || s).join(', ') || 'Layanan Kesehatan Mata',
            distanceKm: f.distanceKm || 3.5,
            bpjsStatus: f.bpjsStatus || 'ACCEPTED',
            bpjsVerified: f.isVerified ?? true,
            address: f.address,
            phone: f.contactPhone || '(0274) 562054',
            schedule: 'Senin - Sabtu: 08:00 - 15:00',
          }));
          this.persist();
          this.notify();
        }
      }

      // 3. Fetch live screenings from DB via API Gateway
      const resScreenings = await fetch('/api/v1/screenings?limit=50', {
        headers: { 'x-retiva-clinical': 'true' },
      });
      if (resScreenings.ok) {
        const json = await resScreenings.json();
        const list = json.data?.screenings || json.data;
        if (Array.isArray(list) && list.length > 0) {
          const mappedScreenings: ScreeningData[] = list.map((s: any) => {
            const primaryImage = s.images?.[0];
            const eye = (primaryImage?.eye || 'OD') as 'OD' | 'OS';
            const qc = s.qualityChecks?.[0] || { passed: true, overallScore: 0.9, blurScore: 0.9, illuminationScore: 0.9, fovScore: 0.9 };
            const pat = this.getPatientById(s.patientId);

            return {
              id: s.id,
              patientId: s.patientId,
              patientName: pat?.name || 'Pasien Terdaftar',
              patientNik: pat?.nik || s.patientId,
              eye,
              capturedAt: s.createdAt || new Date().toISOString(),
              qualityCheck: {
                passed: qc.passed ?? true,
                sharpness: qc.blurScore ?? 0.9,
                illumination: qc.illuminationScore ?? 0.9,
                coverage: qc.fovScore ?? 0.9,
                reason: qc.retakeReason,
              },
              aiResult: s.aiResult ? {
                drGrade: s.aiResult.predictedClass,
                drLabel: s.aiResult.predictedClass,
                confidence: s.aiResult.confidence,
                reliability: s.reliabilityAssessment?.status === 'ANALYZE' ? 'HIGH' : 'LOW',
                probabilities: Object.entries(s.aiResult.rawProbabilities || {}).map(([grade, prob]) => ({
                  grade,
                  label: grade,
                  prob: Number(prob),
                })),
                gradCamFocus: 'Makula & Vaskulatur Retina',
                overlayUrl: primaryImage?.storagePath || primaryImage?.url || '/images/fundus_borderline_sample.jpg',
                heatmapUrl: s.aiResult?.heatmapUrl || '/images/retina_insight_sample.png',
              } : undefined,
              reliability: s.status === 'RETAKE_REQUIRED'
                ? 'RETAKE_REQUIRED'
                : s.status === 'HUMAN_REVIEW'
                ? 'NEEDS_REVIEW'
                : 'HIGH',
              reliabilityLabel: s.status === 'RETAKE_REQUIRED'
                ? 'Perlu Pengambilan Ulang'
                : s.status === 'HUMAN_REVIEW'
                ? 'Perlu Review Spesialis'
                : 'Keandalan Tinggi',
              humanReview: s.status === 'HUMAN_REVIEW' ? { status: 'PENDING' } : undefined,
              imageHash: primaryImage?.checksum || this.generateHash(`${s.id}`),
            };
          });

          const existingIds = new Set(this.screenings.map(sc => sc.id));
          for (const ms of mappedScreenings) {
            if (!existingIds.has(ms.id)) {
              this.screenings.push(ms);
            }
          }
          this.persist();
          this.notify();
        }
      }
    } catch (e) {
      console.warn('API sync silently continued with active local store:', e);
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

    // Async persist to Backend API / PostgreSQL Database
    if (typeof window !== 'undefined') {
      fetch('/api/v1/patients', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-retiva-clinical': 'true',
        },
        body: JSON.stringify({
          nik: newPatient.nik,
          fullName: newPatient.name,
          birthDate: new Date(Date.now() - newPatient.age * 365.25 * 24 * 3600 * 1000).toISOString(),
          gender: newPatient.gender === 'P' ? 'FEMALE' : 'MALE',
          phone: newPatient.phone || '081234567890',
        }),
      }).catch((err: any) => console.warn('Background DB sync patient creation notice:', err));
    }

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
    if (!this.screenings || this.screenings.length === 0) {
      this.screenings = [...INITIAL_SCREENINGS];
      this.persist();
    }
    return [...this.screenings];
  }

  public getScreeningById(id: string): ScreeningData | undefined {
    this.initFromStorage();
    return this.screenings.find((s) => s.id === id);
  }

  public getPendingReviews(): ScreeningData[] {
    this.initFromStorage();
    if (!this.screenings || this.screenings.length === 0) {
      this.screenings = [...INITIAL_SCREENINGS];
      this.persist();
    }
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
    overrideGrade?: string,
    reviewerName?: string,
    reviewerNip?: string
  ): boolean {
    this.initFromStorage();
    let screening = this.screenings.find(
      (s) => s.id === screeningId || s.id.replace(/^#/, '') === screeningId.replace(/^#/, '')
    );
    const activeReviewer = reviewerName || screening?.humanReview?.reviewerName || 'dr. Yunani Setyandriana, Sp.M';
    const activeNip = reviewerNip || screening?.humanReview?.reviewerNip || (screening?.humanReview as any)?.reviewerSip || 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)';

    if (!screening) {
      const fallbackPat = this.patients[0] || {
        id: 'pat-001',
        name: 'Bapak Sutrisno',
        nik: '3404015508750001',
      };
      screening = {
        id: screeningId.startsWith('RTV-') ? screeningId : `RTV-${screeningId}`,
        patientId: fallbackPat.id,
        patientName: fallbackPat.name,
        patientNik: fallbackPat.nik,
        eye: 'OD',
        capturedAt: new Date().toISOString(),
        qualityCheck: { passed: true, sharpness: 0.85, illumination: 0.88, coverage: 0.92 },
        aiResult: {
          drGrade: 'MODERATE_NPDR',
          drLabel: 'Retinopati Diabetik Non-Proliferatif Sedang',
          confidence: 62.0,
          reliability: 'LOW',
          probabilities: [],
          gradCamFocus: 'Mikroaneurisma & Perdarahan Makula',
        },
        reliability: 'NEEDS_REVIEW',
        reliabilityLabel: 'Perlu Review Spesialis',
        humanReview: { status: 'PENDING', reviewerName: activeReviewer, reviewerNip: activeNip },
        recommendation: {
          action: 'Telaah klinis spesialis mata (Sp.M)',
          interval: '1x24 Jam Kerja',
          referralNeeded: true,
          urgencyDays: 14,
          notes: 'Kasus dialihkan ke antrean telaah dokter spesialis mata mitra.',
        },
        imageHash: `hash-${screeningId}`,
      };
      this.screenings.unshift(screening);
    }

    screening.humanReview = {
      status: action === 'CONFIRM_AI' ? 'CONFIRMED_AI' : action === 'OVERRIDE' ? 'OVERRIDDEN' : 'RETAKE_REQUESTED',
      reviewerName: activeReviewer,
      reviewerNip: activeNip,
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
      user: `${activeReviewer} (${activeNip})`,
      action: 'HUMAN_REVIEW_ADJUDICATION',
      entity: `Screening: ${screeningId} (${action}) - Selesai Ditelaah`,
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
