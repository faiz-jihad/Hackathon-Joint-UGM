import React, { useState } from 'react';
import {
  EyeIcon,
  CheckIcon,
  XIcon,
  AlertTriangleIcon,
  InfoIcon,
  UploadCloudIcon,
  ShieldCheckIcon,
  ArrowRightIcon,
  RefreshCwIcon,
  ClockIcon,
  HospitalIcon,
} from './Icons';
import { clinicalStore, ScreeningData, QualityCheckData, AIResultData, RecommendationData } from '../lib/clinical-store';

interface ScreeningWorkflowViewProps {
  onGoToReview: (screeningId: string) => void;
  onGoToReferrals: (patientName: string) => void;
  prefilledNik?: string;
}

export function ScreeningWorkflowView({ onGoToReview, onGoToReferrals, prefilledNik }: ScreeningWorkflowViewProps) {
  const [step, setStep] = useState<number>(1);

  // Form State (initialized or loaded from prefill)
  const [nik, setNik] = useState<string>(prefilledNik || '3404071203720001');
  const [fullName, setFullName] = useState<string>('Bambang Sudarmono');
  const [age, setAge] = useState<number>(54);
  const [gender, setGender] = useState<'L' | 'P'>('L');
  const [diabetesType, setDiabetesType] = useState<'TYPE_1' | 'TYPE_2' | 'GESTATIONAL'>('TYPE_2');
  const [durationYears, setDurationYears] = useState<number>(7);
  const [hba1c, setHba1c] = useState<string>('8.2');
  const [treatment, setTreatment] = useState<'LIFESTYLE' | 'ORAL' | 'INSULIN' | 'COMBINATION'>('COMBINATION');
  const [consentGiven, setConsentGiven] = useState<boolean>(true);

  // Eye Selection & Image
  const [activeEye, setActiveEye] = useState<'OD' | 'OS'>('OD');
  const [selectedQualityOption, setSelectedQualityOption] = useState<'CLEAR' | 'BLUR'>('CLEAR');
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [processingStage, setProcessingStage] = useState<number>(0);

  // Newly Created Screening Record
  const [createdScreening, setCreatedScreening] = useState<ScreeningData | null>(null);

  // Quick lookup if patient already exists
  const handleNikChange = (inputNik: string) => {
    setNik(inputNik);
    const existing = clinicalStore.getPatientByNik(inputNik);
    if (existing) {
      setFullName(existing.name);
      setAge(existing.age);
      setGender(existing.gender);
      setDiabetesType(existing.diabetesProfile.type);
      setDurationYears(existing.diabetesProfile.durationYears);
      setHba1c(String(existing.diabetesProfile.hba1c));
      setTreatment(existing.diabetesProfile.treatment);
    }
  };

  const handleProceedToCapture = () => {
    // Dynamically register patient if new
    let patient = clinicalStore.getPatientByNik(nik);
    if (!patient) {
      patient = clinicalStore.addPatient({
        nik,
        name: fullName,
        age: Number(age) || 50,
        gender,
        diabetesProfile: {
          type: diabetesType,
          durationYears: Number(durationYears) || 5,
          hba1c: parseFloat(hba1c) || 7.5,
          treatment,
        },
      });
    }
    setStep(2);
  };

  const runEvaluation = () => {
    setIsProcessing(true);
    setProcessingStage(1);

    setTimeout(() => {
      setProcessingStage(2);
      setTimeout(() => {
        setProcessingStage(3);
        setTimeout(() => {
          setIsProcessing(false);

          let patient = clinicalStore.getPatientByNik(nik);
          const patientId = patient ? patient.id : 'P-NEW';

          const hba1cVal = parseFloat(hba1c) || 7.5;
          const durVal = Number(durationYears) || 5;

          if (selectedQualityOption === 'BLUR') {
            const qualityCheck: QualityCheckData = {
              passed: false,
              sharpness: 0.31,
              illumination: 0.42,
              coverage: 0.48,
              reason: 'Gambar terlalu buram (indeks ketajaman: 0.31, ambang batas minimum: 0.40). Terhalang pantulan cahaya kornea.',
            };

            const saved = clinicalStore.addScreening({
              patientId,
              patientName: fullName,
              patientNik: nik,
              eye: activeEye,
              qualityCheck,
            });

            setCreatedScreening(saved);
          } else {
            const qualityCheck: QualityCheckData = {
              passed: true,
              sharpness: 0.86,
              illumination: 0.81,
              coverage: 0.94,
            };

            // Dynamic clinical classification based on diabetes profile
            let drGrade: 'NO_DR' | 'MILD_NPDR' | 'MODERATE_NPDR' | 'SEVERE_NPDR' | 'PDR' = 'NO_DR';
            let drLabel = 'Tidak Tampak Retinopati Diabetik';
            let confidence = 95.4;
            let reliability: 'HIGH' | 'LOW' = 'HIGH';
            let probs = [
              { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 95.4 },
              { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 3.5 },
              { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 1.0 },
              { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 0.1 },
              { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
            ];

            if (hba1cVal >= 9.0 || durVal >= 12) {
              drGrade = 'SEVERE_NPDR';
              drLabel = 'Retinopati Diabetik Non-Proliferatif Berat';
              confidence = 92.8;
              reliability = 'HIGH';
              probs = [
                { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 0.2 },
                { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 1.4 },
                { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 5.6 },
                { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 92.8 },
                { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
              ];
            } else if (hba1cVal >= 8.0 || durVal >= 6) {
              drGrade = 'MODERATE_NPDR';
              drLabel = 'Retinopati Diabetik Non-Proliferatif Sedang';
              confidence = 87.4;
              reliability = 'LOW'; // Borderline requiring review
              probs = [
                { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 2.1 },
                { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 9.3 },
                { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 87.4 },
                { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 1.1 },
                { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.1 },
              ];
            } else if (hba1cVal >= 7.2 || durVal >= 3) {
              drGrade = 'MILD_NPDR';
              drLabel = 'Retinopati Diabetik Non-Proliferatif Ringan';
              confidence = 78.5;
              reliability = 'LOW';
              probs = [
                { grade: 'NO_DR', label: 'Tidak Ada DR', prob: 17.5 },
                { grade: 'MILD_NPDR', label: 'NPDR Ringan', prob: 78.5 },
                { grade: 'MODERATE_NPDR', label: 'NPDR Sedang', prob: 3.8 },
                { grade: 'SEVERE_NPDR', label: 'NPDR Berat', prob: 0.2 },
                { grade: 'PDR', label: 'PDR Proliferatif', prob: 0.0 },
              ];
            }

            const aiResult: AIResultData = {
              drGrade,
              drLabel,
              confidence,
              reliability,
              probabilities: probs,
              gradCamFocus: 'Area Mikroaneurisma & Perdarahan Retina Superfisial',
            };

            // Deterministic Perdami/ADA 2024 Rule Engine
            let recommendation: RecommendationData;
            if (drGrade === 'NO_DR') {
              recommendation = {
                action: 'Skrining berkala tahunan di FKTP Puskesmas Mlati II.',
                interval: '12 Bulan',
                referralNeeded: false,
                urgencyDays: 365,
                notes: 'Pertahankan kendali glikemik, tekanan darah, dan profil lipid sesuai target ADA.',
              };
            } else if (drGrade === 'MILD_NPDR') {
              recommendation = {
                action: 'Optimasi terapi OHO/insulin di FKTP dan jadwalkan evaluasi funduskopi 6 bulan.',
                interval: '6 Bulan',
                referralNeeded: false,
                urgencyDays: 180,
                notes: 'Tanda awal mikroangiopati tanpa edema makula bermakna klinis.',
              };
            } else if (drGrade === 'MODERATE_NPDR') {
              recommendation = {
                action: 'Rujukan ke Dokter Spesialis Mata (FKRTL) untuk evaluasi edema makula dan pemeriksaan slit-lamp biomicroscopy.',
                interval: '30 Hari Kalender',
                referralNeeded: true,
                urgencyDays: 30,
                notes: 'Pedoman Perdami 2024: NPDR Sedang wajib dirujuk dalam tempo 30 hari untuk pemeriksaan OCT.',
              };
            } else {
              recommendation = {
                action: 'Rujukan Prioritas FKRTL ke Rumah Sakit Khusus Mata untuk pertimbangan Pan-Retinal Photocoagulation (PRP).',
                interval: '14 Hari Kalender (Prioritas Cito)',
                referralNeeded: true,
                urgencyDays: 14,
                notes: 'Severe NPDR berisiko tinggi konversi cepat menjadi PDR dan perdarahan vitreus.',
              };
            }

            const saved = clinicalStore.addScreening({
              patientId,
              patientName: fullName,
              patientNik: nik,
              eye: activeEye,
              qualityCheck,
              aiResult,
              recommendation,
            });

            setCreatedScreening(saved);
          }

          setStep(3);
        }, 500);
      }, 500);
    }, 500);
  };

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Alur Kerja Skrining Retina Pasien</h1>
          <p className="section-desc">
            Registrasi pasien diabetes, akuisisi citra fundus bilateral (OD/OS), uji kendali mutu, dan analisis keandalan klinis.
          </p>
        </div>
      </div>

      {/* Stepper Header */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div className="stepper-header" style={{ marginBottom: 0 }}>
          <div className={`step-indicator ${step === 1 ? 'active' : step > 1 ? 'completed' : ''}`}>
            <div className="step-number">{step > 1 ? <CheckIcon size={14} /> : '1'}</div>
            <span>1. Data Pasien & Profil Diabetes</span>
          </div>
          <div style={{ color: 'var(--slate-300)' }}>&rarr;</div>
          <div className={`step-indicator ${step === 2 ? 'active' : step > 2 ? 'completed' : ''}`}>
            <div className="step-number">{step > 2 ? <CheckIcon size={14} /> : '2'}</div>
            <span>2. Akuisisi Citra Fundus (OD/OS)</span>
          </div>
          <div style={{ color: 'var(--slate-300)' }}>&rarr;</div>
          <div className={`step-indicator ${step === 3 ? 'active' : ''}`}>
            <div className="step-number">3</div>
            <span>3. Kendali Mutu & Evaluasi Hasil</span>
          </div>
        </div>
      </div>

      {/* STEP 1: PATIENT REGISTRATION & DIABETES PROFILE */}
      {step === 1 && (
        <div className="card">
          <div className="card-header">
            <div>
              <div className="card-title">Identitas Pasien & Riwayat Diabetes Melitus</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                Data klinis esensial untuk personalisasi rekomendasi interval skrining dan stratifikasi risiko komplikasi.
              </div>
            </div>
            <span className="badge badge-neutral">Tahap 1 dari 3</span>
          </div>
          <div className="card-body">
            <div className="grid-2">
              <div className="form-group">
                <label className="form-label" htmlFor="patient-nik">Nomor Induk Kependudukan (NIK - 16 Digit)</label>
                <input
                  id="patient-nik"
                  type="text"
                  className="form-control"
                  value={nik}
                  onChange={(e) => handleNikChange(e.target.value)}
                  maxLength={16}
                  placeholder="Ketik NIK 16 digit..."
                />
                <div className="form-hint">Ketik NIK untuk memuat otomatis data pasien terdaftar atau menambah pasien baru</div>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-name">Nama Lengkap Pasien</label>
                <input
                  id="patient-name"
                  type="text"
                  className="form-control"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Nama lengkap pasien..."
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-age">Usia Pasien (Tahun)</label>
                <input
                  id="patient-age"
                  type="number"
                  className="form-control"
                  value={age}
                  onChange={(e) => setAge(Number(e.target.value))}
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-gender">Jenis Kelamin</label>
                <select
                  id="patient-gender"
                  className="form-control"
                  value={gender}
                  onChange={(e) => setGender(e.target.value as 'L' | 'P')}
                >
                  <option value="L">Laki-laki</option>
                  <option value="P">Perempuan</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-diabetes-type">Klasifikasi Diabetes Melitus</label>
                <select
                  id="patient-diabetes-type"
                  className="form-control"
                  value={diabetesType}
                  onChange={(e) => setDiabetesType(e.target.value as any)}
                >
                  <option value="TYPE_2">Diabetes Melitus Tipe 2 (Dewasa)</option>
                  <option value="TYPE_1">Diabetes Melitus Tipe 1</option>
                  <option value="GESTATIONAL">Diabetes Gestasional</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-duration">Durasi Terdiagnosis Diabetes (Tahun)</label>
                <input
                  id="patient-duration"
                  type="number"
                  className="form-control"
                  value={durationYears}
                  onChange={(e) => setDurationYears(Number(e.target.value))}
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-hba1c">Kadar HbA1c Terakhir (%)</label>
                <input
                  id="patient-hba1c"
                  type="text"
                  className="form-control"
                  value={hba1c}
                  onChange={(e) => setHba1c(e.target.value)}
                  placeholder="Misal: 7.5"
                />
                <div className="form-hint">Ambang batas kendali glikemik target ADA: &lt; 7.0%</div>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="patient-treatment">Regimen Terapi Terkini</label>
                <select
                  id="patient-treatment"
                  className="form-control"
                  value={treatment}
                  onChange={(e) => setTreatment(e.target.value as any)}
                >
                  <option value="COMBINATION">Kombinasi Obat Oral & Insulin</option>
                  <option value="ORAL">Obat Hipoglikemik Oral (OHO)</option>
                  <option value="INSULIN">Terapi Insulin Mandiri</option>
                  <option value="LIFESTYLE">Modifikasi Pola Makan & Gaya Hidup</option>
                </select>
              </div>
            </div>

            <div style={{ marginTop: '1rem', padding: '0.875rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <label style={{ display: 'flex', alignItems: 'flex-start', gap: '0.625rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={consentGiven}
                  onChange={(e) => setConsentGiven(e.target.checked)}
                  style={{ marginTop: '0.2rem' }}
                />
                <span style={{ fontSize: '0.8125rem', color: 'var(--slate-700)', lineHeight: 1.5 }}>
                  <strong>Persetujuan Medis (Informed Consent):</strong> Pasien telah mendapatkan penjelasan mengenai tujuan pemeriksaan funduskopi digital dan menyetujui pemrosesan citra retina dalam sistem skrining RETIVA sesuai standar privasi data medis (UU Perlindungan Data Pribadi & Permenkes No. 24/2022).
                </span>
              </label>
            </div>

            <div style={{ marginTop: '1.5rem', display: 'flex', justifyContent: 'flex-end' }}>
              <button
                type="button"
                className="btn btn-primary"
                disabled={!consentGiven || nik.trim().length < 10 || fullName.trim() === ''}
                onClick={handleProceedToCapture}
              >
                <span>Lanjutkan ke Akuisisi Citra</span>
                <ArrowRightIcon size={16} />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* STEP 2: IMAGE CAPTURE / UPLOAD */}
      {step === 2 && (
        <div className="card">
          <div className="card-header">
            <div>
              <div className="card-title">Akuisisi Citra Funduskopi Digital</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                Pasien: <strong>{fullName}</strong> (NIK: {nik}) — Pilih mata yang diperiksa dan evaluasi citra retina.
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button
                type="button"
                className={`btn btn-sm ${activeEye === 'OD' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => setActiveEye('OD')}
              >
                OD (Mata Kanan)
              </button>
              <button
                type="button"
                className={`btn btn-sm ${activeEye === 'OS' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => setActiveEye('OS')}
              >
                OS (Mata Kiri)
              </button>
            </div>
          </div>
          <div className="card-body">
            <div className="grid-2">
              <div>
                <div className="fundus-frame">
                  <div className="fundus-tag">
                    {activeEye === 'OD' ? 'Oculus Dexter (Mata Kanan)' : 'Oculus Sinister (Mata Kiri)'}
                  </div>
                  <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--slate-400)' }}>
                    <div style={{ width: '120px', height: '120px', borderRadius: '50%', border: '2px dashed var(--slate-600)', margin: '0 auto 1rem auto', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <EyeIcon size={44} style={{ color: 'var(--brand-500)' }} />
                    </div>
                    <div style={{ color: '#ffffff', fontWeight: 600, fontSize: '0.875rem' }}>
                      Citra Siap Dievaluasi
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--slate-400)', marginTop: '0.25rem' }}>
                      Bidang Pandang 45° • Fovea & Diskus Optikus Terpusat
                    </div>
                  </div>
                </div>

                <div style={{ marginTop: '0.75rem', display: 'flex', gap: '0.5rem', justifyContent: 'center' }}>
                  <button
                    type="button"
                    className={`btn btn-sm ${selectedQualityOption === 'CLEAR' ? 'btn-primary' : 'btn-outline'}`}
                    onClick={() => setSelectedQualityOption('CLEAR')}
                  >
                    <span>Uji Citra Jelas (Lolos Quality Gate)</span>
                  </button>
                  <button
                    type="button"
                    className={`btn btn-sm ${selectedQualityOption === 'BLUR' ? 'btn-primary' : 'btn-outline'}`}
                    onClick={() => setSelectedQualityOption('BLUR')}
                  >
                    <span>Uji Citra Buram (Gagal Quality Gate)</span>
                  </button>
                </div>
              </div>

              <div>
                <div style={{ padding: '1rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', marginBottom: '1.25rem' }}>
                  <h3 style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-800)', marginBottom: '0.5rem' }}>
                    Standar Mutu Pemotretan Retina:
                  </h3>
                  <ul style={{ paddingLeft: '1.2rem', fontSize: '0.8125rem', color: 'var(--slate-600)', lineHeight: 1.6 }}>
                    <li>Pastikan fovea dan diskus optikus berada di dalam zona pandang tengah.</li>
                    <li>Hindari artefak pantulan cahaya kornea dan bayangan bulu mata.</li>
                    <li>Verifikasi kecukupan dilatasi pupil sebelum pengambilan gambar.</li>
                    <li>Periksa kesesuaian identitas pasien sebelum pemrosesan algoritma.</li>
                  </ul>
                </div>

                {isProcessing ? (
                  <div style={{ padding: '1.5rem', border: '1px solid var(--border-card)', borderRadius: 'var(--radius-md)', backgroundColor: '#ffffff' }}>
                    <div style={{ fontWeight: 600, color: 'var(--slate-800)', marginBottom: '1rem' }}>
                      Sedang Memeriksa Citra Retina...
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', fontSize: '0.8125rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: processingStage >= 1 ? 'var(--brand-700)' : 'var(--slate-400)' }}>
                        {processingStage > 1 ? <CheckIcon size={16} /> : <ClockIcon size={16} />}
                        <span>1. Uji Kendali Mutu Citra (Ketajaman, Pencahayaan, Cakupan Diskus)</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: processingStage >= 2 ? 'var(--brand-700)' : 'var(--slate-400)' }}>
                        {processingStage > 2 ? <CheckIcon size={16} /> : <ClockIcon size={16} />}
                        <span>2. Inferensi Model EfficientNet-B3 (Klasifikasi ICDR 5 Derajat)</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: processingStage >= 3 ? 'var(--brand-700)' : 'var(--slate-400)' }}>
                        <ClockIcon size={16} />
                        <span>3. Evaluasi Keandalan Klinis (Reliability Gate & Perdami Engine)</span>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    <button
                      type="button"
                      className="btn btn-primary"
                      style={{ padding: '0.75rem' }}
                      onClick={runEvaluation}
                    >
                      <UploadCloudIcon size={18} />
                      <span>Proses Citra & Jalankan Evaluasi Klinis</span>
                    </button>
                    <button
                      type="button"
                      className="btn btn-outline"
                      onClick={() => setStep(1)}
                    >
                      <span>Kembali ke Data Pasien</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* STEP 3: QUALITY GATE & DYNAMIC AI EVALUATION RESULT */}
      {step === 3 && createdScreening && (
        <div>
          {/* Quality Gate Card */}
          <div className="card" style={{ marginBottom: '1.5rem' }}>
            <div className="card-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <ShieldCheckIcon size={18} style={{ color: 'var(--brand-700)' }} />
                <div className="card-title">Hasil Pemeriksaan Kendali Mutu (Quality Gate)</div>
              </div>
              {createdScreening.qualityCheck.passed ? (
                <span className="badge badge-pass">
                  <CheckIcon size={12} />
                  <span>Citra Layak (Passed)</span>
                </span>
              ) : (
                <span className="badge badge-retake">
                  <AlertTriangleIcon size={12} />
                  <span>Perlu Pengambilan Ulang (Failed)</span>
                </span>
              )}
            </div>
            <div className="card-body">
              {createdScreening.qualityCheck.passed ? (
                <div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '1rem' }}>
                    <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                      <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>Ketajaman (Sharpness)</div>
                      <div style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>
                        {createdScreening.qualityCheck.sharpness} / 1.0 (Optimal)
                      </div>
                    </div>
                    <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                      <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>Pencahayaan (Illumination)</div>
                      <div style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>
                        {createdScreening.qualityCheck.illumination} / 1.0 (Seimbang)
                      </div>
                    </div>
                    <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                      <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>Cakupan Retina (Field View)</div>
                      <div style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>
                        {createdScreening.qualityCheck.coverage} / 1.0 (Makula Jelas)
                      </div>
                    </div>
                  </div>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--slate-600)' }}>
                    Kualitas citra memenuhi standar minimum untuk evaluasi pendukung keputusan skrining retina.
                  </div>
                </div>
              ) : (
                <div style={{ backgroundColor: 'var(--status-retake-bg)', border: '1px solid var(--status-retake-border)', padding: '1rem', borderRadius: 'var(--radius-sm)' }}>
                  <div style={{ fontWeight: 700, color: 'var(--status-retake-text)', marginBottom: '0.25rem' }}>
                    Citra Belum Dapat Digunakan
                  </div>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--slate-800)', marginBottom: '0.75rem' }}>
                    {createdScreening.qualityCheck.reason}
                  </div>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={() => {
                      setSelectedQualityOption('CLEAR');
                      setStep(2);
                    }}
                  >
                    <RefreshCwIcon size={14} />
                    <span>Ambil Citra Ulang</span>
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* AI Screening & Reliability Results */}
          {createdScreening.qualityCheck.passed && createdScreening.aiResult && (
            <div className="grid-2">
              <div className="card">
                <div className="card-header">
                  <div className="card-title">Temuan Skrining Model AI</div>
                  <span className="badge badge-info">EfficientNet-B3 v1.0.0</span>
                </div>
                <div className="card-body">
                  <div style={{ marginBottom: '1.25rem' }}>
                    <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                      Hasil Analisis Citra
                    </div>
                    <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--slate-900)', marginTop: '0.25rem' }}>
                      {createdScreening.aiResult.drLabel}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem' }}>
                      <span className={`badge ${createdScreening.aiResult.reliability === 'HIGH' ? 'badge-pass' : 'badge-review'}`}>
                        <ClockIcon size={12} />
                        <span>Keandalan: {createdScreening.reliabilityLabel}</span>
                      </span>
                      <span style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>
                        Probabilitas Utama: {createdScreening.aiResult.confidence}%
                      </span>
                    </div>
                  </div>

                  <div style={{ marginBottom: '1.25rem' }}>
                    <div style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--slate-700)', marginBottom: '0.5rem' }}>
                      Distribusi Probabilitas Kelas ICDR:
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                      {createdScreening.aiResult.probabilities.map((item) => (
                        <div key={item.grade} style={{ fontSize: '0.75rem' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.15rem' }}>
                            <span style={{ fontWeight: item.prob === createdScreening.aiResult?.confidence ? 700 : 500 }}>
                              {item.label}
                            </span>
                            <span className="code-inline">{item.prob}%</span>
                          </div>
                          <div style={{ height: '6px', backgroundColor: 'var(--slate-200)', borderRadius: '9999px', overflow: 'hidden' }}>
                            <div
                              style={{
                                height: '100%',
                                width: `${item.prob}%`,
                                backgroundColor: item.prob === createdScreening.aiResult?.confidence ? 'var(--brand-700)' : 'var(--slate-400)',
                              }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '0.875rem' }}>
                    <button
                      type="button"
                      className="btn btn-outline btn-sm"
                      style={{ width: '100%' }}
                      onClick={() => onGoToReview(createdScreening.id)}
                    >
                      <span>Buka di Portal Telaah Spesialis & Peta Grad-CAM</span>
                      <ArrowRightIcon size={14} />
                    </button>
                  </div>
                </div>
              </div>

              {/* Deterministic Recommendations Engine */}
              {createdScreening.recommendation && (
                <div className="card">
                  <div className="card-header">
                    <div className="card-title">Rekomendasi Alur Klinis (Perdami/ADA 2024)</div>
                    <span className="badge badge-pass">Deterministic Rules</span>
                  </div>
                  <div className="card-body">
                    <div style={{ marginBottom: '1.25rem' }}>
                      <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                        Tindakan Klinis Yang Dianjurkan
                      </div>
                      <div style={{ fontSize: '0.9375rem', fontWeight: 600, color: 'var(--slate-900)', marginTop: '0.25rem', lineHeight: 1.5 }}>
                        {createdScreening.recommendation.action}
                      </div>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '1.25rem' }}>
                      <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>Interval Rujukan Maksimal</div>
                        <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>
                          {createdScreening.recommendation.interval}
                        </div>
                      </div>
                      <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>Status Rujukan FKRTL</div>
                        <div style={{ fontSize: '0.875rem', fontWeight: 700, color: createdScreening.recommendation.referralNeeded ? 'var(--status-review-text)' : 'var(--status-pass-text)' }}>
                          {createdScreening.recommendation.referralNeeded ? 'Wajib Rujukan Lanjutan' : 'Pemeriksaan Rutin FKTP'}
                        </div>
                      </div>
                    </div>

                    <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-100)', borderRadius: 'var(--radius-sm)', fontSize: '0.75rem', color: 'var(--slate-600)', lineHeight: 1.5, marginBottom: '1.25rem' }}>
                      <strong>Dasar Hukum & Klinis:</strong> {createdScreening.recommendation.notes}
                    </div>

                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      {createdScreening.recommendation.referralNeeded && (
                        <button
                          type="button"
                          className="btn btn-primary"
                          style={{ flex: 1 }}
                          onClick={() => onGoToReferrals(fullName)}
                        >
                          <HospitalIcon size={14} />
                          <span>Cari Rumah Sakit Rujukan Terdekat</span>
                        </button>
                      )}
                      <button
                        type="button"
                        className="btn btn-outline"
                        onClick={() => {
                          setStep(1);
                          setCreatedScreening(null);
                        }}
                      >
                        <span>Skrining Pasien Lain</span>
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
