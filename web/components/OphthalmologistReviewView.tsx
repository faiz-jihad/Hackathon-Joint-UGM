import React, { useState, useEffect } from 'react';
import {
  EyeIcon,
  CheckIcon,
  XIcon,
  AlertTriangleIcon,
  InfoIcon,
  ShieldCheckIcon,
  ClockIcon,
  FileTextIcon,
  SlidersIcon,
  UserIcon,
} from './Icons';
import { clinicalStore, ScreeningData } from '../lib/clinical-store';

interface OphthalmologistReviewViewProps {
  screeningId?: string;
  onAdjudicationSaved: () => void;
}

export function OphthalmologistReviewView({ screeningId = 'SCR-2026-0891', onAdjudicationSaved }: OphthalmologistReviewViewProps) {
  const [allScreenings, setAllScreenings] = useState<ScreeningData[]>([]);
  const [currentId, setCurrentId] = useState<string>(screeningId);
  const [screening, setScreening] = useState<ScreeningData | null>(null);
  const [viewMode, setViewMode] = useState<'fundus' | 'gradcam'>('fundus');
  const [adjudicationAction, setAdjudicationAction] = useState<'CONFIRM_AI' | 'OVERRIDE' | 'REQUEST_RETAKE'>('CONFIRM_AI');
  const [overrideGrade, setOverrideGrade] = useState<string>('MODERATE_NPDR');
  const [clinicalNotes, setClinicalNotes] = useState<string>(
    'Tampak mikroaneurisma fokal pada kuadran temporal superior dan beberapa bercak perdarahan retina superfisial (dot-blot hemorrhages). Belum tampak neovaskularisasi diskus (NVD/NVE). Sesuai dengan NPDR derajat sedang. Rujuk ke poli mata untuk pemeriksaan OCT makula.'
  );
  const [savedSuccess, setSavedSuccess] = useState<boolean>(false);

  const syncScreening = (targetId: string) => {
    const list = clinicalStore.getScreenings();
    setAllScreenings(list);
    const item = list.find((s) => s.id === targetId) || list[0];
    if (item) {
      setCurrentId(item.id);
      setScreening(item);
      if (item.humanReview?.clinicalNotes) {
        setClinicalNotes(item.humanReview.clinicalNotes);
      } else {
        setClinicalNotes(
          item.aiResult?.drGrade === 'NO_DR'
            ? 'Fundus tenang, tidak tampak mikroaneurisma ataupun lesi vaskular. Skrining tahunan berkala.'
            : item.aiResult?.drGrade === 'MILD_NPDR'
            ? 'Mikroaneurisma minimal tanpa edema makula. Optimasi kontrol glikemik dan evaluasi 6 bulan.'
            : item.aiResult?.drGrade === 'MODERATE_NPDR'
            ? 'Tampak mikroaneurisma fokal pada kuadran temporal superior dan beberapa bercak perdarahan retina. Rujuk ke spesialis mata.'
            : 'Perdarahan intraretina luas multipel kuadran sesuai aturan 4-2-1. Rujukan cito vitreoretina.'
        );
      }
      if (item.humanReview?.overrideGrade) {
        setOverrideGrade(item.humanReview.overrideGrade);
      } else if (item.aiResult?.drGrade) {
        setOverrideGrade(item.aiResult.drGrade);
      }
    }
  };

  useEffect(() => {
    syncScreening(screeningId);
    const unsubscribe = clinicalStore.subscribe(() => {
      syncScreening(currentId);
    });
    return () => unsubscribe();
  }, [screeningId]);

  const handleSelectScreening = (newId: string) => {
    syncScreening(newId);
  };

  const handleSave = () => {
    if (!screening) return;

    clinicalStore.adjudicateScreening(
      screening.id,
      adjudicationAction,
      clinicalNotes,
      adjudicationAction === 'OVERRIDE' ? overrideGrade : undefined
    );

    setSavedSuccess(true);
    setTimeout(() => {
      onAdjudicationSaved();
    }, 1200);
  };

  if (!screening) {
    return (
      <div className="card" style={{ padding: '2rem', textAlign: 'center' }}>
        <p>Memuat berkas skrining...</p>
      </div>
    );
  }

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Portal Telaah Klinis Dokter Spesialis Mata</h1>
          <p className="section-desc">
            Ajudikasi citra fundus retina, inspeksi aktivasi model Grad-CAM, dan penetapan tatalaksana rujukan formal.
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
            <label htmlFor="screening-picker" style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--slate-600)' }}>Pilih Berkas:</label>
            <select
              id="screening-picker"
              className="form-control"
              style={{ fontSize: '0.75rem', padding: '0.25rem 0.5rem', width: 'auto' }}
              value={currentId}
              onChange={(e) => handleSelectScreening(e.target.value)}
            >
              {allScreenings.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.id} — {s.patientName} ({s.eye}) [{s.humanReview?.status === 'CONFIRMED_AI' ? 'Sudah Ditelaah' : 'Menunggu'}]
                </option>
              ))}
            </select>
          </div>
          <span className={`badge ${screening.humanReview?.status === 'CONFIRMED_AI' ? 'badge-pass' : 'badge-review'}`}>
            Status: {screening.humanReview?.status === 'CONFIRMED_AI' ? 'Sudah Ditelaah' : 'Menunggu Telaah'}
          </span>
        </div>
      </div>

      {/* Dynamic Patient Header Card */}
      <div className="card" style={{ marginBottom: '1.25rem' }}>
        <div className="card-body" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '50%', backgroundColor: 'var(--slate-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--slate-700)' }}>
              <UserIcon size={20} />
            </div>
            <div>
              <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--slate-900)' }}>{screening.patientName}</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>
                NIK: {screening.patientNik} • Mata: {screening.eye === 'OD' ? 'Oculus Dexter (OD)' : 'Oculus Sinister (OS)'} • Waktu: {new Date(screening.capturedAt).toLocaleString('id-ID')}
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <span className="badge badge-neutral">Mata: {screening.eye}</span>
            <span className="badge badge-pass">
              Mutu: {screening.qualityCheck.passed ? 'Citra Layak' : 'Perlu Retake'}
            </span>
            <span className="badge badge-review">Keandalan: {screening.reliabilityLabel}</span>
          </div>
        </div>
      </div>

      {/* Desktop Split Review per Section 13 */}
      <div className="grid-2">
        {/* Left Column: Fundus & Grad-CAM Image */}
        <div className="card">
          <div className="card-header">
            <div className="card-title">Inspeksi Citra Retina Digital</div>
            <div style={{ display: 'flex', gap: '0.35rem' }}>
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'fundus' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => setViewMode('fundus')}
              >
                <EyeIcon size={14} />
                <span>Citra Fundus Asli</span>
              </button>
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'gradcam' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => setViewMode('gradcam')}
              >
                <SlidersIcon size={14} />
                <span>Peta Grad-CAM AI</span>
              </button>
            </div>
          </div>
          <div className="card-body">
            <div className="fundus-frame">
              <div className="fundus-tag">
                {viewMode === 'fundus' ? `Citra Optik Fundus ${screening.eye} (Field View 45°)` : 'Peta Aktivasi Grad-CAM (Layer Conv_Head)'}
              </div>

              {viewMode === 'fundus' ? (
                screening.aiResult?.overlayUrl ? (
                  <div style={{ textAlign: 'center', padding: '1rem', color: 'var(--slate-300)' }}>
                    <img
                      src={screening.aiResult.overlayUrl}
                      alt="Citra Funduskopi Digital"
                      style={{ maxHeight: '220px', maxWidth: '100%', borderRadius: '50%', objectFit: 'cover', margin: '0 auto 0.5rem auto' }}
                    />
                    <div style={{ fontSize: '0.8125rem', color: '#ffffff', fontWeight: 600 }}>Citra Funduskopi Digital {screening.eye}</div>
                    <div style={{ fontSize: '0.725rem', color: 'var(--slate-400)', marginTop: '0.2rem' }}>
                      SHA-256 Integritas: <span className="code-inline" style={{ color: '#ffffff', backgroundColor: 'transparent' }}>{screening.imageHash.substring(0, 16)}...</span>
                    </div>
                  </div>
                ) : (
                  <div style={{ textAlign: 'center', padding: '3rem 1.5rem', color: 'var(--slate-300)' }}>
                    <div style={{ width: '160px', height: '160px', borderRadius: '50%', background: 'radial-gradient(circle at 35% 40%, #c2410c 0%, #7c2d12 40%, #451a03 70%, #000000 100%)', margin: '0 auto 1.5rem auto', position: 'relative', boxShadow: 'inset 0 0 30px rgba(0,0,0,0.8)' }}>
                      <div style={{ position: 'absolute', top: '45%', left: '22%', width: '28px', height: '34px', borderRadius: '50%', backgroundColor: '#fed7aa', opacity: 0.85, filter: 'blur(1px)' }} />
                      <div style={{ position: 'absolute', top: '50%', right: '35%', width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#431407', opacity: 0.9 }} />
                      <div style={{ position: 'absolute', top: '35%', right: '30%', width: '4px', height: '4px', borderRadius: '50%', backgroundColor: '#ef4444' }} />
                      <div style={{ position: 'absolute', top: '40%', right: '28%', width: '5px', height: '5px', borderRadius: '50%', backgroundColor: '#dc2626' }} />
                      <div style={{ position: 'absolute', top: '60%', right: '32%', width: '4px', height: '4px', borderRadius: '50%', backgroundColor: '#b91c1c' }} />
                    </div>
                    <div style={{ fontSize: '0.8125rem', color: '#ffffff', fontWeight: 600 }}>Citra Funduskopi Digital {screening.eye}</div>
                    <div style={{ fontSize: '0.725rem', color: 'var(--slate-400)', marginTop: '0.2rem' }}>
                      SHA-256 Integritas: <span className="code-inline" style={{ color: '#ffffff', backgroundColor: 'transparent' }}>{screening.imageHash.substring(0, 16)}...</span>
                    </div>
                  </div>
                )
              ) : (
                screening.aiResult?.heatmapUrl ? (
                  <div style={{ textAlign: 'center', padding: '1rem', color: 'var(--slate-300)' }}>
                    <img
                      src={screening.aiResult.heatmapUrl}
                      alt="Peta Grad-CAM"
                      style={{ maxHeight: '220px', maxWidth: '100%', borderRadius: '50%', objectFit: 'cover', margin: '0 auto 0.5rem auto' }}
                    />
                    <div style={{ fontSize: '0.8125rem', color: '#ffffff', fontWeight: 600 }}>Peta Aktivasi Grad-CAM (Heatmap)</div>
                    <div style={{ fontSize: '0.725rem', color: 'var(--slate-400)', marginTop: '0.2rem' }}>
                      Fokus Aktivasi Model: {screening.aiResult?.gradCamFocus || 'Area Lesi Retina'}
                    </div>
                  </div>
                ) : (
                  <div style={{ textAlign: 'center', padding: '3rem 1.5rem', color: 'var(--slate-300)' }}>
                    <div style={{ width: '160px', height: '160px', borderRadius: '50%', background: 'radial-gradient(circle at 65% 45%, #ef4444 0%, #f59e0b 35%, #10b981 60%, #1e3a8a 85%)', margin: '0 auto 1.5rem auto', opacity: 0.85, filter: 'blur(2px)' }} />
                    <div style={{ fontSize: '0.8125rem', color: '#ffffff', fontWeight: 600 }}>Peta Aktivasi Grad-CAM (Heatmap)</div>
                    <div style={{ fontSize: '0.725rem', color: 'var(--slate-400)', marginTop: '0.2rem' }}>
                      Fokus Aktivasi Model: {screening.aiResult?.gradCamFocus || 'Area Lesi Retina'}
                    </div>
                  </div>
                )
              )}
            </div>

            <div style={{ marginTop: '0.875rem', padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
              <InfoIcon size={15} style={{ color: 'var(--brand-700)', flexShrink: 0 }} />
              <span style={{ fontSize: '0.725rem', color: 'var(--slate-600)', lineHeight: 1.4 }}>
                <strong>Pemberitahuan Klinis:</strong> Visualisasi Grad-CAM merepresentasikan gradien atensi arsitektur konvolusi EfficientNet-B3 untuk membantu pelacakan area lesi, <u>bukan bukti patologis mutlak</u>.
              </span>
            </div>
          </div>
        </div>

        {/* Right Column: AI Suggestion & Ophthalmologist Adjudication Form */}
        <div className="card">
          <div className="card-header">
            <div className="card-title">Formulir Ajudikasi Spesialis Mata</div>
            <span className="badge badge-review">Human-in-the-Loop</span>
          </div>
          <div className="card-body">
            {savedSuccess ? (
              <div style={{ padding: '2rem', textAlign: 'center', backgroundColor: 'var(--status-pass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--status-pass-border)' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: 'var(--brand-600)', color: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 0.75rem auto' }}>
                  <CheckIcon size={20} />
                </div>
                <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>
                  Ajudikasi Berhasil Disimpan
                </div>
                <div style={{ fontSize: '0.8125rem', color: 'var(--slate-600)', marginTop: '0.25rem' }}>
                  Hasil telaah klinis telah diperbarui di database dan tercatat dalam Log Audit resmi.
                </div>
              </div>
            ) : (
              <div>
                {/* Dynamic AI Screening Findings Summary */}
                <div style={{ padding: '0.875rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', marginBottom: '1.25rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                    <span style={{ fontSize: '0.725rem', fontWeight: 600, color: 'var(--slate-500)', textTransform: 'uppercase' }}>
                      Temuan Model AI:
                    </span>
                    <span className="code-inline" style={{ fontSize: '0.7rem' }}>EfficientNet-B3 (v1.0.0)</span>
                  </div>
                  <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--slate-900)' }}>
                    {screening.aiResult?.drLabel || 'Pemeriksaan Mutu Citra'}
                  </div>
                  {screening.aiResult && (
                    <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)', marginTop: '0.2rem' }}>
                      Tingkat Keyakinan: {screening.aiResult.confidence}% • Keandalan: {screening.reliabilityLabel}
                    </div>
                  )}
                </div>

                {/* Adjudication Decision Radio */}
                <div className="form-group">
                  <label className="form-label">Keputusan Ajudikasi Spesialis Mata:</label>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.625rem', padding: '0.625rem', border: '1px solid var(--slate-200)', borderRadius: 'var(--radius-sm)', cursor: 'pointer', backgroundColor: adjudicationAction === 'CONFIRM_AI' ? 'var(--brand-50)' : '#ffffff' }}>
                      <input
                        type="radio"
                        name="adjudication"
                        checked={adjudicationAction === 'CONFIRM_AI'}
                        onChange={() => setAdjudicationAction('CONFIRM_AI')}
                      />
                      <div>
                        <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-900)' }}>
                          Konfirmasi Temuan AI ({screening.aiResult?.drGrade || 'Valid'})
                        </div>
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>
                          Menyetujui klasifikasi model dan menerbitkan rekomendasi rujukan.
                        </div>
                      </div>
                    </label>

                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.625rem', padding: '0.625rem', border: '1px solid var(--slate-200)', borderRadius: 'var(--radius-sm)', cursor: 'pointer', backgroundColor: adjudicationAction === 'OVERRIDE' ? 'var(--brand-50)' : '#ffffff' }}>
                      <input
                        type="radio"
                        name="adjudication"
                        checked={adjudicationAction === 'OVERRIDE'}
                        onChange={() => setAdjudicationAction('OVERRIDE')}
                      />
                      <div>
                        <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-900)' }}>
                          Koreksi Derajat DR Manual (Clinical Override)
                        </div>
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>
                          Mengubah klasifikasi retinopati berdasarkan inspeksi lesi klinis dokter.
                        </div>
                      </div>
                    </label>

                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.625rem', padding: '0.625rem', border: '1px solid var(--slate-200)', borderRadius: 'var(--radius-sm)', cursor: 'pointer', backgroundColor: adjudicationAction === 'REQUEST_RETAKE' ? 'var(--brand-50)' : '#ffffff' }}>
                      <input
                        type="radio"
                        name="adjudication"
                        checked={adjudicationAction === 'REQUEST_RETAKE'}
                        onChange={() => setAdjudicationAction('REQUEST_RETAKE')}
                      />
                      <div>
                        <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-900)' }}>
                          Minta Pengambilan Ulang Citra (Retake Required)
                        </div>
                        <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)' }}>
                          Kualitas citra visual tidak memadai untuk interpretasi definitif lesi retina.
                        </div>
                      </div>
                    </label>
                  </div>
                </div>

                {adjudicationAction === 'OVERRIDE' && (
                  <div className="form-group" style={{ backgroundColor: 'var(--slate-50)', padding: '0.75rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                    <label className="form-label" htmlFor="override-grade-select">Koreksi Derajat ICDR:</label>
                    <select
                      id="override-grade-select"
                      className="form-control"
                      value={overrideGrade}
                      onChange={(e) => setOverrideGrade(e.target.value)}
                    >
                      <option value="NO_DR">Tidak Tampak Retinopati Diabetik (No DR)</option>
                      <option value="MILD_NPDR">Retinopati Diabetik Non-Proliferatif Ringan (Mild NPDR)</option>
                      <option value="MODERATE_NPDR">Retinopati Diabetik Non-Proliferatif Sedang (Moderate NPDR)</option>
                      <option value="SEVERE_NPDR">Retinopati Diabetik Non-Proliferatif Berat (Severe NPDR)</option>
                      <option value="PDR">Retinopati Diabetik Proliferatif (PDR)</option>
                    </select>
                  </div>
                )}

                {/* Doctor Clinical Notes */}
                <div className="form-group">
                  <label className="form-label" htmlFor="clinical-notes-textarea">
                    Catatan Klinis Dokter Penelaah (Wajib Terdata di Audit Trail):
                  </label>
                  <textarea
                    id="clinical-notes-textarea"
                    className="form-control"
                    rows={4}
                    value={clinicalNotes}
                    onChange={(e) => setClinicalNotes(e.target.value)}
                  />
                  <div className="form-hint">
                    Tercatat bersama Surat Izin Praktik (SIP) dokter dan tanda tangan kriptografis sistem.
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1.25rem' }}>
                  <button
                    type="button"
                    className="btn btn-primary"
                    style={{ flex: 1 }}
                    onClick={handleSave}
                  >
                    <ShieldCheckIcon size={16} />
                    <span>Simpan & Tandatangani Ajudikasi Klinis</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
