import React, { useState, useEffect } from 'react';
import { EyeIcon, RefreshCwIcon, ClockIcon, HospitalIcon, ArrowRightIcon, ShieldCheckIcon, AlertTriangleIcon, CheckIcon } from './Icons';
import { clinicalStore, ScreeningData } from '../lib/clinical-store';

interface DashboardViewProps {
  onStartScreening: () => void;
  onOpenReview: (screeningId: string) => void;
}

export function DashboardView({ onStartScreening, onOpenReview }: DashboardViewProps) {
  const [metrics, setMetrics] = useState({
    totalScreenedToday: 0,
    totalRetakeRequired: 0,
    pendingHumanReviews: 0,
    activeReferrals: 0,
  });
  const [screenings, setScreenings] = useState<ScreeningData[]>([]);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const syncData = () => {
    setMetrics(clinicalStore.getMetrics());
    setScreenings(clinicalStore.getScreenings());
  };

  useEffect(() => {
    syncData();
    // Reactive live subscription to all updates across views
    const unsubscribe = clinicalStore.subscribe(() => {
      syncData();
    });
    return () => unsubscribe();
  }, []);

  const handleDeleteScreening = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (confirm(`Hapus catatan skrining ${id}?`)) {
      clinicalStore.deleteScreening(id);
    }
  };

  const filteredScreenings = screenings.filter((s) => {
    const matchesSearch =
      searchQuery.trim() === '' ||
      s.patientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.patientNik.includes(searchQuery) ||
      s.id.toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchesSearch) return false;

    if (filterStatus === 'NEEDS_REVIEW') {
      return s.reliability === 'NEEDS_REVIEW';
    }
    if (filterStatus === 'RETAKE') {
      return s.reliability === 'RETAKE_REQUIRED' || !s.qualityCheck.passed;
    }
    if (filterStatus === 'HIGH') {
      return s.reliability === 'HIGH';
    }
    return true;
  });

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Ringkasan Alur Kerja Skrining</h1>
          <p className="section-desc">
            Pemantauan antrean skrining retina harian FKTP, evaluasi kendali mutu citra, dan penelaahan klinis rujukan.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            type="button"
            className="btn btn-outline"
            onClick={() => clinicalStore.resetToDefaults()}
            title="Reset data ke set klinis awal"
          >
            <RefreshCwIcon size={14} />
            <span>Reset Demo Data</span>
          </button>
          <button type="button" className="btn btn-primary" onClick={onStartScreening}>
            <EyeIcon size={16} />
            <span>Mulai Skrining Pasien Baru</span>
          </button>
        </div>
      </div>

      {/* Dynamic KPI Cards per Section 5.1 */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-label">Skrining Selesai Hari Ini</span>
            <div className="metric-icon-box">
              <EyeIcon size={16} />
            </div>
          </div>
          <div className="metric-value">{metrics.totalScreenedToday}</div>
          <div className="metric-sub">Pemeriksaan retina terdata di FKTP</div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-label">Perlu Pengambilan Ulang</span>
            <div className="metric-icon-box" style={{ color: 'var(--status-retake-text)', backgroundColor: 'var(--status-retake-bg)' }}>
              <RefreshCwIcon size={16} />
            </div>
          </div>
          <div className="metric-value">{metrics.totalRetakeRequired}</div>
          <div className="metric-sub">Kualitas citra tidak lolos Quality Gate</div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-label">Antrean Review Spesialis Mata</span>
            <div className="metric-icon-box" style={{ color: 'var(--status-review-text)', backgroundColor: 'var(--status-review-bg)' }}>
              <ClockIcon size={16} />
            </div>
          </div>
          <div className="metric-value">{metrics.pendingHumanReviews}</div>
          <div className="metric-sub">Menunggu telaah klinis & ajudikasi</div>
        </div>

        <div className="metric-card">
          <div className="metric-header">
            <span className="metric-label">Rujukan FKRTL / Follow-up</span>
            <div className="metric-icon-box" style={{ color: 'var(--status-info-text)', backgroundColor: 'var(--status-info-bg)' }}>
              <HospitalIcon size={16} />
            </div>
          </div>
          <div className="metric-value">{metrics.activeReferrals}</div>
          <div className="metric-sub">Pasien dijadwalkan ke RS Rujukan</div>
        </div>
      </div>

      {/* Dynamic Review Queue Card */}
      <div className="card" style={{ marginBottom: '1.75rem' }}>
        <div className="card-header">
          <div>
            <div className="card-title">Antrean Skrining Retina Aktif</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
              Daftar citra fundus yang memerlukan perhatian teknis atau telaah spesialis mata (Data Live).
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <span className="badge badge-neutral">{filteredScreenings.length} dari {screenings.length} Kasus</span>
          </div>
        </div>

        {/* Dynamic Interactive Filter & Search Bar */}
        <div style={{ padding: '0.875rem 1.25rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem', backgroundColor: 'var(--slate-50)' }}>
          <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
            <button
              type="button"
              className={`btn btn-sm ${filterStatus === 'ALL' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setFilterStatus('ALL')}
            >
              Semua ({screenings.length})
            </button>
            <button
              type="button"
              className={`btn btn-sm ${filterStatus === 'NEEDS_REVIEW' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setFilterStatus('NEEDS_REVIEW')}
            >
              Perlu Review Spesialis ({screenings.filter((s) => s.reliability === 'NEEDS_REVIEW').length})
            </button>
            <button
              type="button"
              className={`btn btn-sm ${filterStatus === 'RETAKE' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setFilterStatus('RETAKE')}
            >
              Perlu Retake ({screenings.filter((s) => !s.qualityCheck.passed).length})
            </button>
            <button
              type="button"
              className={`btn btn-sm ${filterStatus === 'HIGH' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setFilterStatus('HIGH')}
            >
              Keandalan Tinggi ({screenings.filter((s) => s.reliability === 'HIGH').length})
            </button>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <input
              type="text"
              className="form-control"
              style={{ width: '220px', padding: '0.35rem 0.65rem', fontSize: '0.75rem' }}
              placeholder="Cari pasien / NIK / ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>No. Skrining & Pasien</th>
                <th>Mata & Waktu</th>
                <th>Kendali Mutu (Quality Gate)</th>
                <th>Temuan Skrining AI</th>
                <th>Keandalan (Reliability Gate)</th>
                <th style={{ textAlign: 'right' }}>Tindakan</th>
              </tr>
            </thead>
            <tbody>
              {filteredScreenings.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '2rem', color: 'var(--slate-500)' }}>
                    Tidak ada antrean skrining yang cocok dengan filter atau kata kunci.
                  </td>
                </tr>
              ) : (
                filteredScreenings.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ fontWeight: 600, color: 'var(--slate-900)' }}>{item.patientName}</div>
                      <div className="code-inline" style={{ fontSize: '0.7rem' }}>NIK: {item.patientNik}</div>
                      <div style={{ fontSize: '0.675rem', color: 'var(--slate-400)', marginTop: '0.1rem' }}>{item.id}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 500 }}>{item.eye === 'OD' ? 'OD (Mata Kanan)' : 'OS (Mata Kiri)'}</div>
                      <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>
                        {new Date(item.capturedAt).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })} WIB
                      </div>
                    </td>
                    <td>
                      {item.qualityCheck.passed ? (
                        <span className="badge badge-pass">
                          <CheckIcon size={12} />
                          <span>Citra Layak</span>
                        </span>
                      ) : (
                        <span className="badge badge-retake">
                          <AlertTriangleIcon size={12} />
                          <span>Perlu Retake</span>
                        </span>
                      )}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600, color: item.aiResult?.drGrade === 'NO_DR' ? 'var(--slate-700)' : 'var(--slate-900)' }}>
                        {item.aiResult ? item.aiResult.drLabel : item.qualityCheck.reason || 'Belum Dievaluasi'}
                      </div>
                      {item.aiResult && (
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>
                          Probabilitas model: {item.aiResult.confidence}%
                        </div>
                      )}
                    </td>
                    <td>
                      {item.reliability === 'HIGH' && (
                        <span className="badge badge-pass">
                          <ShieldCheckIcon size={12} />
                          <span>Keandalan Tinggi</span>
                        </span>
                      )}
                      {item.reliability === 'NEEDS_REVIEW' && (
                        <span className="badge badge-review">
                          <ClockIcon size={12} />
                          <span>{item.humanReview?.status === 'CONFIRMED_AI' ? 'Sudah Ditelaah' : 'Perlu Review Spesialis'}</span>
                        </span>
                      )}
                      {item.reliability === 'RETAKE_REQUIRED' && (
                        <span className="badge badge-retake">
                          <RefreshCwIcon size={12} />
                          <span>Foto Ulang Diperlukan</span>
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '0.35rem', justifyContent: 'flex-end' }}>
                        <button
                          type="button"
                          className="btn btn-outline btn-sm"
                          onClick={() => onOpenReview(item.id)}
                        >
                          <span>Periksa</span>
                          <ArrowRightIcon size={12} />
                        </button>
                        <button
                          type="button"
                          className="btn btn-sm"
                          style={{ color: 'var(--status-retake-text)', borderColor: 'var(--border-subtle)', background: 'transparent' }}
                          onClick={(e) => handleDeleteScreening(item.id, e)}
                          title="Hapus berkas skrining"
                        >
                          Hapus
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Clinical Guidance Info Box */}
      <div className="card" style={{ backgroundColor: 'var(--slate-50)', borderStyle: 'dashed' }}>
        <div className="card-body" style={{ display: 'flex', gap: '1.25rem', alignItems: 'flex-start' }}>
          <div style={{ padding: '0.75rem', backgroundColor: 'var(--brand-100)', borderRadius: 'var(--radius-sm)', color: 'var(--brand-800)' }}>
            <ShieldCheckIcon size={24} />
          </div>
          <div>
            <h2 style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--slate-900)', marginBottom: '0.25rem' }}>
              Protokol Skrining Perdami & Konsensus ADA 2024
            </h2>
            <p style={{ fontSize: '0.8125rem', color: 'var(--slate-600)', lineHeight: 1.6 }}>
              Semua pasien diabetes melitus tipe 2 wajib menjalani skrining funduskopi tahunan sejak terdiagnosis. Pasien diabetes melitus tipe 1 memulai skrining 5 tahun pasca-diagnosis. Kasus dengan temuan <strong>Moderate NPDR ke atas</strong> atau <strong>penurunan ketajaman visual</strong> harus dirujuk ke Fasilitas Kesehatan Rujukan Tingkat Lanjutan (FKRTL) dalam waktu maksimal 30 hari kalender.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
