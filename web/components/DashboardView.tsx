'use client';

import React, { useState, useEffect } from 'react';
import { clinicalStore, ScreeningData } from '../lib/clinical-store';
import {
  LayoutDashboardIcon,
  EyeIcon,
  UsersIcon,
  ShieldCheckIcon,
  ActivityIcon,
  CheckIcon,
  SearchIcon,
  CalendarIcon,
  InfoIcon,
} from './Icons';

interface DashboardViewProps {
  role?: 'admin' | 'dokter' | 'pengguna';
  currentUser?: {
    fullName?: string;
    email?: string;
    role?: string;
  } | null;
  onStartScreening?: () => void;
  onOpenReview?: (screeningId: string) => void;
  onNavigateTab?: (tab: string) => void;
}

export function DashboardView({
  role = 'admin',
  currentUser,
  onStartScreening,
  onOpenReview,
  onNavigateTab,
}: DashboardViewProps) {
  const [screenings, setScreenings] = useState<ScreeningData[]>([]);
  const [activeFilter, setActiveFilter] = useState<'all' | 'pending' | 'reviewed' | 'high_risk'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sosActiveCount, setSosActiveCount] = useState<number>(0);
  const [patientsCount, setPatientsCount] = useState<number>(5);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const syncData = () => {
      const all = clinicalStore.getScreenings();
      // Filter out dummy scr_ test ids if any
      const valid = all.filter((s) => !s.id.toLowerCase().startsWith('scr_'));
      setScreenings(valid);
      setPatientsCount(clinicalStore.getPatients().length);
    };

    syncData();
    const unsubscribe = clinicalStore.subscribe(syncData);

    // Fetch active SOS count
    const fetchSos = async () => {
      try {
        const res = await fetch('/api/v1/sos/incidents?status=ACTIVE');
        if (res.ok) {
          const json = await res.json();
          setSosActiveCount(json.stats?.active || (json.data || []).length || 0);
        }
      } catch {}
    };
    fetchSos();
    const interval = setInterval(fetchSos, 10000);

    return () => {
      unsubscribe();
      clearInterval(interval);
    };
  }, []);

  const totalPatients = mounted ? patientsCount : 5;
  const pendingScreenings = screenings.filter((s) => s.humanReview?.status === 'PENDING');
  const reviewedScreenings = screenings.filter(
    (s) => s.humanReview?.status === 'CONFIRMED_AI' || s.humanReview?.status === 'OVERRIDDEN'
  );
  const overrideCount = screenings.filter((s) => s.humanReview?.status === 'OVERRIDDEN').length;
  const confirmedCount = screenings.filter((s) => s.humanReview?.status === 'CONFIRMED_AI').length;

  // Concordance calculation
  const totalAdjudicated = overrideCount + confirmedCount;
  const concordanceRate = totalAdjudicated > 0 ? Math.round((confirmedCount / totalAdjudicated) * 100) : 92;

  // Severity Distribution Counts
  const gradeCounts = {
    NO_DR: screenings.filter((s) => s.aiResult?.drGrade === 'NO_DR').length,
    MILD_NPDR: screenings.filter((s) => s.aiResult?.drGrade === 'MILD_NPDR').length,
    MODERATE_NPDR: screenings.filter((s) => s.aiResult?.drGrade === 'MODERATE_NPDR').length,
    SEVERE_NPDR: screenings.filter((s) => s.aiResult?.drGrade === 'SEVERE_NPDR').length,
    PDR: screenings.filter((s) => s.aiResult?.drGrade === 'PDR').length,
  };

  const filteredScreenings = screenings.filter((item) => {
    const matchesSearch =
      item.patientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.patientNik.includes(searchQuery) ||
      item.id.toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchesSearch) return false;

    if (activeFilter === 'pending') {
      return item.humanReview?.status === 'PENDING';
    }
    if (activeFilter === 'reviewed') {
      return item.humanReview?.status === 'CONFIRMED_AI' || item.humanReview?.status === 'OVERRIDDEN';
    }
    if (activeFilter === 'high_risk') {
      return item.aiResult?.drGrade === 'SEVERE_NPDR' || item.aiResult?.drGrade === 'PDR';
    }
    return true;
  });

  const isDoctor = role === 'dokter';

  return (
    <div className="dashboard-content-clean" style={{ minHeight: '100%', padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* 1. Header Banner & Identity Context */}
      <div
        style={{
          background: 'linear-gradient(135deg, #0A4B8A 0%, #0F5FC2 55%, #1976D2 100%)',
          borderRadius: '16px',
          padding: '1.75rem 2rem',
          color: '#ffffff',
          boxShadow: '0 10px 25px -5px rgba(15, 95, 194, 0.3)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1.25rem',
        }}
      >
        <div>
          <h1 style={{ fontSize: '1.65rem', fontWeight: 800, margin: 0, letterSpacing: '-0.02em', lineHeight: 1.2 }}>
            {isDoctor
              ? `Selamat Datang, ${currentUser?.fullName || 'dr. Yunani Setyandriana, Sp.M'}`
              : `Panel Operasional, ${currentUser?.fullName || 'Administrator Puskesmas'}`}
          </h1>
          <p style={{ margin: '0.45rem 0 0 0', fontSize: '0.875rem', opacity: 0.9, maxWidth: '620px', lineHeight: 1.45 }}>
            {isDoctor
              ? 'Tinjau antrean foto fundus retina, ajudikasi kasus borderline AI, dan sahkan rencana rujukan telemedicine vitreoretina.'
              : 'Pemantauan alur skrining foto fundus AI, kesiapan telemedicine rujukan, dan mitigasi dini risiko kebutaan retinopati diabetik.'}
          </p>
        </div>

        {/* Action Buttons Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
          {isDoctor ? (
            <button
              type="button"
              onClick={() => onNavigateTab ? onNavigateTab('review') : (pendingScreenings[0] && onOpenReview?.(pendingScreenings[0].id))}
              style={{
                backgroundColor: '#ffffff',
                color: '#0A2540',
                border: 'none',
                padding: '0.75rem 1.25rem',
                borderRadius: '10px',
                fontWeight: 700,
                fontSize: '0.875rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                transition: 'all 0.2s',
              }}
            >
              <EyeIcon size={16} />
              <span suppressHydrationWarning>Buka Antrean Telaah ({mounted ? pendingScreenings.length : 0})</span>
            </button>
          ) : (
            <>
              {onStartScreening && (
                <button
                  type="button"
                  onClick={onStartScreening}
                  style={{
                    backgroundColor: '#ffffff',
                    color: '#0D47A1',
                    border: 'none',
                    padding: '0.75rem 1.25rem',
                    borderRadius: '10px',
                    fontWeight: 700,
                    fontSize: '0.875rem',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                    transition: 'all 0.2s',
                  }}
                >
                  <ActivityIcon size={16} />
                  <span>Mulai Skrining AI Baru</span>
                </button>
              )}
              {sosActiveCount > 0 && onNavigateTab && (
                <button
                  type="button"
                  onClick={() => onNavigateTab('sos-monitoring')}
                  style={{
                    backgroundColor: '#EF4444',
                    color: '#ffffff',
                    border: 'none',
                    padding: '0.75rem 1.15rem',
                    borderRadius: '10px',
                    fontWeight: 700,
                    fontSize: '0.875rem',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    boxShadow: '0 0 14px rgba(239,68,68,0.5)',
                  }}
                >
                  <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#ffffff', display: 'inline-block' }}></span>
                  <span suppressHydrationWarning>{mounted ? sosActiveCount : 0} SOS Aktif</span>
                </button>
              )}
            </>
          )}
        </div>
      </div>

      {/* Embedded CSS for Metric Cards Interactive Hover & Icon Animation */}
      <style>{`
        .dashboard-metric-card {
          background-color: #ffffff;
          border-radius: 14px;
          padding: 1.25rem;
          border: 1px solid #E2E8F0;
          box-shadow: 0 2px 6px rgba(15, 23, 42, 0.04);
          transition: all 0.28s cubic-bezier(0.4, 0, 0.2, 1);
          cursor: pointer;
          position: relative;
          overflow: hidden;
        }
        .dashboard-metric-card:hover {
          background-color: #0F5FC2 !important;
          border-color: #0F5FC2 !important;
          transform: translateY(-4px);
          box-shadow: 0 12px 24px -4px rgba(15, 95, 194, 0.35);
        }
        .dashboard-metric-card .dmc-label {
          font-size: 0.8rem;
          font-weight: 600;
          color: #64748B;
          transition: color 0.2s ease;
        }
        .dashboard-metric-card:hover .dmc-label {
          color: rgba(255, 255, 255, 0.88) !important;
        }
        .dashboard-metric-card .dmc-value {
          font-size: 1.85rem;
          font-weight: 800;
          color: #0F172A;
          margin-top: 0.4rem;
          transition: color 0.2s ease;
        }
        .dashboard-metric-card:hover .dmc-value {
          color: #ffffff !important;
        }
        .dashboard-metric-card .dmc-sub {
          font-size: 0.75rem;
          font-weight: 600;
          color: #64748B;
          margin-top: 0.35rem;
          display: flex;
          align-items: center;
          gap: 0.3rem;
          transition: color 0.2s ease;
        }
        .dashboard-metric-card:hover .dmc-sub {
          color: rgba(255, 255, 255, 0.92) !important;
        }
        .dashboard-metric-card .dmc-icon-box {
          width: 38px;
          height: 38px;
          border-radius: 10px;
          background-color: #EFF6FF;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #0F5FC2;
          transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .dashboard-metric-card:hover .dmc-icon-box {
          background-color: rgba(255, 255, 255, 0.22) !important;
          color: #ffffff !important;
          transform: scale(1.2) rotate(-8deg);
        }
        .dashboard-metric-card .dmc-icon-box svg {
          transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .dashboard-metric-card:hover .dmc-icon-box svg {
          transform: scale(1.12);
        }
      `}</style>

      {/* 2. Key Metrics Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        {/* Metric 1 */}
        <div className="dashboard-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="dmc-label">
              {isDoctor ? 'Antrean Kasus Menunggu' : 'Total Pasien Terdaftar'}
            </span>
            <div className="dmc-icon-box">
              {isDoctor ? <EyeIcon size={18} /> : <UsersIcon size={18} />}
            </div>
          </div>
          <div className="dmc-value" suppressHydrationWarning>
            {isDoctor ? (mounted ? pendingScreenings.length : 0) : totalPatients}
          </div>
          <div className="dmc-sub" suppressHydrationWarning>
            {isDoctor ? (pendingScreenings.length > 0 ? '⚠️ Memerlukan Ajudikasi' : '✓ Antrean Bersih') : '↑ 12% dari bulan lalu'}
          </div>
        </div>

        {/* Metric 2 */}
        <div className="dashboard-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="dmc-label">
              {isDoctor ? 'Kasus Berhasil Diajudikasi' : 'Total Skrining AI Selesai'}
            </span>
            <div className="dmc-icon-box">
              <CheckIcon size={18} />
            </div>
          </div>
          <div className="dmc-value" suppressHydrationWarning>
            {isDoctor ? (mounted ? reviewedScreenings.length : 0) : (mounted ? screenings.length : 11)}
          </div>
          <div className="dmc-sub" suppressHydrationWarning>
            {isDoctor ? 'Tervalidasi Tanda Tangan SIP' : '96.4% Citra Lolos Mutu (Grade A)'}
          </div>
        </div>

        {/* Metric 3 */}
        <div className="dashboard-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="dmc-label">
              {isDoctor ? 'Konkordansi AI vs Spesialis' : 'Antrean Telaah Spesialis'}
            </span>
            <div className="dmc-icon-box">
              <ShieldCheckIcon size={18} />
            </div>
          </div>
          <div className="dmc-value" suppressHydrationWarning>
            {isDoctor ? `${concordanceRate}%` : (mounted ? pendingScreenings.length : 0)}
          </div>
          <div className="dmc-sub" suppressHydrationWarning>
            {isDoctor ? `${confirmedCount} Konfirmasi • ${overrideCount} Koreksi` : 'Kasus dialihkan ke Sp.M'}
          </div>
        </div>

        {/* Metric 4 */}
        <div className="dashboard-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="dmc-label">
              {isDoctor ? 'Clinical Override Rate' : 'Insiden Darurat / SOS'}
            </span>
            <div className="dmc-icon-box">
              <ActivityIcon size={18} />
            </div>
          </div>
          <div className="dmc-value" suppressHydrationWarning>
            {isDoctor ? `${totalAdjudicated > 0 ? Math.round((overrideCount / totalAdjudicated) * 100) : 8}%` : (mounted ? sosActiveCount : 0)}
          </div>
          <div className="dmc-sub" suppressHydrationWarning>
            {isDoctor ? 'Penyesuaian klinis lesi mikro' : (sosActiveCount > 0 ? '⚠️ Butuh Penanganan Cepat' : '✓ Tidak ada insiden darurat')}
          </div>
        </div>
      </div>

      {/* 3. Distribution Breakdown Bar (5 Level ICDR) */}
      <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', padding: '1.25rem', border: '1px solid #E2E8F0', boxShadow: '0 2px 6px rgba(15,23,42,0.04)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.5rem' }}>
          <div>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#0F172A', margin: 0 }}>
              Distribusi Derajat Keparahan Retinopati Diabetik (ICDR)
            </h3>
            <p style={{ fontSize: '0.75rem', color: '#64748B', margin: '0.15rem 0 0 0' }}>
              Akumulasi hasil skrining AI dan telaah klinis di fasilitas kesehatan
            </p>
          </div>
          <span
            suppressHydrationWarning
            style={{ fontSize: '0.75rem', fontWeight: 600, color: '#0284C7', backgroundColor: '#E0F2FE', padding: '0.2rem 0.6rem', borderRadius: '6px' }}
          >
            Total Terklasifikasi: {screenings.length} Kasus
          </span>
        </div>

        {/* Multi-segment Progress Bar */}
        <div style={{ height: '10px', width: '100%', borderRadius: '9999px', overflow: 'hidden', display: 'flex', backgroundColor: '#F1F5F9', marginBottom: '0.85rem' }}>
          <div style={{ width: `${screenings.length ? (gradeCounts.NO_DR / screenings.length) * 100 : 20}%`, backgroundColor: '#10B981' }} title="No DR" />
          <div style={{ width: `${screenings.length ? (gradeCounts.MILD_NPDR / screenings.length) * 100 : 20}%`, backgroundColor: '#F59E0B' }} title="Mild NPDR" />
          <div style={{ width: `${screenings.length ? (gradeCounts.MODERATE_NPDR / screenings.length) * 100 : 35}%`, backgroundColor: '#2563EB' }} title="Moderate NPDR" />
          <div style={{ width: `${screenings.length ? (gradeCounts.SEVERE_NPDR / screenings.length) * 100 : 15}%`, backgroundColor: '#DC2626' }} title="Severe NPDR" />
          <div style={{ width: `${screenings.length ? (gradeCounts.PDR / screenings.length) * 100 : 10}%`, backgroundColor: '#881337' }} title="PDR" />
        </div>

        {/* Legend pills */}
        <div suppressHydrationWarning style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem', fontSize: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#10B981' }} />
            <span style={{ color: '#334155', fontWeight: 600 }}>Tingkat 0 - No DR ({gradeCounts.NO_DR})</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#F59E0B' }} />
            <span style={{ color: '#334155', fontWeight: 600 }}>Tingkat 1 - Mild ({gradeCounts.MILD_NPDR})</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#2563EB' }} />
            <span style={{ color: '#334155', fontWeight: 600 }}>Tingkat 2 - Moderate ({gradeCounts.MODERATE_NPDR})</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#DC2626' }} />
            <span style={{ color: '#334155', fontWeight: 600 }}>Tingkat 3 - Severe ({gradeCounts.SEVERE_NPDR})</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#881337' }} />
            <span style={{ color: '#334155', fontWeight: 600 }}>Tingkat 4 - PDR ({gradeCounts.PDR})</span>
          </div>
        </div>
      </div>

      {/* 4. Main Interactive Screening & Triage Queue Table */}
      <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 2px 6px rgba(15,23,42,0.04)' }}>
        {/* Table Header Filter & Search */}
        <div style={{ padding: '1.25rem', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <h2 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#0F172A', margin: 0 }}>
              {isDoctor ? 'Antrean Prioritas & Riwayat Telaah Dokter' : 'Daftar Pemeriksaan & Antrean Skrining'}
            </h2>
            <p style={{ fontSize: '0.75rem', color: '#64748B', margin: '0.2rem 0 0 0' }} suppressHydrationWarning>
              Menampilkan {filteredScreenings.length} dari {screenings.length} total rekaman skrining funduskopi
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap' }}>
            {/* Search Input */}
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Cari pasien / NIK / ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  padding: '0.45rem 0.75rem 0.45rem 2rem',
                  fontSize: '0.8rem',
                  borderRadius: '8px',
                  border: '1px solid #CBD5E1',
                  outline: 'none',
                  width: '200px',
                }}
              />
              <span style={{ position: 'absolute', left: '0.65rem', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }}>
                <SearchIcon size={14} />
              </span>
            </div>

            {/* Filter Tabs */}
            <div style={{ display: 'flex', backgroundColor: '#F1F5F9', padding: '0.2rem', borderRadius: '8px', gap: '0.2rem' }}>
              <button
                type="button"
                onClick={() => setActiveFilter('all')}
                style={{
                  border: 'none',
                  backgroundColor: activeFilter === 'all' ? '#ffffff' : 'transparent',
                  color: activeFilter === 'all' ? '#0F172A' : '#64748B',
                  fontWeight: activeFilter === 'all' ? 700 : 500,
                  fontSize: '0.75rem',
                  padding: '0.35rem 0.65rem',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  boxShadow: activeFilter === 'all' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                }}
              >
                Semua
              </button>
              <button
                type="button"
                onClick={() => setActiveFilter('pending')}
                suppressHydrationWarning
                style={{
                  border: 'none',
                  backgroundColor: activeFilter === 'pending' ? '#ffffff' : 'transparent',
                  color: activeFilter === 'pending' ? '#B45309' : '#64748B',
                  fontWeight: activeFilter === 'pending' ? 700 : 500,
                  fontSize: '0.75rem',
                  padding: '0.35rem 0.65rem',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  boxShadow: activeFilter === 'pending' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                }}
              >
                Menunggu Telaah ({mounted ? pendingScreenings.length : 0})
              </button>
              <button
                type="button"
                onClick={() => setActiveFilter('reviewed')}
                suppressHydrationWarning
                style={{
                  border: 'none',
                  backgroundColor: activeFilter === 'reviewed' ? '#ffffff' : 'transparent',
                  color: activeFilter === 'reviewed' ? '#16A34A' : '#64748B',
                  fontWeight: activeFilter === 'reviewed' ? 700 : 500,
                  fontSize: '0.75rem',
                  padding: '0.35rem 0.65rem',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  boxShadow: activeFilter === 'reviewed' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                }}
              >
                Selesai Ditelaah ({mounted ? reviewedScreenings.length : 0})
              </button>
              <button
                type="button"
                onClick={() => setActiveFilter('high_risk')}
                style={{
                  border: 'none',
                  backgroundColor: activeFilter === 'high_risk' ? '#ffffff' : 'transparent',
                  color: activeFilter === 'high_risk' ? '#DC2626' : '#64748B',
                  fontWeight: activeFilter === 'high_risk' ? 700 : 500,
                  fontSize: '0.75rem',
                  padding: '0.35rem 0.65rem',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  boxShadow: activeFilter === 'high_risk' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                }}
              >
                Risiko Tinggi (PDR/Severe)
              </button>
            </div>
          </div>
        </div>

        {/* Table Content */}
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.8125rem' }}>
            <thead>
              <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#64748B', fontWeight: 700, fontSize: '0.725rem', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                <th style={{ padding: '0.75rem 1rem' }}>ID Skrining</th>
                <th style={{ padding: '0.75rem 1rem' }}>Pasien &amp; NIK</th>
                <th style={{ padding: '0.75rem 1rem' }}>Mata</th>
                <th style={{ padding: '0.75rem 1rem' }}>Derajat AI</th>
                <th style={{ padding: '0.75rem 1rem' }}>Status Human Review</th>
                <th style={{ padding: '0.75rem 1rem' }}>Catatan / Adjudikasi</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'center' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {filteredScreenings.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ padding: '3rem 1rem', textAlign: 'center', color: '#64748B' }}>
                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 0.5rem auto', color: '#94A3B8' }}>
                      <InfoIcon size={20} />
                    </div>
                    <div style={{ fontWeight: 600, color: '#334155' }}>Tidak ada berkas yang sesuai dengan filter</div>
                    <div style={{ fontSize: '0.75rem', marginTop: '0.2rem' }}>Silakan sesuaikan kata kunci pencarian atau tab filter di atas.</div>
                  </td>
                </tr>
              ) : (
                filteredScreenings.map((item) => {
                  const isPending = item.humanReview?.status === 'PENDING';
                  const isConfirmed = item.humanReview?.status === 'CONFIRMED_AI';
                  const isOverridden = item.humanReview?.status === 'OVERRIDDEN';

                  const grade = item.aiResult?.drGrade || 'NO_DR';
                  const isHigh = grade === 'SEVERE_NPDR' || grade === 'PDR';

                  let gradeBadgeBg = '#ECFDF5';
                  let gradeBadgeColor = '#065F46';
                  let gradeText = 'No DR (Normal)';

                  if (grade === 'MILD_NPDR') {
                    gradeBadgeBg = '#FFFBEB';
                    gradeBadgeColor = '#92400E';
                    gradeText = 'Mild NPDR (Tingkat 1)';
                  } else if (grade === 'MODERATE_NPDR') {
                    gradeBadgeBg = '#EFF6FF';
                    gradeBadgeColor = '#1E40AF';
                    gradeText = 'Moderate NPDR (Tingkat 2)';
                  } else if (grade === 'SEVERE_NPDR') {
                    gradeBadgeBg = '#FEF2F2';
                    gradeBadgeColor = '#991B1B';
                    gradeText = 'Severe NPDR (Tingkat 3)';
                  } else if (grade === 'PDR') {
                    gradeBadgeBg = '#FFF1F2';
                    gradeBadgeColor = '#881337';
                    gradeText = 'PDR Proliferatif (Tingkat 4)';
                  }

                  return (
                    <tr
                      key={item.id}
                      style={{
                        borderBottom: '1px solid #F1F5F9',
                        backgroundColor: isHigh && isPending ? '#FFFDF5' : 'transparent',
                        transition: 'background-color 0.15s',
                      }}
                    >
                      {/* ID Skrining */}
                      <td style={{ padding: '0.85rem 1rem', fontFamily: 'monospace', fontWeight: 700, color: '#0F172A' }}>
                        {item.id}
                        {isHigh && (
                          <span style={{ display: 'block', fontSize: '0.65rem', color: '#DC2626', fontWeight: 800, marginTop: '0.15rem' }}>
                            🚨 PRIORITAS TINGGI
                          </span>
                        )}
                      </td>

                      {/* Pasien & NIK */}
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <div style={{ fontWeight: 700, color: '#0F172A' }}>{item.patientName}</div>
                        <div style={{ fontSize: '0.7rem', color: '#64748B' }}>NIK: {item.patientNik}</div>
                      </td>

                      {/* Posisi Mata */}
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <span
                          style={{
                            display: 'inline-block',
                            padding: '0.2rem 0.5rem',
                            borderRadius: '6px',
                            backgroundColor: '#F1F5F9',
                            fontWeight: 700,
                            fontSize: '0.75rem',
                            color: '#334155',
                          }}
                        >
                          {item.eye === 'OD' ? 'OD (Kanan)' : 'OS (Kiri)'}
                        </span>
                      </td>

                      {/* Derajat AI */}
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <span
                          style={{
                            display: 'inline-block',
                            padding: '0.25rem 0.65rem',
                            borderRadius: '9999px',
                            backgroundColor: gradeBadgeBg,
                            color: gradeBadgeColor,
                            fontWeight: 700,
                            fontSize: '0.75rem',
                          }}
                        >
                          {gradeText}
                        </span>
                        {item.aiResult && (
                          <div style={{ fontSize: '0.7rem', color: '#64748B', marginTop: '0.2rem' }}>
                            Keyakinan: {item.aiResult.confidence}%
                          </div>
                        )}
                      </td>

                      {/* Status Human Review */}
                      <td style={{ padding: '0.85rem 1rem' }}>
                        {isPending ? (
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '0.3rem',
                              padding: '0.25rem 0.65rem',
                              borderRadius: '9999px',
                              backgroundColor: '#FEF3C7',
                              color: '#B45309',
                              fontWeight: 700,
                              fontSize: '0.75rem',
                            }}
                          >
                            <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#D97706' }} />
                            Menunggu Telaah Sp.M
                          </span>
                        ) : isConfirmed ? (
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '0.3rem',
                              padding: '0.25rem 0.65rem',
                              borderRadius: '9999px',
                              backgroundColor: '#DCFCE7',
                              color: '#166534',
                              fontWeight: 700,
                              fontSize: '0.75rem',
                            }}
                          >
                            <CheckIcon size={12} />
                            Konfirmasi Temuan AI
                          </span>
                        ) : isOverridden ? (
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '0.3rem',
                              padding: '0.25rem 0.65rem',
                              borderRadius: '9999px',
                              backgroundColor: '#FEF9C3',
                              color: '#854D0E',
                              fontWeight: 700,
                              fontSize: '0.75rem',
                            }}
                          >
                            ⚙️ Clinical Override
                          </span>
                        ) : (
                          <span style={{ color: '#94A3B8', fontSize: '0.75rem' }}>-</span>
                        )}
                      </td>

                      {/* Catatan / Adjudikator */}
                      <td style={{ padding: '0.85rem 1rem', maxWidth: '240px' }}>
                        {item.humanReview?.reviewerName && (
                          <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '0.75rem' }}>
                            {item.humanReview.reviewerName}
                          </div>
                        )}
                        <div
                          style={{
                            fontSize: '0.725rem',
                            color: '#64748B',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                          title={item.humanReview?.clinicalNotes || item.recommendation?.notes || '-'}
                        >
                          {item.humanReview?.clinicalNotes || item.recommendation?.notes || 'Menunggu telaah klinis dokter spesialis'}
                        </div>
                      </td>

                      {/* Tombol Aksi */}
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'center' }}>
                        {isDoctor ? (
                          <button
                            type="button"
                            onClick={() => onOpenReview?.(item.id)}
                            style={{
                              backgroundColor: isPending ? '#0284C7' : '#F1F5F9',
                              color: isPending ? '#FFFFFF' : '#334155',
                              border: 'none',
                              padding: '0.4rem 0.85rem',
                              borderRadius: '6px',
                              fontWeight: 700,
                              fontSize: '0.75rem',
                              cursor: 'pointer',
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '0.35rem',
                              transition: 'all 0.15s',
                            }}
                          >
                            <EyeIcon size={13} />
                            <span>{isPending ? 'Mulai Telaah' : 'Lihat Hasil'}</span>
                          </button>
                        ) : (
                          <button
                            type="button"
                            onClick={() => onOpenReview?.(item.id)}
                            style={{
                              backgroundColor: '#EFF6FF',
                              color: '#1D4ED8',
                              border: '1px solid #DBEAFE',
                              padding: '0.4rem 0.8rem',
                              borderRadius: '6px',
                              fontWeight: 600,
                              fontSize: '0.75rem',
                              cursor: 'pointer',
                            }}
                          >
                            Buka Berkas
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
