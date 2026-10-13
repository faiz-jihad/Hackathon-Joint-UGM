'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import {
  EyeIcon,
  ShieldCheckIcon,
  HospitalIcon,
  ClockIcon,
  CheckIcon,
  AlertTriangleIcon,
  FileTextIcon,
  ArrowRightIcon,
} from './Icons';

import { clinicalStore, PatientData, ScreeningData } from '../lib/clinical-store';

interface PatientPortalViewProps {
  onSwitchCharacter: () => void;
  onLogout?: () => void;
  onOpenDoctorView?: () => void;
  onOpenAdminView?: () => void;
  currentUser?: {
    fullName?: string;
    email?: string;
    role?: string;
  } | null;
}

export function PatientPortalView({
  onSwitchCharacter,
  onLogout,
  onOpenDoctorView,
  onOpenAdminView,
  currentUser,
}: PatientPortalViewProps) {
  const [activeSubTab, setActiveSubTab] = useState<'screening' | 'referral' | 'education'>('screening');
  const [showFullDisclaimer, setShowFullDisclaimer] = useState<boolean>(false);

  // Dynamic Patient and Screening data sourced from DB via ClinicalStore
  const [patientData, setPatientData] = useState<PatientData | undefined>(() => {
    const list = clinicalStore.getPatients();
    const matched = list.find(
      (p) =>
        p.name.toLowerCase().includes(currentUser?.fullName?.toLowerCase() || '') ||
        p.nik === '3404084501650002'
    ) || list[0];
    return matched;
  });

  const [screeningList, setScreeningList] = useState<ScreeningData[]>(() => {
    return clinicalStore.getScreenings();
  });

  React.useEffect(() => {
    const unsubscribe = clinicalStore.subscribe(() => {
      const list = clinicalStore.getPatients();
      const matched = list.find(
        (p) =>
          p.name.toLowerCase().includes(currentUser?.fullName?.toLowerCase() || '') ||
          p.nik === '3404084501650002'
      ) || list[0];
      setPatientData(matched);
      setScreeningList(clinicalStore.getScreenings());
    });
    return () => unsubscribe();
  }, [currentUser]);

  const patient = {
    nik: patientData?.nik || '3404084501650002',
    name: patientData?.name || currentUser?.fullName || 'Ny. Siti Aminah',
    age: patientData?.age || 61,
    gender: patientData?.gender === 'P' ? 'Perempuan' : 'Laki-laki',
    phone: patientData?.phone || '0812-9876-5432',
    address: 'Jl. Kaliurang KM 9.2, Sleman, D.I. Yogyakarta',
    faskesPrimer: 'Puskesmas Sleman (Faskes Tingkat 1)',
    dmType: patientData?.diabetesProfile?.type === 'TYPE_1' ? 'Diabetes Mellitus Tipe 1' : 'Diabetes Mellitus Tipe 2',
    durationYears: patientData?.diabetesProfile?.durationYears || 12,
    hba1c: patientData?.diabetesProfile?.hba1c || 9.4,
    treatment: patientData?.diabetesProfile?.treatment === 'INSULIN' ? 'Terapi Insulin Harian & Metformin' : 'Metformin / OHO',
    bpjsNumber: '0001839201948',
  };

  const activeScreening = screeningList.find(
    (s) => (patientData && s.patientId === patientData.id) || (patientData && s.patientNik === patientData.nik)
  ) || screeningList[0];

  const latestScreening = {
    screeningId: activeScreening?.id || 'SCR-2026-0891',
    date: activeScreening?.capturedAt
      ? new Date(activeScreening.capturedAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })
      : '26 September 2026',
    time: '09:15 WIB',
    facility: 'Puskesmas Sleman',
    nakes: 'Dewi Sartika, A.Md.Kes',
    reviewerDoctor: activeScreening?.humanReview?.reviewerName || 'dr. Harianto, Sp.M(K)',
    reviewStatus: activeScreening?.humanReview?.status === 'CONFIRMED_AI'
      ? 'TERADJUDIKASI (SELESAI DITELAAH)'
      : (activeScreening?.reliabilityLabel || 'TERADJUDIKASI'),
    od: {
      eye: 'Mata Kanan (OD)',
      grade: activeScreening?.aiResult?.drGrade || 'MODERATE_NPDR',
      gradeLabel: activeScreening?.aiResult?.drLabel || 'Moderate Non-Proliferative Diabetic Retinopathy',
      confidence: activeScreening?.aiResult?.confidence || 89.2,
      recommendation: activeScreening?.recommendation?.action || 'Rujuk ke Spesialis Mata Poliklinik Vitreoretina dalam 4 minggu.',
      findings: ['Mikroaneurisma multipel kuadran temporal', 'Hard exudate perifovea', 'Tanpa neovaskularisasi'],
    },
    os: {
      eye: 'Mata Kiri (OS)',
      grade: 'MILD_NPDR',
      gradeLabel: 'Mild Non-Proliferative Diabetic Retinopathy',
      confidence: 93.1,
      recommendation: 'Evaluasi berkala 6 bulan & kendali metabolik HbA1c < 7.0%.',
      findings: ['Mikroaneurisma terisolasi kuadran nasal', 'Makula dalam batas normal'],
    },
    referral: {
      targetHospital: 'RSUP Dr. Sardjito Yogyakarta',
      serviceType: 'Poliklinik Mata Vitreoretina',
      nomorRujukan: '0119R0010926P00021',
      validUntil: '25 Desember 2026',
      urgency: 'Prioritas Sedang (Dalam 4 Minggu)',
    },
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: 'var(--slate-50)', display: 'flex', flexDirection: 'column' }}>
      {/* Patient Portal Header */}
      <header
        style={{
          backgroundColor: '#ffffff',
          borderBottom: '1px solid var(--border-subtle)',
          padding: '0.85rem 1.5rem',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          position: 'sticky',
          top: 0,
          zIndex: 40,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div
            style={{
              width: '42px',
              height: '42px',
              borderRadius: '9999px',
              overflow: 'hidden',
              border: '2px solid #ff2a85',
              position: 'relative',
              flexShrink: 0,
            }}
          >
            <Image
              src="/images/character/Pengguna.png"
              alt="Avatar Pasien"
              fill
              style={{ objectFit: 'cover' }}
            />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <h1 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--slate-900)' }}>
                Portal Pasien Mandiri RETIVA
              </h1>
              <span
                style={{
                  fontSize: '0.65rem',
                  fontWeight: 700,
                  backgroundColor: '#fce4ec',
                  color: '#c2185b',
                  padding: '0.2rem 0.5rem',
                  borderRadius: '9999px',
                }}
              >
                PERAN: PENGGUNA
              </span>
            </div>
            <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>
              {currentUser?.fullName || patient.name} • NIK: {patient.nik} • Faskes: {patient.faskesPrimer}
            </div>
          </div>
        </div>

        {/* Action Buttons & Switch Character */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
          <button
            type="button"
            className="arcade-switch-badge-btn"
            onClick={onSwitchCharacter}
            title="Kembali ke layar pemilihan peran"
          >
            <span style={{ fontSize: '1rem' }}>🎮</span>
            <span>Ganti Peran</span>
          </button>

          {onLogout && (
            <button
              type="button"
              className="admin-logout-btn"
              onClick={onLogout}
              title="Keluar dari sesi"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                <polyline points="16 17 21 12 16 7" />
                <line x1="21" y1="12" x2="9" y2="12" />
              </svg>
              <span>Keluar</span>
            </button>
          )}

          {onOpenDoctorView && (
            <button
              type="button"
              className="btn btn-outline btn-sm"
              onClick={onOpenDoctorView}
              title="Beralih ke Telaah Spesialis Mata"
            >
              Lihat Mode Dokter Sp.M
            </button>
          )}

          {onOpenAdminView && (
            <button
              type="button"
              className="btn btn-outline btn-sm"
              onClick={onOpenAdminView}
              title="Beralih ke Dashboard Admin"
            >
              Mode Admin
            </button>
          )}
        </div>
      </header>

      {/* Main Container */}
      <main style={{ maxWidth: '1200px', width: '100%', margin: '0 auto', padding: '1.5rem', flex: 1 }}>
        {/* Patient Profile Card */}
        <div
          style={{
            backgroundColor: '#ffffff',
            borderRadius: 'var(--radius-lg)',
            padding: '1.25rem 1.5rem',
            border: '1px solid var(--border-subtle)',
            boxShadow: 'var(--shadow-sm)',
            marginBottom: '1.5rem',
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '1.25rem',
            alignItems: 'center',
          }}
        >
          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--slate-500)', fontWeight: 600 }}>
              Profil Pasien
            </div>
            <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--slate-900)', marginTop: '0.2rem' }}>
              {patient.name}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--slate-600)', marginTop: '0.15rem' }}>
              {patient.gender}, {patient.age} Tahun • BPJS: {patient.bpjsNumber}
            </div>
          </div>

          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--slate-500)', fontWeight: 600 }}>
              Kondisi Metabolik
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.2rem' }}>
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#e11d48' }}>
                HbA1c {patient.hba1c}%
              </span>
              <span style={{ fontSize: '0.7rem', backgroundColor: '#ffe4e6', color: '#be123c', padding: '0.15rem 0.4rem', borderRadius: '4px', fontWeight: 600 }}>
                Tinggi
              </span>
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--slate-600)', marginTop: '0.15rem' }}>
              {patient.dmType} ({patient.durationYears} tahun)
            </div>
          </div>

          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--slate-500)', fontWeight: 600 }}>
              Faskes Primer Pembina
            </div>
            <div style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--slate-800)', marginTop: '0.2rem' }}>
              {patient.faskesPrimer}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
              Terintegrasi Rekam Medis SatuSehat
            </div>
          </div>

          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--slate-500)', fontWeight: 600 }}>
              Status Rujukan
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.2rem' }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#f59e0b' }} />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#b45309' }}>
                Perlu Rujukan Vitreoretina
              </span>
            </div>
            <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
              RSUP Dr. Sardjito Yogyakarta
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div style={{ display: 'flex', gap: '0.5rem', borderBottom: '1px solid var(--border-subtle)', marginBottom: '1.5rem' }}>
          <button
            type="button"
            style={{
              padding: '0.65rem 1.25rem',
              fontSize: '0.85rem',
              fontWeight: 600,
              border: 'none',
              borderBottom: activeSubTab === 'screening' ? '3px solid #ff2a85' : '3px solid transparent',
              backgroundColor: 'transparent',
              color: activeSubTab === 'screening' ? '#c2185b' : 'var(--slate-600)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
            }}
            onClick={() => setActiveSubTab('screening')}
          >
            <EyeIcon size={16} />
            <span>Hasil Pemeriksaan Retina Terkini</span>
          </button>

          <button
            type="button"
            style={{
              padding: '0.65rem 1.25rem',
              fontSize: '0.85rem',
              fontWeight: 600,
              border: 'none',
              borderBottom: activeSubTab === 'referral' ? '3px solid #ff2a85' : '3px solid transparent',
              backgroundColor: 'transparent',
              color: activeSubTab === 'referral' ? '#c2185b' : 'var(--slate-600)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
            }}
            onClick={() => setActiveSubTab('referral')}
          >
            <HospitalIcon size={16} />
            <span>Surat Rujukan &amp; SatuSehat</span>
          </button>

          <button
            type="button"
            style={{
              padding: '0.65rem 1.25rem',
              fontSize: '0.85rem',
              fontWeight: 600,
              border: 'none',
              borderBottom: activeSubTab === 'education' ? '3px solid #ff2a85' : '3px solid transparent',
              backgroundColor: 'transparent',
              color: activeSubTab === 'education' ? '#c2185b' : 'var(--slate-600)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
            }}
            onClick={() => setActiveSubTab('education')}
          >
            <FileTextIcon size={16} />
            <span>Panduan Pasien &amp; Pencegahan Kebutaan</span>
          </button>
        </div>

        {/* Tab 1: Screening Results */}
        {activeSubTab === 'screening' && (
          <div>
            {/* Banner Verification */}
            <div
              style={{
                backgroundColor: '#f0fdf4',
                border: '1px solid #bbf7d0',
                borderRadius: 'var(--radius-md)',
                padding: '0.85rem 1.25rem',
                marginBottom: '1.25rem',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '0.75rem',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div
                  style={{
                    backgroundColor: '#16a34a',
                    color: '#ffffff',
                    width: '28px',
                    height: '28px',
                    borderRadius: '50%',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <CheckIcon size={16} />
                </div>
                <div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#166534' }}>
                    Pemeriksaan Terverifikasi Spesialis Mata
                  </div>
                  <div style={{ fontSize: '0.75rem', color: '#15803d' }}>
                    Ditinjau dan diadjudikasi oleh <strong>{latestScreening.reviewerDoctor}</strong> pada {latestScreening.date} di {latestScreening.facility}.
                  </div>
                </div>
              </div>

              <div style={{ fontSize: '0.75rem', color: '#166534', fontFamily: 'monospace' }}>
                ID: {latestScreening.screeningId}
              </div>
            </div>

            {/* Bilateral OD / OS Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem', marginBottom: '1.5rem' }}>
              {/* Mata Kanan (OD) */}
              <div
                style={{
                  backgroundColor: '#ffffff',
                  borderRadius: 'var(--radius-lg)',
                  border: '1px solid var(--border-subtle)',
                  padding: '1.25rem',
                  boxShadow: 'var(--shadow-sm)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                  <span style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--slate-900)' }}>
                    {latestScreening.od.eye}
                  </span>
                  <span
                    style={{
                      fontSize: '0.7rem',
                      fontWeight: 700,
                      backgroundColor: '#fef3c7',
                      color: '#b45309',
                      padding: '0.2rem 0.5rem',
                      borderRadius: '4px',
                    }}
                  >
                    Moderate NPDR
                  </span>
                </div>

                <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-md)', marginBottom: '0.85rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600 }}>Diagnosis Klinis:</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--slate-800)', marginTop: '0.2rem' }}>
                    {latestScreening.od.gradeLabel}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)', marginTop: '0.35rem' }}>
                    Tingkat Keyakinan AI: <strong>{latestScreening.od.confidence}%</strong> (Sesuai dengan Adjudikasi Dokter)
                  </div>
                </div>

                <div style={{ marginBottom: '0.85rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600, marginBottom: '0.35rem' }}>Temuan Retina:</div>
                  <ul style={{ paddingLeft: '1.2rem', fontSize: '0.775rem', color: 'var(--slate-700)', lineHeight: '1.5' }}>
                    {latestScreening.od.findings.map((f, i) => (
                      <li key={i}>{f}</li>
                    ))}
                  </ul>
                </div>

                <div style={{ padding: '0.65rem', backgroundColor: '#fff7ed', border: '1px solid #ffedd5', borderRadius: 'var(--radius-md)', fontSize: '0.775rem', color: '#9a3412' }}>
                  <strong>Rekomendasi Tindakan:</strong> {latestScreening.od.recommendation}
                </div>
              </div>

              {/* Mata Kiri (OS) */}
              <div
                style={{
                  backgroundColor: '#ffffff',
                  borderRadius: 'var(--radius-lg)',
                  border: '1px solid var(--border-subtle)',
                  padding: '1.25rem',
                  boxShadow: 'var(--shadow-sm)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                  <span style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--slate-900)' }}>
                    {latestScreening.os.eye}
                  </span>
                  <span
                    style={{
                      fontSize: '0.7rem',
                      fontWeight: 700,
                      backgroundColor: '#e0f2fe',
                      color: '#0369a1',
                      padding: '0.2rem 0.5rem',
                      borderRadius: '4px',
                    }}
                  >
                    Mild NPDR
                  </span>
                </div>

                <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-md)', marginBottom: '0.85rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600 }}>Diagnosis Klinis:</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--slate-800)', marginTop: '0.2rem' }}>
                    {latestScreening.os.gradeLabel}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)', marginTop: '0.35rem' }}>
                    Tingkat Keyakinan AI: <strong>{latestScreening.os.confidence}%</strong> (Sesuai dengan Adjudikasi Dokter)
                  </div>
                </div>

                <div style={{ marginBottom: '0.85rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600, marginBottom: '0.35rem' }}>Temuan Retina:</div>
                  <ul style={{ paddingLeft: '1.2rem', fontSize: '0.775rem', color: 'var(--slate-700)', lineHeight: '1.5' }}>
                    {latestScreening.os.findings.map((f, i) => (
                      <li key={i}>{f}</li>
                    ))}
                  </ul>
                </div>

                <div style={{ padding: '0.65rem', backgroundColor: '#f0fdf4', border: '1px solid #dcfce7', borderRadius: 'var(--radius-md)', fontSize: '0.775rem', color: '#166534' }}>
                  <strong>Rekomendasi Tindakan:</strong> {latestScreening.os.recommendation}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Referral & SatuSehat */}
        {activeSubTab === 'referral' && (
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border-subtle)',
              padding: '1.5rem',
              boxShadow: 'var(--shadow-sm)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <div>
                <span style={{ fontSize: '0.75rem', color: '#2563eb', fontWeight: 700, textTransform: 'uppercase' }}>
                  Surat Rujukan Digital BPJS Kesehatan &amp; SatuSehat
                </span>
                <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--slate-900)', marginTop: '0.2rem' }}>
                  Rujukan Spesialis Vitreoretina
                </h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--slate-600)', marginTop: '0.2rem' }}>
                  Faskes Asal: <strong>{latestScreening.facility}</strong> → Faskes Rujukan: <strong>{latestScreening.referral.targetHospital}</strong>
                </p>
              </div>

              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>Nomor Rujukan BPJS:</div>
                <div style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--slate-900)', fontFamily: 'monospace' }}>
                  {latestScreening.referral.nomorRujukan}
                </div>
                <div style={{ fontSize: '0.7rem', color: '#16a34a', fontWeight: 600 }}>
                  Aktif s.d {latestScreening.referral.validUntil}
                </div>
              </div>
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
                gap: '1rem',
                backgroundColor: 'var(--slate-50)',
                padding: '1.25rem',
                borderRadius: 'var(--radius-md)',
                marginBottom: '1.5rem',
              }}
            >
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600 }}>Tujuan Rujukan:</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--slate-800)', marginTop: '0.15rem' }}>
                  {latestScreening.referral.targetHospital}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)' }}>
                  {latestScreening.referral.serviceType}
                </div>
              </div>

              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600 }}>Tingkat Urgensi:</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#d97706', marginTop: '0.15rem' }}>
                  {latestScreening.referral.urgency}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)' }}>
                  Evaluasi fotokoagulasi laser / injeksi anti-VEGF
                </div>
              </div>

              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', fontWeight: 600 }}>Dokter Perujuk:</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--slate-800)', marginTop: '0.15rem' }}>
                  {latestScreening.reviewerDoctor}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)' }}>
                  NIP/STR: 34.1.1.100.2.22
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
              <button
                type="button"
                className="btn btn-primary btn-sm"
                onClick={() => alert('Mengunduh e-Rujukan BPJS & Kartu SatuSehat format PDF...')}
              >
                Unduh Lembar Rujukan BPJS (PDF)
              </button>
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={() => alert('Kode QR SatuSehat untuk pendaftaran mandiri faskes lanjutan: QR-SATUSEHAT-3404084501650002')}
              >
                Tampilkan QR Code SatuSehat
              </button>
            </div>
          </div>
        )}

        {/* Tab 3: Patient Education */}
        {activeSubTab === 'education' && (
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border-subtle)',
              padding: '1.5rem',
              boxShadow: 'var(--shadow-sm)',
            }}
          >
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--slate-900)', marginBottom: '0.5rem' }}>
              4 Langkah Menjaga Penglihatan Pasien Diabetes (Perdami 2024)
            </h3>
            <p style={{ fontSize: '0.825rem', color: 'var(--slate-600)', marginBottom: '1.25rem' }}>
              Retinopati Diabetik pada tahap awal seringkali tidak bergejala. Pencegahan kebutaan permanen dapat dicapai dengan kontrol metabolik ketat.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
              <div style={{ padding: '1rem', backgroundColor: '#f0fdfa', border: '1px solid #ccfbf1', borderRadius: 'var(--radius-md)' }}>
                <div style={{ fontSize: '1.25rem', marginBottom: '0.4rem' }}>🩸</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#0f766e', marginBottom: '0.25rem' }}>
                  Target HbA1c &lt; 7.0%
                </div>
                <div style={{ fontSize: '0.775rem', color: '#115e59', lineHeight: '1.4' }}>
                  Kendalikan gula darah dengan konsumsi obat teratur atau insulin sesuai petunjuk dokter Puskesmas.
                </div>
              </div>

              <div style={{ padding: '1rem', backgroundColor: '#f0f9ff', border: '1px solid #bae6fd', borderRadius: 'var(--radius-md)' }}>
                <div style={{ fontSize: '1.25rem', marginBottom: '0.4rem' }}>👁️</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#0369a1', marginBottom: '0.25rem' }}>
                  Skrining Retina Rutin
                </div>
                <div style={{ fontSize: '0.775rem', color: '#075985', lineHeight: '1.4' }}>
                  Lakukan foto fundus minimal 1 kali setahun untuk mendeteksi kebocoran pembuluh darah sedini mungkin.
                </div>
              </div>

              <div style={{ padding: '1rem', backgroundColor: '#fffbeb', border: '1px solid #fde68a', borderRadius: 'var(--radius-md)' }}>
                <div style={{ fontSize: '1.25rem', marginBottom: '0.4rem' }}>🩺</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#b45309', marginBottom: '0.25rem' }}>
                  Kendali Tekanan Darah
                </div>
                <div style={{ fontSize: '0.775rem', color: '#92400e', lineHeight: '1.4' }}>
                  Pertahankan tensi darah di bawah 130/80 mmHg untuk mengurangi tekanan mikrovaskular retina.
                </div>
              </div>

              <div style={{ padding: '1rem', backgroundColor: '#fdf2f8', border: '1px solid #fbcfe8', borderRadius: 'var(--radius-md)' }}>
                <div style={{ fontSize: '1.25rem', marginBottom: '0.4rem' }}>🥗</div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#be185d', marginBottom: '0.25rem' }}>
                  Pola Hidup Sehat &amp; Diet
                </div>
                <div style={{ fontSize: '0.775rem', color: '#9d174d', lineHeight: '1.4' }}>
                  Batasi asupan karbohidrat sederhana, berhenti merokok, dan rutin berolahraga ringan minimal 150 menit/minggu.
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer
        style={{
          backgroundColor: '#ffffff',
          borderTop: '1px solid var(--border-subtle)',
          padding: '1rem 1.5rem',
          fontSize: '0.75rem',
          color: 'var(--slate-500)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '0.75rem',
        }}
      >
        <div>
          <strong>RETIVA Patient Portal v1.0.0</strong> — Terhubung ke SatuSehat Kemenkes RI &amp; BPJS Kesehatan.
        </div>
        <div>
          Kerahasiaan data medis dilindungi UU PDP No. 27/2022 &amp; Permenkes No. 24/2022.
        </div>
      </footer>
    </div>
  );
}
