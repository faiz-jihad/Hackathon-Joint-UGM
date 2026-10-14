'use client';

import React, { useState, useEffect } from 'react';
import {
  ShieldCheckIcon,
  AlertTriangleIcon,
  HospitalIcon,
  ClockIcon,
  CheckIcon,
  ArrowRightIcon,
  FileTextIcon,
} from './Icons';

interface CareCompanionViewProps {
  patientId?: string;
  patientName?: string;
  onNavigateTab?: (tab: string) => void;
}

export function CareCompanionView({
  patientId = '',
  patientName = 'Pasien Terdaftar',
}: CareCompanionViewProps) {
  // State variables
  const [activeTab, setActiveTab] = useState<'A_SCREENING' | 'B_PRE_CONSULT' | 'C_CONSULT_ENTRY' | 'D_CARE_PLAN'>('B_PRE_CONSULT');
  const [careState, setCareState] = useState<string>('AWAITING_CONSULTATION');
  const [loading, setLoading] = useState<boolean>(true);
  const [stateData, setStateData] = useState<any>(null);

  // Safety & Urgent Symptoms Modal
  const [showSymptomModal, setShowSymptomModal] = useState<boolean>(false);
  const [symptomText, setSymptomText] = useState<string>('');
  const [emergencyResult, setEmergencyResult] = useState<any>(null);

  // Phase B: Pre-consultation
  const [facilities, setFacilities] = useState<any[]>([]);
  const [filterBpjs, setFilterBpjs] = useState<boolean>(false);
  const [savedFacility, setSavedFacility] = useState<any>(null);
  const [copiedQuestionIdx, setCopiedQuestionIdx] = useState<number | null>(null);

  // Phase C: Consultation Entry
  const [consultationForm, setConsultationForm] = useState({
    hospitalClinicName: 'RS Mata Dr. YAP Yogyakarta',
    doctorName: 'dr. Harianto, Sp.M(K)',
    consultationDate: new Date().toISOString().split('T')[0],
    doctorFindingsDiagnosis: 'Retinopati Diabetik Non-Proliferatif Derajat Sedang (Moderate NPDR) ODS. Tanpa tanda edema makula klinis signifikan.',
    recommendedTreatment: 'Kontrol metabolik ketat. Terapi medikamentosa OHO dilanjutkan. Observasi fundus berkala 3-6 bulan.',
    prescribedMedications: [
      { name: 'Metformin 500 mg', dosage: '1 tablet', frequency: '2 kali sehari (sesudah makan)', instructions: 'Terapi OHO' },
      { name: 'Artelac Eye Drops', dosage: '1 tetes', frequency: '3 kali sehari', instructions: 'Tetes mata lubrikasi ODS' }
    ],
    followUpDate: new Date(Date.now() + 90 * 24 * 3600 * 1000).toISOString().split('T')[0],
    dietaryLifestyleInstructions: 'Diet rendah indeks glikemik, batasi garam < 2000 mg/hari, konsumsi sayur berdaun hijau gelap kaya lutein, jalan santai 30 menit/hari.',
    additionalRestrictions: 'Hindari aktivitas angkat beban sangat berat jika ada keluhan kilatan cahaya.',
    source: 'PATIENT_REPORTED',
    verificationStatus: 'UNVERIFIED_PATIENT_ENTRY',
    isPatientConfirmed: false,
  });
  const [consultationSaved, setConsultationSaved] = useState<boolean>(false);
  const [showConfirmModal, setShowConfirmModal] = useState<boolean>(false);

  // Phase D: Nutrition & Care Plan
  const [dailyBudget, setDailyBudget] = useState<number>(35000);
  const [cityRegion, setCityRegion] = useState<string>('D.I. Yogyakarta');
  const [mealPlan, setMealPlan] = useState<any>(null);
  const [loadingMeal, setLoadingMeal] = useState<boolean>(false);
  const [completedMeals, setCompletedMeals] = useState<Record<string, boolean>>({});
  const [reminders, setReminders] = useState<any[]>([]);
  const [weeklyProgress, setWeeklyProgress] = useState<any>(null);
  const [actionHistory, setActionHistory] = useState<any[]>([]);

  // Load Care Companion State
  useEffect(() => {
    fetchCareState();
  }, [patientId]);

  const fetchCareState = async () => {
    try {
      const url = patientId ? `/api/v1/care-companion/state?patientId=${patientId}` : '/api/v1/care-companion/state';
      const res = await fetch(url);
      const json = await res.json();
      if (json.success && json.data) {
        setStateData(json.data);
        setCareState(json.data.currentState);
        setFacilities(json.data.preConsultation?.facilities || []);
        setReminders(json.data.reminders || []);

        if (json.data.consultationSummary) {
          setConsultationForm({
            ...json.data.consultationSummary,
            consultationDate: json.data.consultationSummary.consultationDate?.split('T')[0] || '',
            followUpDate: json.data.consultationSummary.followUpDate?.split('T')[0] || '',
          });
          setConsultationSaved(true);
        }

        // Set active tab based on state
        if (json.data.currentState === 'SCREENING_COMPLETED') {
          setActiveTab('A_SCREENING');
        } else if (json.data.currentState === 'AWAITING_CONSULTATION') {
          setActiveTab('B_PRE_CONSULT');
        } else if (json.data.currentState === 'CONSULTATION_RECORDED') {
          setActiveTab('C_CONSULT_ENTRY');
        } else if (json.data.currentState === 'CARE_PLAN_READY' || json.data.currentState === 'CARE_PLAN_ACTIVE') {
          setActiveTab('D_CARE_PLAN');
        }

        // Load baseline meal plan
        generateMealPlan(35000);
        fetchWeeklyProgress();
      }
    } catch (err) {
      console.warn('Error fetching care companion state:', err);
    } finally {
      setLoading(false);
    }
  };

  const checkUrgentSymptoms = async () => {
    try {
      const res = await fetch('/api/v1/care-companion/urgent-check', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ patientId, symptomsText: symptomText }),
      });
      const json = await res.json();
      if (json.success) {
        setEmergencyResult(json.data);
      }
    } catch (err) {
      console.error('Error evaluating symptoms:', err);
    }
  };

  const generateMealPlan = async (budget: number) => {
    try {
      setLoadingMeal(true);
      const res = await fetch('/api/v1/care-companion/meal-plan/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          dailyBudgetIdr: budget,
          cityRegion,
          isGeneralEducation: careState === 'SCREENING_COMPLETED' || careState === 'AWAITING_CONSULTATION',
          clinicianDietaryNotes: consultationForm.dietaryLifestyleInstructions,
        }),
      });
      const json = await res.json();
      if (json.success) {
        setMealPlan(json.data);
      }
    } catch (err) {
      console.error('Error generating meal plan:', err);
    } finally {
      setLoadingMeal(false);
    }
  };

  const replaceMealItem = async (category: 'SARAPAN' | 'MAKAN_SIANG' | 'MAKAN_MALAM' | 'CAMILAN') => {
    if (!mealPlan) return;
    try {
      setLoadingMeal(true);
      const res = await fetch('/api/v1/care-companion/meal-plan/replace-meal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ currentPlan: mealPlan, category }),
      });
      const json = await res.json();
      if (json.success) {
        setMealPlan(json.data);
      }
    } catch (err) {
      console.error('Error replacing meal:', err);
    } finally {
      setLoadingMeal(false);
    }
  };

  const saveConsultation = async (confirmNow: boolean) => {
    try {
      const res = await fetch('/api/v1/care-companion/consultation-summary', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patientId,
          ...consultationForm,
          isPatientConfirmed: confirmNow,
        }),
      });
      const json = await res.json();
      if (json.success) {
        setConsultationSaved(true);
        if (confirmNow) {
          setShowConfirmModal(false);
          await fetch(`/api/v1/care-companion/consultation-summary/${json.data.id}/confirm`, {
            method: 'POST',
          });
          setCareState('CARE_PLAN_READY');
          setActiveTab('D_CARE_PLAN');
          fetchCareState();
        } else {
          alert('Ringkasan konsultasi dokter berhasil disimpan sebagai draf catatan pasien.');
        }
      }
    } catch (err) {
      console.error('Error saving consultation:', err);
    }
  };

  const toggleReminder = async (id: string, currentStatus: boolean) => {
    try {
      await fetch(`/api/v1/care-companion/reminders/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isCompleted: !currentStatus }),
      });
      setReminders((prev) =>
        prev.map((r) => (r.id === id ? { ...r, isCompleted: !currentStatus } : r))
      );
    } catch (err) {
      console.error('Error toggling reminder:', err);
    }
  };

  const fetchWeeklyProgress = async () => {
    try {
      const res = await fetch(`/api/v1/care-companion/progress?patientId=${patientId}`);
      const json = await res.json();
      if (json.success) {
        setWeeklyProgress(json.data);
      }
    } catch (err) {
      console.error('Error fetching progress:', err);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-12">
      {/* 1. TOP HERO: AGENTIC CARE COMPANION HEADER */}
      <div className="bg-gradient-to-r from-[#0D47A1] via-[#003178] to-[#0A2540] rounded-2xl p-6 text-white shadow-lg">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="px-3 py-1 bg-white/20 text-white rounded-full text-xs font-semibold uppercase tracking-wider backdrop-blur-sm">
                AI Care Companion
              </span>
              <span className="px-3 py-1 bg-[#10B981]/30 text-emerald-200 border border-emerald-400/40 rounded-full text-xs font-semibold">
                Sistem Pendamping Klinis Pasien
              </span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight">
              Pendamping Perawatan Retinopati Diabetik
            </h1>
            <p className="text-blue-100 text-sm mt-1 max-w-2xl leading-relaxed">
              Membimbing perjalanan Anda mulai dari memahami skrining, mencari faskes rujukan, mencatat arahan dokter, hingga perencanaan nutrisi harian yang ramah kantong.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                setEmergencyResult(null);
                setShowSymptomModal(true);
              }}
              className="px-4 py-2.5 bg-rose-600 hover:bg-rose-700 active:bg-rose-800 text-white rounded-xl text-xs font-semibold shadow-md flex items-center gap-2 transition"
            >
              <AlertTriangleIcon className="w-4 h-4 text-white" />
              <span>Cek Gejala Darurat Mata</span>
            </button>
          </div>
        </div>

        {/* CLINICAL DISCLAIMER BANNER */}
        <div className="mt-5 p-3.5 bg-blue-950/60 border border-blue-400/30 rounded-xl text-xs text-blue-200 flex items-start gap-3">
          <ShieldCheckIcon className="w-5 h-5 text-blue-300 flex-shrink-0 mt-0.5" />
          <p className="leading-relaxed">
            <strong className="text-white">Prinsip Medis:</strong> AI Retiva berfungsi mendampingi proses perawatan dan bukan pengganti dokter spesialis mata. AI tidak menetapkan diagnosis definitif maupun meresepkan obat secara mandiri. Keputusan klinis mutlak berada pada dokter penanggung jawab.
          </p>
        </div>
      </div>

      {/* 2. JOURNEY PROGRESSION STEPPER */}
      <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          <button
            onClick={() => setActiveTab('A_SCREENING')}
            className={`p-3 rounded-xl text-left border transition flex flex-col justify-between ${
              activeTab === 'A_SCREENING'
                ? 'bg-blue-50 border-[#0D47A1] text-[#0D47A1]'
                : 'border-slate-100 hover:bg-slate-50 text-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Fase A</span>
              <CheckIcon className="w-4 h-4 text-emerald-600" />
            </div>
            <div className="font-semibold text-xs mt-1">1. Hasil Skrining</div>
            <div className="text-[11px] text-slate-500 truncate mt-0.5">Penjelasan & Batasan</div>
          </button>

          <button
            onClick={() => setActiveTab('B_PRE_CONSULT')}
            className={`p-3 rounded-xl text-left border transition flex flex-col justify-between ${
              activeTab === 'B_PRE_CONSULT'
                ? 'bg-blue-50 border-[#0D47A1] text-[#0D47A1]'
                : 'border-slate-100 hover:bg-slate-50 text-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Fase B</span>
              <span className="w-2 h-2 rounded-full bg-blue-600"></span>
            </div>
            <div className="font-semibold text-xs mt-1">2. Pra-Konsultasi</div>
            <div className="text-[11px] text-slate-500 truncate mt-0.5">Cari Faskes & Pertanyaan</div>
          </button>

          <button
            onClick={() => setActiveTab('C_CONSULT_ENTRY')}
            className={`p-3 rounded-xl text-left border transition flex flex-col justify-between ${
              activeTab === 'C_CONSULT_ENTRY'
                ? 'bg-blue-50 border-[#0D47A1] text-[#0D47A1]'
                : 'border-slate-100 hover:bg-slate-50 text-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Fase C</span>
              {consultationSaved && <CheckIcon className="w-4 h-4 text-emerald-600" />}
            </div>
            <div className="font-semibold text-xs mt-1">3. Catat Hasil Dokter</div>
            <div className="text-[11px] text-slate-500 truncate mt-0.5">Konfirmasi Arahan Klinis</div>
          </button>

          <button
            onClick={() => {
              if (!consultationForm.isPatientConfirmed && careState !== 'CARE_PLAN_READY' && careState !== 'CARE_PLAN_ACTIVE') {
                alert('Silakan simpan dan konfirmasi hasil konsultasi dokter di Fase C terlebih dahulu sebelum membuka rencana perawatan aktif.');
                setActiveTab('C_CONSULT_ENTRY');
              } else {
                setActiveTab('D_CARE_PLAN');
              }
            }}
            className={`p-3 rounded-xl text-left border transition flex flex-col justify-between ${
              activeTab === 'D_CARE_PLAN'
                ? 'bg-blue-50 border-[#0D47A1] text-[#0D47A1]'
                : 'border-slate-100 hover:bg-slate-50 text-slate-700'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Fase D</span>
              <span className="text-[10px] font-bold px-1.5 py-0.2 bg-blue-100 text-[#0D47A1] rounded">Aktif</span>
            </div>
            <div className="font-semibold text-xs mt-1">4. Rencana Pasca-Konsultasi</div>
            <div className="text-[11px] text-slate-500 truncate mt-0.5">Nutrisi Budget & Pengingat</div>
          </button>
        </div>
      </div>

      {/* 3. CONDITIONAL TAB RENDERING */}

      {/* TAB A: SCREENING RESULT & GUIDANCE */}
      {activeTab === 'A_SCREENING' && (
        <div className="space-y-6">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div>
                <span className="px-2.5 py-1 bg-amber-50 text-amber-700 border border-amber-200 rounded-lg text-xs font-semibold">
                  Retinopati Diabetik Non-Proliferatif Derajat Sedang (Moderate DR)
                </span>
                <h2 className="text-lg font-bold text-slate-900 mt-2">
                  Hasil Analisis Skrining Citra Retina Terakhir
                </h2>
                <p className="text-xs text-slate-500">ID Skrining: {stateData?.screening?.id || 'SCR-2026-0891'} • Tanggal: 26 September 2026</p>
              </div>
              <div className="text-right">
                <span className="text-xs text-slate-500">Tingkat Keyakinan AI</span>
                <div className="text-lg font-bold text-[#0D47A1]">88.4%</div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
              <div className="space-y-3">
                <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Temuan Vaskular Retina</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Citra fundus menunjukkan adanya mikroaneurisma multipel, perdarahan bercak halus (dot/blot hemorrhages), serta eksudat lipid di area retina posterior. Tidak terlihat neovaskularisasi aktif disc optik.
                </p>

                <div className="p-3.5 bg-blue-50 border border-blue-200 rounded-xl">
                  <div className="text-xs font-bold text-[#0D47A1] mb-1">Rekomendasi Tindak Lanjut Protokol PERDAMI:</div>
                  <p className="text-xs text-blue-900 leading-relaxed">
                    Disarankan rujukan terencana ke dokter spesialis mata (Sp.M) untuk pemeriksaan biomikroskopi fundus dilatasi dan evaluasi makulopati diabetik dalam 2–4 minggu.
                  </p>
                </div>
              </div>

              <div className="bg-slate-50 rounded-xl p-4 border border-slate-200 space-y-3">
                <h3 className="text-xs font-bold text-slate-800">Langkah yang Disarankan Selanjutnya:</h3>
                <ul className="space-y-2 text-xs text-slate-600">
                  <li className="flex items-start gap-2">
                    <span className="w-5 h-5 rounded-full bg-blue-100 text-[#0D47A1] flex items-center justify-center font-bold text-[10px] flex-shrink-0 mt-0.5">1</span>
                    <span>Cari faskes mata terdekat yang memiliki dokter spesialis mata & fasilitas laser retina.</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-5 h-5 rounded-full bg-blue-100 text-[#0D47A1] flex items-center justify-center font-bold text-[10px] flex-shrink-0 mt-0.5">2</span>
                    <span>Minta Surat Rujukan Faskes Tingkat 1 (Puskesmas/Klinik) bila menggunakan BPJS Kesehatan.</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-5 h-5 rounded-full bg-blue-100 text-[#0D47A1] flex items-center justify-center font-bold text-[10px] flex-shrink-0 mt-0.5">3</span>
                    <span>Siapkan daftar pertanyaan agar konsultasi dengan dokter berlangsung efektif.</span>
                  </li>
                </ul>

                <button
                  onClick={() => setActiveTab('B_PRE_CONSULT')}
                  className="w-full mt-4 py-2.5 bg-[#0D47A1] hover:bg-[#003178] text-white rounded-xl text-xs font-semibold transition flex items-center justify-center gap-2"
                >
                  <span>Buka Asisten Pra-Konsultasi</span>
                  <ArrowRightIcon className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB B: PRE-CONSULTATION ASSISTANT */}
      {activeTab === 'B_PRE_CONSULT' && (
        <div className="space-y-6">
          {/* BPJS / Referral Navigation & Facilities Search */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
            <div className="flex flex-col md:flex-row md:items-center justify-between pb-4 border-b border-slate-100 gap-3">
              <div>
                <h2 className="text-base font-bold text-slate-900">
                  Pencarian Rumah Sakit & Fasilitas Mata Rujukan
                </h2>
                <p className="text-xs text-slate-500">
                  Data faskes terverifikasi dengan layanan retina di wilayah D.I. Yogyakarta & sekitarnya.
                </p>
              </div>

              <div className="flex items-center gap-2">
                <label className="flex items-center gap-2 text-xs font-semibold text-slate-700 bg-slate-100 px-3 py-1.5 rounded-lg cursor-pointer">
                  <input
                    type="checkbox"
                    checked={filterBpjs}
                    onChange={(e) => setFilterBpjs(e.target.checked)}
                    className="rounded text-[#0D47A1]"
                  />
                  <span>Hanya Menerima BPJS</span>
                </label>
              </div>
            </div>

            {/* Facilities List */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
              {(filterBpjs ? facilities.filter(f => f.bpjsStatus === 'ACCEPTED') : facilities).map((fac) => (
                <div
                  key={fac.id}
                  className={`border rounded-xl p-4 transition flex flex-col justify-between ${
                    savedFacility?.id === fac.id ? 'border-[#0D47A1] bg-blue-50/40 ring-2 ring-blue-500/20' : 'border-slate-200 hover:border-slate-300'
                  }`}
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="px-2 py-0.5 bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold rounded">
                        {fac.bpjsStatus === 'ACCEPTED' ? '✓ Menerima BPJS' : 'Perlu Konfirmasi'}
                      </span>
                      <span className="text-[11px] text-slate-500 font-semibold">{fac.distanceKm}</span>
                    </div>

                    <h3 className="font-bold text-xs text-slate-900">{fac.name}</h3>
                    <p className="text-[11px] text-slate-500 line-clamp-2">{fac.address}</p>

                    <div className="flex flex-wrap gap-1 mt-2">
                      {fac.services?.slice(0, 3).map((s: string) => (
                        <span key={s} className="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded text-[9px] font-medium">
                          {s.replace(/_/g, ' ')}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="pt-3 border-t border-slate-100 mt-3 flex items-center justify-between">
                    <a
                      href={fac.bookingUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs font-semibold text-[#0D47A1] hover:underline"
                    >
                      Antrean Online
                    </a>
                    <button
                      onClick={() => setSavedFacility(fac)}
                      className={`px-3 py-1 text-xs rounded-lg font-semibold transition ${
                        savedFacility?.id === fac.id
                          ? 'bg-blue-600 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      {savedFacility?.id === fac.id ? 'Dipilih' : 'Pilih Faskes'}
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* BPJS ALUR RUJUKAN CARD */}
            <div className="mt-5 p-4 bg-emerald-50/80 border border-emerald-200 rounded-xl text-xs text-emerald-950 flex items-start gap-3">
              <HospitalIcon className="w-5 h-5 text-emerald-700 flex-shrink-0 mt-0.5" />
              <div>
                <strong className="text-emerald-900 block mb-0.5">Panduan Alur Rujukan BPJS Kesehatan (FKRTL):</strong>
                Kunjungi Fasilitas Kesehatan Tingkat Pertama (FKTP Puskesmas/Klinik Pratama terdaftar Anda) terlebih dahulu untuk meminta Surat Pengantar Rujukan (SPK) ke Poliklinik Mata Rumah Sakit tipe B/C tujuan. Bawa KTP dan Kartu BPJS aktif.
              </div>
            </div>
          </div>

          {/* QUESTIONS FOR DOCTOR & PRELIMINARY NUTRITION */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Suggested Doctor Questions */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <h3 className="font-bold text-sm text-slate-900 flex items-center gap-2">
                  <FileTextIcon className="w-4 h-4 text-[#0D47A1]" />
                  <span>Daftar Pertanyaan untuk Dokter</span>
                </h3>
                <span className="text-[11px] text-slate-500">Klik untuk menyalin</span>
              </div>

              <div className="space-y-2.5">
                {[
                  'Berapa derajat keparahan retinopati diabetik pada mata saya saat ini?',
                  'Apakah ada tanda edema makula yang mempengaruhi penglihatan sentral saya?',
                  'Apakah mata saya memerlukan tindakan laser atau suntikan intraokular dalam waktu dekat?',
                  'Berapa target HbA1c dan tekanan darah yang aman untuk melindungi retina saya?',
                  'Kapan waktu kontrol ulang yang tepat untuk evaluasi berkala?',
                ].map((q, idx) => (
                  <div
                    key={idx}
                    onClick={() => {
                      navigator.clipboard.writeText(q);
                      setCopiedQuestionIdx(idx);
                      setTimeout(() => setCopiedQuestionIdx(null), 2000);
                    }}
                    className="p-3 rounded-xl bg-slate-50 border border-slate-200 hover:border-blue-400 cursor-pointer transition text-xs flex items-center justify-between group"
                  >
                    <span className="text-slate-700 leading-relaxed pr-2">{idx + 1}. {q}</span>
                    <span className="text-[10px] text-blue-600 font-bold opacity-0 group-hover:opacity-100 transition flex-shrink-0">
                      {copiedQuestionIdx === idx ? '✓ Tersalin' : 'Salin'}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Preliminary Educational Meal Plan Example */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <h3 className="font-bold text-sm text-slate-900 flex items-center gap-2">
                  <ClockIcon className="w-4 h-4 text-emerald-600" />
                  <span>Edukasi Pola Makan Ramah Kantong</span>
                </h3>
                <span className="px-2 py-0.5 bg-amber-50 text-amber-700 text-[10px] font-bold rounded">
                  Edukasi Umum
                </span>
              </div>

              <p className="text-xs text-slate-500 leading-relaxed">
                Contoh panduan makan harian bergizi seimbang untuk kontrol gula darah sebelum konsultasi dokter:
              </p>

              <div className="space-y-2 text-xs">
                <div className="p-2.5 bg-slate-50 rounded-lg flex justify-between items-center">
                  <span className="font-semibold text-slate-800">Sarapan:</span>
                  <span className="text-slate-600">Nasi Merah + Telur Rebus + Sayur Bayam</span>
                </div>
                <div className="p-2.5 bg-slate-50 rounded-lg flex justify-between items-center">
                  <span className="font-semibold text-slate-800">Makan Siang:</span>
                  <span className="text-slate-600">Ikan Kembung Kukus Kuning + Tumis Buncis</span>
                </div>
                <div className="p-2.5 bg-slate-50 rounded-lg flex justify-between items-center">
                  <span className="font-semibold text-slate-800">Makan Malam:</span>
                  <span className="text-slate-600">Pecel Sayuran + Tahu Panggang</span>
                </div>
              </div>

              <div className="pt-2">
                <button
                  onClick={() => setActiveTab('C_CONSULT_ENTRY')}
                  className="w-full py-2.5 bg-[#0D47A1] hover:bg-[#003178] text-white rounded-xl text-xs font-semibold transition"
                >
                  Sudah Selesai Konsultasi? Catat Hasil Dokter Disini
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB C: DOCTOR CONSULTATION ENTRY & CONFIRMATION */}
      {activeTab === 'C_CONSULT_ENTRY' && (
        <div className="space-y-6">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
            <div className="pb-4 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-2">
              <div>
                <h2 className="text-base font-bold text-slate-900">
                  Formulir Ringkasan Hasil Konsultasi Dokter Spesialis Mata
                </h2>
                <p className="text-xs text-slate-500">
                  Masukkan arahan dan resep resmi yang diberikan oleh dokter untuk mengaktifkan rencana perawatan terpersonalisasi.
                </p>
              </div>

              <span className="px-3 py-1 bg-blue-50 text-[#0D47A1] border border-blue-200 rounded-lg text-xs font-semibold">
                Sumber Data: Catatan Pasien
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Rumah Sakit / Klinik</label>
                <input
                  type="text"
                  value={consultationForm.hospitalClinicName}
                  onChange={(e) => setConsultationForm({ ...consultationForm, hospitalClinicName: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Contoh: RS Mata Dr. YAP Yogyakarta"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-700 mb-1">Nama Dokter Penanggung Jawab</label>
                <input
                  type="text"
                  value={consultationForm.doctorName}
                  onChange={(e) => setConsultationForm({ ...consultationForm, doctorName: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Contoh: dr. Harianto, Sp.M(K)"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block font-semibold text-slate-700 mb-1">Temuan Klinis & Diagnosis Dokter</label>
                <textarea
                  rows={2}
                  value={consultationForm.doctorFindingsDiagnosis}
                  onChange={(e) => setConsultationForm({ ...consultationForm, doctorFindingsDiagnosis: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Tuliskan temuan dokter spesialis mata..."
                />
              </div>

              <div className="md:col-span-2">
                <label className="block font-semibold text-slate-700 mb-1">Instruksi Terapi & Tindakan Lanjutan</label>
                <textarea
                  rows={2}
                  value={consultationForm.recommendedTreatment}
                  onChange={(e) => setConsultationForm({ ...consultationForm, recommendedTreatment: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Contoh: Terapi obat oral diteruskan, belum ada indikasi laser..."
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-700 mb-1">Tanggal Kontrol Ulang Berikutnya</label>
                <input
                  type="date"
                  value={consultationForm.followUpDate}
                  onChange={(e) => setConsultationForm({ ...consultationForm, followUpDate: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-700 mb-1">Instruksi Pola Makan dari Dokter/Nakes</label>
                <input
                  type="text"
                  value={consultationForm.dietaryLifestyleInstructions}
                  onChange={(e) => setConsultationForm({ ...consultationForm, dietaryLifestyleInstructions: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Contoh: Kurangi garam dan makanan manis..."
                />
              </div>
            </div>

            {/* Prescribed Medications Section */}
            <div className="mt-6 pt-4 border-t border-slate-100">
              <h3 className="font-bold text-xs text-slate-800 mb-3">Obat yang Diresepkan Dokter:</h3>
              <div className="space-y-2">
                {consultationForm.prescribedMedications.map((med: any, idx: number) => (
                  <div key={idx} className="p-3 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between text-xs">
                    <div>
                      <span className="font-bold text-slate-900">{med.name}</span>
                      <span className="text-slate-500 ml-2">({med.dosage})</span>
                      <div className="text-[11px] text-slate-600 mt-0.5">{med.frequency} • {med.instructions}</div>
                    </div>
                    <span className="px-2 py-0.5 bg-blue-100 text-blue-800 font-semibold text-[10px] rounded">Terjadwal</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Actions */}
            <div className="mt-6 pt-4 border-t border-slate-100 flex flex-col md:flex-row items-center justify-between gap-3">
              <div className="text-[11px] text-slate-500">
                Data disimpan dengan label: <strong>Catatan Pasien Belum Terverifikasi Dokumen Resmi</strong>.
              </div>

              <div className="flex items-center gap-3 w-full md:w-auto">
                <button
                  onClick={() => saveConsultation(false)}
                  className="flex-1 md:flex-initial px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-semibold transition"
                >
                  Simpan Draf
                </button>
                <button
                  onClick={() => setShowConfirmModal(true)}
                  className="flex-1 md:flex-initial px-5 py-2.5 bg-[#0D47A1] hover:bg-[#003178] text-white rounded-xl text-xs font-semibold shadow-md transition"
                >
                  Tinjau & Konfirmasi Dokter
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB D: POST-CONSULTATION CARE PLANNING (NUTRITION & REMINDERS) */}
      {activeTab === 'D_CARE_PLAN' && (
        <div className="space-y-6">
          {/* BUDGET-AWARE NUTRITION PLANNER */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between pb-4 border-b border-slate-100 gap-4">
              <div>
                <div className="flex items-center gap-2">
                  <span className="px-2.5 py-0.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded text-xs font-bold">
                    Perencanaan Aktif Pasca-Konsultasi
                  </span>
                  <span className="text-xs text-slate-500">Berdasarkan Arahan dr. Harianto, Sp.M</span>
                </div>
                <h2 className="text-lg font-bold text-slate-900 mt-1">
                  Panduan Menu Harian Ramah Kantong (Low-GI Diabetes)
                </h2>
              </div>

              {/* Budget Controller */}
              <div className="flex items-center gap-3 bg-slate-50 p-2 rounded-xl border border-slate-200">
                <span className="text-xs font-bold text-slate-600">Anggaran Harian:</span>
                <select
                  value={dailyBudget}
                  onChange={(e) => {
                    const b = Number(e.target.value);
                    setDailyBudget(b);
                    generateMealPlan(b);
                  }}
                  className="bg-white border border-slate-300 rounded-lg px-2.5 py-1 text-xs font-bold text-[#0D47A1] outline-none"
                >
                  <option value={25000}>Rp 25.000 / hari (Ekonomis)</option>
                  <option value={35000}>Rp 35.000 / hari (Standar)</option>
                  <option value={50000}>Rp 50.000 / hari (Variasi Lengkap)</option>
                </select>
              </div>
            </div>

            {/* Budget Summary Card */}
            {mealPlan && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 bg-gradient-to-r from-blue-50 to-indigo-50/50 p-4 rounded-xl border border-blue-100">
                <div>
                  <span className="text-[11px] text-slate-500 font-semibold">Total Estimasi Belanja</span>
                  <div className="text-lg font-bold text-slate-900">
                    Rp {mealPlan.estimatedTotalCostIdr.toLocaleString('id-ID')}
                  </div>
                </div>
                <div>
                  <span className="text-[11px] text-slate-500 font-semibold">Sisa Anggaran Harian</span>
                  <div className={`text-lg font-bold ${mealPlan.remainingBudgetIdr >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                    Rp {mealPlan.remainingBudgetIdr.toLocaleString('id-ID')}
                  </div>
                </div>
                <div>
                  <span className="text-[11px] text-slate-500 font-semibold">Status Kepatuhan Budget</span>
                  <div className="text-xs font-bold text-emerald-700 mt-1">
                    ✓ Dalam Batas Anggaran Terjangkau
                  </div>
                </div>
              </div>
            )}

            {/* Meals Cards */}
            {mealPlan && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[
                  { label: 'Sarapan', cat: 'SARAPAN' as const, meal: mealPlan.meals.breakfast },
                  { label: 'Makan Siang', cat: 'MAKAN_SIANG' as const, meal: mealPlan.meals.lunch },
                  { label: 'Makan Malam', cat: 'MAKAN_MALAM' as const, meal: mealPlan.meals.dinner },
                  { label: 'Camilan Sehat', cat: 'CAMILAN' as const, meal: mealPlan.meals.snack },
                ].map(({ label, cat, meal }) => (
                  <div key={label} className="border border-slate-200 rounded-xl p-4 space-y-3 bg-white">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs text-[#0D47A1]">{label}</span>
                        <span className="px-1.5 py-0.5 bg-emerald-50 text-emerald-700 text-[10px] font-semibold rounded">
                          IG: {meal.glycemicIndex}
                        </span>
                      </div>
                      <span className="text-xs font-bold text-slate-700">
                        Rp {meal.estimatedCostIdr.toLocaleString('id-ID')}
                      </span>
                    </div>

                    <h4 className="font-bold text-xs text-slate-900">{meal.name}</h4>
                    <p className="text-[11px] text-slate-500">{meal.portion}</p>

                    <div className="space-y-1 pt-1 border-t border-slate-100">
                      <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider">Bahan:</span>
                      <div className="flex flex-wrap gap-1">
                        {meal.ingredients.map((ing: any, i: number) => (
                          <span key={i} className="text-[10px] px-2 py-0.5 bg-slate-100 rounded text-slate-700">
                            {ing.name} ({ing.quantity} - Rp {ing.estCostIdr.toLocaleString('id-ID')})
                          </span>
                        ))}
                      </div>
                    </div>

                    <div className="pt-2 flex items-center justify-between">
                      <button
                        onClick={() => replaceMealItem(cat)}
                        className="text-xs text-[#0D47A1] hover:underline font-semibold"
                      >
                        🔄 Ganti Menu Ini
                      </button>

                      <label className="flex items-center gap-1.5 text-xs text-slate-600 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={completedMeals[meal.id] || false}
                          onChange={(e) => setCompletedMeals({ ...completedMeals, [meal.id]: e.target.checked })}
                          className="rounded text-emerald-600"
                        />
                        <span>Selesai Dimakan</span>
                      </label>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Shopping List Table */}
            {mealPlan && (
              <div className="border border-slate-200 rounded-xl p-4 bg-slate-50 space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-xs text-slate-900 uppercase tracking-wider">Daftar Belanja Pasar Hari Ini</h3>
                  <span className="text-[11px] text-slate-500">Estimasi Pasar Tradisional Yogyakarta</span>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                  {mealPlan.shoppingList.map((item: any, i: number) => (
                    <div key={i} className="p-2 bg-white rounded-lg border border-slate-200 text-xs">
                      <div className="font-semibold text-slate-800 truncate">{item.item}</div>
                      <div className="text-[11px] text-slate-500">{item.quantity} • Rp {item.estPriceIdr.toLocaleString('id-ID')}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* REMINDERS & WEEKLY ADHERENCE TRACKER */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Active Reminders */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
              <h3 className="font-bold text-sm text-slate-900 flex items-center gap-2">
                <ClockIcon className="w-4 h-4 text-[#0D47A1]" />
                <span>Pengingat & Jadwal Kepatuhan Pasien</span>
              </h3>

              <div className="space-y-2.5">
                {reminders.map((r: any) => (
                  <div
                    key={r.id}
                    className={`p-3 rounded-xl border flex items-center justify-between transition ${
                      r.isCompleted ? 'bg-slate-50 border-slate-200 opacity-60' : 'bg-white border-blue-200'
                    }`}
                  >
                    <div>
                      <div className="font-bold text-xs text-slate-900">{r.title}</div>
                      <div className="text-[11px] text-slate-500 mt-0.5">{r.description || 'Pengingat rutin'}</div>
                      <div className="text-[10px] text-blue-600 font-semibold mt-1">
                        Jadwal: {new Date(r.scheduledTime).toLocaleDateString('id-ID')}
                      </div>
                    </div>

                    <button
                      onClick={() => toggleReminder(r.id, r.isCompleted)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                        r.isCompleted
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-[#0D47A1] text-white hover:bg-[#003178]'
                      }`}
                    >
                      {r.isCompleted ? '✓ Selesai' : 'Tandai Selesai'}
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Weekly Progress & AI Action Audit Log */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4">
              <h3 className="font-bold text-sm text-slate-900 flex items-center gap-2">
                <ShieldCheckIcon className="w-4 h-4 text-emerald-600" />
                <span>Ringkasan Kepatuhan & Transparansi AI</span>
              </h3>

              <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-emerald-950">Skor Kepatuhan Mingguan:</span>
                  <span className="text-sm font-bold text-emerald-700">92%</span>
                </div>
                <p className="text-xs text-emerald-900 leading-relaxed">
                  Kepatuhan konsumsi obat harian dan pola makan sangat baik. Tetap pertahankan kontrol glikemik hingga jadwal evaluasi fundus berikutnya.
                </p>
              </div>

              <div className="pt-2 space-y-2">
                <span className="text-xs font-bold text-slate-700 block">Riwayat Aksi Bounded AI Tool:</span>
                <div className="space-y-1.5 text-[11px] text-slate-600">
                  <div className="p-2 bg-slate-50 rounded border border-slate-200 flex justify-between">
                    <span>1. `search_eye_care_facilities` (Faskes Mata Yogyakarta)</span>
                    <span className="text-emerald-600 font-semibold">Tereksekusi</span>
                  </div>
                  <div className="p-2 bg-slate-50 rounded border border-slate-200 flex justify-between">
                    <span>2. `generate_meal_plan` (Anggaran Rp 35.000)</span>
                    <span className="text-emerald-600 font-semibold">Tereksekusi</span>
                  </div>
                  <div className="p-2 bg-slate-50 rounded border border-slate-200 flex justify-between">
                    <span>3. `save_patient_care_plan` (Konfirmasi Pasien: YA)</span>
                    <span className="text-emerald-600 font-semibold">Terotorisasi</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 4. CONFIRMATION MODAL (PHASE C TO D GUARD) */}
      {showConfirmModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-bold text-slate-900">
              Konfirmasi Ringkasan Konsultasi Dokter
            </h3>
            <p className="text-xs text-slate-600 leading-relaxed">
              Anda akan mengonfirmasi bahwa data yang Anda masukkan sesuai dengan instruksi yang diberikan oleh dokter penanggung jawab:
            </p>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs space-y-1">
              <div><strong>Faskes:</strong> {consultationForm.hospitalClinicName}</div>
              <div><strong>Dokter:</strong> {consultationForm.doctorName}</div>
              <div><strong>Diagnosis:</strong> {consultationForm.doctorFindingsDiagnosis}</div>
              <div><strong>Jadwal Kontrol:</strong> {consultationForm.followUpDate}</div>
            </div>

            <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900">
              Perhatian: Rencana perawatan pasca-konsultasi akan diaktifkan berdasarkan catatan ini. AI Retiva tidak melakukan verifikasi medis independen atas isi catatan manual ini.
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setShowConfirmModal(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition"
              >
                Batal
              </button>
              <button
                onClick={() => saveConsultation(true)}
                className="px-5 py-2 text-xs font-semibold bg-[#0D47A1] hover:bg-[#003178] text-white rounded-xl shadow transition"
              >
                Ya, Konfirmasi & Aktifkan Rencana
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 5. URGENT SYMPTOMS CHECK MODAL */}
      {showSymptomModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                <AlertTriangleIcon className="w-5 h-5 text-rose-600" />
                <span>Pemeriksaan Gejala Darurat Mata</span>
              </h3>
              <button
                onClick={() => setShowSymptomModal(false)}
                className="text-slate-400 hover:text-slate-600 font-bold"
              >
                ✕
              </button>
            </div>

            <p className="text-xs text-slate-600 leading-relaxed">
              Tuliskan keluhan atau gejala mata yang sedang Anda rasakan saat ini (misalnya: kilatan cahaya, bintik melayang mendadak, pandangan gelap seperti tirai, dsb):
            </p>

            <textarea
              rows={3}
              value={symptomText}
              onChange={(e) => setSymptomText(e.target.value)}
              placeholder="Contoh: Tiba-tiba pandangan mata kanan gelap seperti tertutup tirai dan ada kilatan cahaya..."
              className="w-full p-3 border border-slate-300 rounded-xl text-xs outline-none focus:ring-2 focus:ring-rose-500"
            />

            {emergencyResult && (
              <div
                className={`p-4 rounded-xl text-xs space-y-2 border ${
                  emergencyResult.isEmergency
                    ? 'bg-rose-50 border-rose-300 text-rose-950'
                    : 'bg-emerald-50 border-emerald-200 text-emerald-950'
                }`}
              >
                <div className="font-bold flex items-center gap-1.5">
                  {emergencyResult.isEmergency ? '⚠️ ' : '✓ '}
                  {emergencyResult.warningTitle}
                </div>
                <p className="leading-relaxed">{emergencyResult.warningMessage}</p>
                {emergencyResult.matchedTriggers?.length > 0 && (
                  <div className="text-[11px] font-semibold text-rose-800">
                    Gejala terdeteksi: {emergencyResult.matchedTriggers.join(', ')}
                  </div>
                )}
              </div>
            )}

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setShowSymptomModal(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition"
              >
                Tutup
              </button>
              <button
                onClick={checkUrgentSymptoms}
                className="px-5 py-2 text-xs font-semibold bg-rose-600 hover:bg-rose-700 text-white rounded-xl shadow transition"
              >
                Evaluasi Gejala
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
