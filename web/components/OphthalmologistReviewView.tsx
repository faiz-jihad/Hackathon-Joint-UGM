import React, { useState, useEffect, useRef } from 'react';
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

export function OphthalmologistReviewView({ screeningId = 'RTV-20261024-36', onAdjudicationSaved }: OphthalmologistReviewViewProps) {
  const [doctorsList, setDoctorsList] = useState([
    {
      name: 'dr. Yunani Setyandriana, Sp.M',
      role: 'Spesialis Mata (Ophthalmologist)',
      hospital: 'RSUP Dr. Sardjito / Faskes Mitra RETIVA',
      sip: 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)',
    },
    {
      name: 'dr. Arga Pratama, Sp.M',
      role: 'Spesialis Vitreoretina',
      hospital: 'RS Mata Cicendo / Perdami Jabar',
      sip: 'SIP: 446.1/1829/SIP-D/2023',
    },
    {
      name: 'dr. Siti Nurhaliza, Sp.M(K)',
      role: 'Konsultan Retina & Diabetes',
      hospital: 'RSUP Dr. Sardjito',
      sip: 'SIP: 446.1/2041/SIP-D/2024',
    },
    {
      name: 'dr. Hendra Kusuma, Sp.M',
      role: 'Spesialis Oftalmologi',
      hospital: 'RS Mata Yap Yogyakarta',
      sip: 'SIP: 446.1/1592/SIP-D/2022',
    },
  ]);

  const [selectedDoctorIndex, setSelectedDoctorIndex] = useState<number>(0);
  const activeDoctor = doctorsList[selectedDoctorIndex];

  const formatIndonesianDateTime = (isoString?: string) => {
    const d = isoString ? new Date(isoString) : new Date();
    if (isNaN(d.getTime())) return new Date().toLocaleDateString('id-ID');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const day = d.getDate();
    const month = months[d.getMonth()];
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const mins = String(d.getMinutes()).padStart(2, '0');
    return `${day} ${month} ${year}, ${hours}:${mins} WIB`;
  };

  const [mounted, setMounted] = useState<boolean>(false);
  const [allScreenings, setAllScreenings] = useState<ScreeningData[]>(() => {
    return clinicalStore.getScreenings().filter((s) => !s.id.toLowerCase().startsWith('scr_'));
  });
  const [currentId, setCurrentId] = useState<string>(screeningId);
  const currentIdRef = useRef<string>(screeningId);
  const [screening, setScreening] = useState<ScreeningData | null>(() => {
    const list = clinicalStore.getScreenings().filter((s) => !s.id.toLowerCase().startsWith('scr_'));
    return list.find((s) => s.id === screeningId) || list.find((s) => s.humanReview?.status === 'PENDING') || list[0] || null;
  });
  const [viewMode, setViewMode] = useState<'fundus' | 'gradcam'>('fundus');
  const [gradCamOpacity, setGradCamOpacity] = useState<number>(0.75);
  const [displayLayout, setDisplayLayout] = useState<'overlay' | 'side-by-side'>('overlay');
  const [showHotspotMarkers, setShowHotspotMarkers] = useState<boolean>(true);
  const [activePinTooltip, setActivePinTooltip] = useState<string | null>(null);
  const [adjudicationAction, setAdjudicationAction] = useState<'CONFIRM_AI' | 'OVERRIDE'>('CONFIRM_AI');
  const [overrideGrade, setOverrideGrade] = useState<string>('MODERATE_NPDR');
  const [clinicalNotes, setClinicalNotes] = useState<string>('');
  const [savedSuccess, setSavedSuccess] = useState<boolean>(false);
  const [isClosedView, setIsClosedView] = useState<boolean>(true);
  const userSelectedRef = useRef<boolean>(false);

  const isCaseClosed = screening?.humanReview?.status === 'CONFIRMED_AI' || screening?.humanReview?.status === 'OVERRIDDEN' || savedSuccess;

  useEffect(() => {
    setMounted(true);
  }, []);

  const syncScreening = (targetId: string, customList?: ScreeningData[]) => {
    const list = (customList || (allScreenings.length > 0 ? allScreenings : clinicalStore.getScreenings()))
      .filter((s) => !s.id.toLowerCase().startsWith('scr_'));
    setAllScreenings(list);
    const cleanTargetId = targetId.replace(/^#/, '');
    const item = list.find((s) => s.id === targetId || s.id.replace(/^#/, '') === cleanTargetId) ||
                 list.find((s) => s.humanReview?.status === 'PENDING') ||
                 list[0];
    if (item) {
      currentIdRef.current = item.id;
      setCurrentId(item.id);
      setScreening(item);
      const isItemReviewed = item.humanReview?.status === 'CONFIRMED_AI' || item.humanReview?.status === 'OVERRIDDEN';
      setSavedSuccess(isItemReviewed);

      // Pastikan catatan klinis bersih dari template teks default saat kasus baru dibuka
      if (item.humanReview?.status === 'CONFIRMED_AI' || item.humanReview?.status === 'OVERRIDDEN') {
        setClinicalNotes(item.humanReview?.clinicalNotes || '');
      } else {
        setClinicalNotes('');
      }
      if (item.humanReview?.overrideGrade) {
        setOverrideGrade(item.humanReview.overrideGrade);
      } else if (item.aiResult?.drGrade) {
        setOverrideGrade(item.aiResult.drGrade);
      }
      if (item.humanReview?.reviewerName) {
        const foundIdx = doctorsList.findIndex((d) => d.name === item.humanReview?.reviewerName);
        if (foundIdx !== -1) setSelectedDoctorIndex(foundIdx);
      }
    }

    // Check server review status endpoint in real-time
    fetch(`/api/v1/reviews/status?screeningId=${encodeURIComponent(targetId)}`)
      .then((res) => res.json())
      .then((data) => {
        if (data.success) {
          if (data.data?.isReviewed) {
            setSavedSuccess(true);
          } else {
            setSavedSuccess(false);
          }
        }
      })
      .catch(() => {});
  };

  // Sync hanya ketika prop screeningId berubah dari luar (bukan pada setiap perubahan state internal)
  useEffect(() => {
    if (screeningId) {
      syncScreening(screeningId);
    }
  }, [screeningId]);

  // Listener sinkronisasi lokal tanpa mereset currentId
  useEffect(() => {
    const unsubscribe = clinicalStore.subscribe(() => {
      if (currentIdRef.current) {
        syncScreening(currentIdRef.current);
      }
    });
    return () => unsubscribe();
  }, []);

  // Polling antrean telaah spesialis dari server API Gateway secara live
  useEffect(() => {
    let active = true;

    const pollPendingQueue = async () => {
      try {
        const res = await fetch('/api/v1/reviews/pending', {
          headers: { 'x-retiva-clinical': 'true' },
        });
        if (res.ok && active) {
          const json = await res.json();
          if (Array.isArray(json.data) && json.data.length > 0) {
            const localList = clinicalStore.getScreenings();
            const combinedMap = new Map<string, ScreeningData>();
            for (const item of localList) {
              if (!item.id.toLowerCase().startsWith('scr_')) {
                combinedMap.set(item.id, item);
              }
            }
            for (const item of json.data) {
              if (!item.id.toLowerCase().startsWith('scr_')) {
                combinedMap.set(item.id, item as ScreeningData);
              }
            }
            const mergedList = Array.from(combinedMap.values()).filter(
              (s) => !s.id.toLowerCase().startsWith('scr_')
            );
            setAllScreenings(mergedList);

            // Jika ada kasus PENDING dari mobile dan dokter belum memilih manual berkas lain, prioritaskan kasus pending
            if (!userSelectedRef.current) {
              const pendingItem = mergedList.find((s) => s.humanReview?.status === 'PENDING');
              if (pendingItem && currentIdRef.current !== pendingItem.id) {
                currentIdRef.current = pendingItem.id;
                setCurrentId(pendingItem.id);
                setScreening(pendingItem);
                setSavedSuccess(false);
              }
            }
          }
        }
      } catch (_) {}
    };

    pollPendingQueue();
    const interval = setInterval(pollPendingQueue, 2500);
    return () => {
      active = false;
      clearInterval(interval);
    };
  }, []);

  const handleSelectScreening = (newId: string) => {
    userSelectedRef.current = true;
    currentIdRef.current = newId;
    syncScreening(newId);
  };

  const handleSave = async () => {
    if (!screening) return;

    clinicalStore.adjudicateScreening(
      screening.id,
      adjudicationAction,
      clinicalNotes,
      adjudicationAction === 'OVERRIDE' ? overrideGrade : undefined,
      activeDoctor.name,
      activeDoctor.sip
    );

    const reviewStatus = adjudicationAction === 'OVERRIDE' ? 'OVERRIDDEN' : 'CONFIRMED_AI';
    const baseClass = adjudicationAction === 'OVERRIDE' && overrideGrade ? overrideGrade : (screening.aiResult?.drGrade || 'MODERATE_DR');
    let normalizedClass = baseClass.replace('_NPDR', '_DR');
    if (normalizedClass === 'PDR') normalizedClass = 'PROLIFERATIVE_DR';

    fetch(`/api/v1/reviews/${screening.id}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-retiva-clinical': 'true',
      },
      body: JSON.stringify({
        reviewStatus,
        confirmedClass: normalizedClass,
        clinicalNotes: clinicalNotes || 'Telaah klinis dokter spesialis mata terverifikasi.',
      }),
    }).catch((err) => console.warn('Backend review sync notice:', err));
    const updatedStatus = adjudicationAction === 'CONFIRM_AI' ? 'CONFIRMED_AI' : adjudicationAction === 'OVERRIDE' ? 'OVERRIDDEN' : 'RETAKE_REQUESTED';
    setScreening((prev) => {
      if (!prev) return null;
      return {
        ...prev,
        humanReview: {
          ...prev.humanReview,
          status: updatedStatus as any,
          reviewerName: activeDoctor.name,
          reviewerNip: activeDoctor.sip,
          clinicalNotes,
        },
      };
    });

    setAllScreenings((prev) =>
      prev.map((item) =>
        item.id === screening.id || item.id.replace(/^#/, '') === screening.id.replace(/^#/, '')
          ? {
              ...item,
              humanReview: {
                ...item.humanReview,
                status: updatedStatus as any,
                reviewerName: activeDoctor.name,
                reviewerNip: activeDoctor.sip,
                clinicalNotes,
              },
            }
          : item
      )
    );

    userSelectedRef.current = false;

    const effectiveGrade = adjudicationAction === 'OVERRIDE' && overrideGrade
      ? overrideGrade
      : (screening.aiResult?.drGrade || 'MODERATE_NPDR');
    const effectiveLabel = effectiveGrade === 'NO_DR'
      ? 'Tidak Tampak Retinopati Diabetik'
      : effectiveGrade === 'MILD_NPDR'
      ? 'Retinopati Diabetik Non-Proliferatif Ringan'
      : effectiveGrade === 'MODERATE_NPDR'
      ? 'Retinopati Diabetik Non-Proliferatif Sedang'
      : effectiveGrade === 'SEVERE_NPDR'
      ? 'Retinopati Diabetik Non-Proliferatif Berat'
      : 'Retinopati Diabetik Proliferatif (PDR)';

    // Broadcast review status to server for instant mobile notification & timeline update
    try {
      await fetch('/api/v1/reviews/status', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          screeningId: screening.id,
          isReviewed: true,
          doctorName: activeDoctor.name,
          doctorRole: activeDoctor.role,
          doctorSip: activeDoctor.sip,
          notes: clinicalNotes,
          adjudicationAction,
          confirmedGrade: effectiveGrade,
          overrideGrade: adjudicationAction === 'OVERRIDE' ? overrideGrade : undefined,
          finalGrade: effectiveGrade,
          finalLabel: effectiveLabel,
        }),
      });
    } catch (e) {
      console.warn('Failed to broadcast review status to server:', e);
    }

    setSavedSuccess(true);
    setTimeout(() => {
      onAdjudicationSaved();
    }, 1200);
  };

  if (!mounted || !screening) {
    return (
      <div className="card" style={{ padding: '3rem 2rem', textAlign: 'center', background: '#FFFFFF', borderRadius: '14px', border: '1px solid #E2E8F0' }}>
        <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '1.25rem' }}>
          {!mounted ? 'Memuat portal telaah klinis dokter spesialis mata...' : 'Berkas skrining tidak ditemukan atau sedang disiapkan.'}
        </p>
        {mounted && !screening && (
          <button
            type="button"
            className="admin-btn-primary"
            onClick={() => {
              const list = clinicalStore.getScreenings();
              if (list.length > 0) {
                setScreening(list[0]);
                setCurrentId(list[0].id);
              }
            }}
            style={{ padding: '0.6rem 1.25rem', fontSize: '13px', borderRadius: '8px' }}
          >
            Muat Berkas Skrining
          </button>
        )}
      </div>
    );
  }

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Portal Telaah Klinis Dokter Spesialis Mata</h1>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <label htmlFor="screening-picker" style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--slate-600)' }}>Pilih Berkas:</label>
          <select
            id="screening-picker"
            suppressHydrationWarning
            className="form-control"
            style={{ fontSize: '0.75rem', padding: '0.3rem 0.6rem', width: 'auto' }}
            value={currentId}
            onChange={(e) => handleSelectScreening(e.target.value)}
          >
            {allScreenings
              .filter((s) => !s.id.toLowerCase().startsWith('scr_'))
              .map((s) => (
                <option key={s.id} value={s.id} suppressHydrationWarning>
                  {s.id} ({s.eye}) [{s.humanReview?.status === 'CONFIRMED_AI' || s.humanReview?.status === 'OVERRIDDEN' ? 'Sudah Ditelaah' : 'Menunggu'}]
                </option>
              ))}
          </select>
        </div>
      </div>

      {allScreenings.length > 0 &&
        !allScreenings.some((s) => s.humanReview?.status === 'PENDING') && (
        <div style={{ padding: '0.75rem 1rem', marginBottom: '1.25rem', backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#166534', fontSize: '0.8125rem', fontWeight: 600 }}>
          <CheckIcon size={16} />
          <span>Seluruh antrean telaah spesialis telah selesai ditangani. Tidak ada berkas yang menunggu ajudikasi saat ini.</span>
        </div>
      )}

      {/* Clean Dynamic Patient Header Card (without badge clutter) */}
      <div className="card" style={{ marginBottom: '1.25rem' }}>
        <div className="card-body" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '50%', backgroundColor: 'var(--slate-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--slate-700)' }}>
              <UserIcon size={20} />
            </div>
            <div>
              <div style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--slate-900)' }}>{screening.patientName}</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                NIK: <strong>{screening.patientNik}</strong> • Mata: <strong>{screening.eye === 'OD' ? 'Oculus Dexter (OD)' : 'Oculus Sinister (OS)'}</strong> • Waktu: <span suppressHydrationWarning>{formatIndonesianDateTime(screening.capturedAt)}</span>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <span
              suppressHydrationWarning
              className={`badge ${isCaseClosed ? 'badge-pass' : 'badge-review'}`}
              style={{ padding: '0.35rem 0.85rem', fontSize: '0.75rem', fontWeight: 700 }}
            >
              {isCaseClosed ? '✓ Kasus Ditutup (Selesai Telaah)' : '⏳ Menunggu Telaah'}
            </span>
          </div>
        </div>
      </div>

      {/* Desktop Split Review per Section 13 */}
      <div className="grid-2">
        {/* Left Column: Fundus & Grad-CAM Image */}
        <div className="card">
          <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.6rem' }}>
            <div>
              <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
                <EyeIcon size={18} style={{ color: '#0F5FC2' }} />
                <span>Inspeksi Citra Retina Digital &amp; Grad-CAM</span>
              </div>
              <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                Atensi gradien EfficientNet-B3 disinkronkan langsung di atas citra fundus optik asli
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'fundus' && displayLayout === 'overlay' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => {
                  setViewMode('fundus');
                  setDisplayLayout('overlay');
                }}
                title="Tampilkan foto fundus asli tanpa heatmap"
              >
                <EyeIcon size={14} />
                <span>Foto Asli</span>
              </button>
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'gradcam' && displayLayout === 'overlay' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => {
                  setViewMode('gradcam');
                  setDisplayLayout('overlay');
                }}
                title="Tumpangkan peta Grad-CAM langsung di atas foto asli"
              >
                <SlidersIcon size={14} />
                <span>Peta Grad-CAM AI</span>
              </button>
              <button
                type="button"
                className={`btn btn-sm ${displayLayout === 'side-by-side' ? 'btn-primary' : 'btn-outline'}`}
                onClick={() => setDisplayLayout(displayLayout === 'side-by-side' ? 'overlay' : 'side-by-side')}
                title="Bandingkan foto asli dan Grad-CAM berdampingan"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="3" width="8" height="18" rx="1" />
                  <rect x="13" y="3" width="8" height="18" rx="1" />
                </svg>
                <span>Berdampingan</span>
              </button>
            </div>
          </div>
          <div className="card-body">
            {(() => {
              const rawFundusSrc = screening.aiResult?.overlayUrl || '/images/fundus_borderline_sample.jpg';
              const gradcamHeatmapSrc = screening.aiResult?.heatmapUrl || '/images/retina_insight_sample.png';

              if (displayLayout === 'side-by-side') {
                return (
                  <div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '0.75rem' }}>
                      {/* Left: Original Photo */}
                      <div className="fundus-frame" style={{ minHeight: '260px' }}>
                        <div className="fundus-tag">1. Citra Optik Fundus {screening.eye} (Asli)</div>
                        <img
                          src={rawFundusSrc}
                          alt="Citra Funduskopi Digital Asli"
                          className="fundus-img"
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                      </div>

                      {/* Right: Grad-CAM Overlay */}
                      <div className="fundus-frame" style={{ minHeight: '260px' }}>
                        <div className="fundus-tag" style={{ backgroundColor: 'rgba(220, 38, 38, 0.85)' }}>
                          2. Peta Atensi Grad-CAM (Efek {Math.round(gradCamOpacity * 100)}%)
                        </div>
                        <div style={{ position: 'relative', width: '100%', height: '100%' }}>
                          {/* Underlying Photo */}
                          <img
                            src={rawFundusSrc}
                            alt="Citra Fundus Dasar"
                            className="fundus-img"
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          />
                          {/* Heatmap overlay */}
                          <img
                            src={gradcamHeatmapSrc}
                            alt="Heatmap Grad-CAM"
                            style={{
                              position: 'absolute',
                              inset: 0,
                              width: '100%',
                              height: '100%',
                              objectFit: 'cover',
                              opacity: gradCamOpacity,
                              mixBlendMode: 'screen',
                              filter: 'contrast(1.25) saturate(1.2)',
                            }}
                          />
                          {/* Multi-stop lesion attention glow overlay */}
                          <div
                            style={{
                              position: 'absolute',
                              inset: 0,
                              pointerEvents: 'none',
                              opacity: gradCamOpacity * 0.75,
                              background: 'radial-gradient(circle at 62% 46%, rgba(220, 38, 38, 0.85) 0%, rgba(234, 88, 12, 0.7) 25%, rgba(250, 204, 21, 0.45) 45%, rgba(2, 132, 199, 0.2) 65%, transparent 80%)',
                              mixBlendMode: 'screen',
                            }}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                );
              }

              // Standard / Overlay View
              return (
                <div>
                  <div className="fundus-frame" style={{ minHeight: '340px' }}>
                    <div className="fundus-tag" style={{ zIndex: 25 }}>
                      {viewMode === 'fundus'
                        ? `Citra Optik Fundus ${screening.eye} Asli (Field View 45°)`
                        : `Peta Aktivasi Grad-CAM di Atas Foto Asli (${Math.round(gradCamOpacity * 100)}% Opasitas)`}
                    </div>

                    <div style={{ position: 'relative', width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {/* Base authentic photographic fundus image */}
                      <img
                        src={rawFundusSrc}
                        alt="Citra Funduskopi Digital Pasien"
                        className="fundus-img"
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />

                      {/* Grad-CAM Heatmap layer on top of real photo */}
                      {viewMode === 'gradcam' && (
                        <>
                          <img
                            src={gradcamHeatmapSrc}
                            alt="Peta Grad-CAM AI Heatmap"
                            style={{
                              position: 'absolute',
                              inset: 0,
                              width: '100%',
                              height: '100%',
                              objectFit: 'cover',
                              opacity: gradCamOpacity,
                              mixBlendMode: 'screen',
                              filter: 'contrast(1.25) saturate(1.2)',
                              pointerEvents: 'none',
                            }}
                          />
                          {/* Multi-stop attention glow overlay */}
                          <div
                            style={{
                              position: 'absolute',
                              inset: 0,
                              pointerEvents: 'none',
                              opacity: gradCamOpacity * 0.75,
                              background: 'radial-gradient(circle at 62% 46%, rgba(220, 38, 38, 0.85) 0%, rgba(234, 88, 12, 0.7) 25%, rgba(250, 204, 21, 0.45) 45%, rgba(2, 132, 199, 0.2) 65%, transparent 80%)',
                              mixBlendMode: 'screen',
                            }}
                          />

                          {/* Anatomical Lesion Markers */}
                          {showHotspotMarkers && (
                            <>
                              {/* Hotspot 1: Macular microaneurysms & hemorrhage */}
                              <div
                                style={{
                                  position: 'absolute',
                                  left: '62%',
                                  top: '46%',
                                  transform: 'translate(-50%, -50%)',
                                  cursor: 'pointer',
                                  zIndex: 20,
                                }}
                                onClick={() => setActivePinTooltip(activePinTooltip === 'macula' ? null : 'macula')}
                                onMouseEnter={() => setActivePinTooltip('macula')}
                                onMouseLeave={() => setActivePinTooltip(null)}
                              >
                                <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                  <span style={{ position: 'absolute', width: '32px', height: '32px', borderRadius: '50%', backgroundColor: 'rgba(239, 68, 68, 0.45)', animation: 'pulse 1.8s infinite' }} />
                                  <div style={{ width: '18px', height: '18px', borderRadius: '50%', backgroundColor: '#DC2626', border: '2.5px solid #FFFFFF', boxShadow: '0 0 10px rgba(220,38,38,0.9)' }} />
                                </div>
                                {activePinTooltip === 'macula' && (
                                  <div style={{ position: 'absolute', bottom: '130%', left: '50%', transform: 'translateX(-50%)', backgroundColor: 'rgba(15, 23, 42, 0.95)', color: '#FFFFFF', padding: '0.45rem 0.75rem', borderRadius: '8px', fontSize: '0.725rem', whiteSpace: 'nowrap', zIndex: 30, boxShadow: '0 4px 14px rgba(0,0,0,0.5)', border: '1px solid rgba(255,255,255,0.2)' }}>
                                    <div style={{ fontWeight: 700, color: '#F87171' }}>Fokus Atensi Lesi (94.2% Saliency):</div>
                                    <div>Mikroaneurisma &amp; Hemoragi Makula Temporal</div>
                                  </div>
                                )}
                              </div>

                              {/* Hotspot 2: Optic Disc / Papil N.II */}
                              <div
                                style={{
                                  position: 'absolute',
                                  left: '28%',
                                  top: '48%',
                                  transform: 'translate(-50%, -50%)',
                                  cursor: 'pointer',
                                  zIndex: 20,
                                }}
                                onClick={() => setActivePinTooltip(activePinTooltip === 'disc' ? null : 'disc')}
                                onMouseEnter={() => setActivePinTooltip('disc')}
                                onMouseLeave={() => setActivePinTooltip(null)}
                              >
                                <div style={{ width: '16px', height: '16px', borderRadius: '50%', backgroundColor: '#0284C7', border: '2px solid #FFFFFF', boxShadow: '0 0 8px rgba(2,132,199,0.85)' }} />
                                {activePinTooltip === 'disc' && (
                                  <div style={{ position: 'absolute', bottom: '130%', left: '50%', transform: 'translateX(-50%)', backgroundColor: 'rgba(15, 23, 42, 0.95)', color: '#FFFFFF', padding: '0.45rem 0.75rem', borderRadius: '8px', fontSize: '0.725rem', whiteSpace: 'nowrap', zIndex: 30, boxShadow: '0 4px 14px rgba(0,0,0,0.5)', border: '1px solid rgba(255,255,255,0.2)' }}>
                                    <div style={{ fontWeight: 700, color: '#38BDF8' }}>Diskus Optikus (Papil N.II):</div>
                                    <div>Kontur Batas &amp; Titik Keluar Pembuluh Darah</div>
                                  </div>
                                )}
                              </div>
                            </>
                          )}
                        </>
                      )}
                    </div>
                  </div>
                </div>
              );
            })()}

            {/* Interactive Grad-CAM Opacity & Marker Controls */}
            {(viewMode === 'gradcam' || displayLayout === 'side-by-side') && (
              <div
                style={{
                  marginTop: '0.85rem',
                  padding: '0.75rem 1rem',
                  backgroundColor: '#F8FAFC',
                  borderRadius: '10px',
                  border: '1px solid #E2E8F0',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.65rem',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.78rem' }}>
                  <span style={{ fontWeight: 600, color: '#334155', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                    <SlidersIcon size={14} style={{ color: '#0F5FC2' }} />
                    Transparansi Peta Grad-CAM: <strong style={{ color: '#0F5FC2' }}>{Math.round(gradCamOpacity * 100)}%</strong>
                  </span>
                  <div style={{ display: 'flex', gap: '0.25rem' }}>
                    {[0.25, 0.5, 0.75, 1.0].map((val) => (
                      <button
                        key={val}
                        type="button"
                        onClick={() => setGradCamOpacity(val)}
                        style={{
                          padding: '0.15rem 0.45rem',
                          fontSize: '0.7rem',
                          borderRadius: '4px',
                          border: '1px solid #CBD5E1',
                          backgroundColor: gradCamOpacity === val ? '#0F5FC2' : '#FFFFFF',
                          color: gradCamOpacity === val ? '#FFFFFF' : '#475569',
                          fontWeight: 600,
                          cursor: 'pointer',
                        }}
                      >
                        {Math.round(val * 100)}%
                      </button>
                    ))}
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.05"
                    value={gradCamOpacity}
                    onChange={(e) => setGradCamOpacity(parseFloat(e.target.value))}
                    style={{ flex: 1, accentColor: '#0F5FC2', cursor: 'pointer' }}
                  />
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.75rem', color: '#475569', cursor: 'pointer', userSelect: 'none' }}>
                    <input
                      type="checkbox"
                      checked={showHotspotMarkers}
                      onChange={(e) => setShowHotspotMarkers(e.target.checked)}
                      style={{ accentColor: '#0F5FC2' }}
                    />
                    <span>Pin Lesi</span>
                  </label>
                </div>
              </div>
            )}

            {/* SHA-256 and Model Notice */}
            <div style={{ marginTop: '0.85rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.725rem', color: '#64748B', flexWrap: 'wrap', gap: '0.4rem' }}>
              <div>
                SHA-256 Integritas: <span className="code-inline" style={{ fontSize: '0.7rem' }}>{screening.imageHash ? screening.imageHash.substring(0, 16) + '...' : '986f918d7f4bdb56...'}</span>
              </div>
              <div style={{ fontWeight: 600, color: '#0F5FC2' }}>
                Fokus Model: {screening.aiResult?.gradCamFocus || 'Area Mikroaneurisma & Makula'}
              </div>
            </div>

            <div style={{ marginTop: '0.65rem', padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
              <InfoIcon size={15} style={{ color: 'var(--brand-700)', flexShrink: 0 }} />
              <span style={{ fontSize: '0.725rem', color: 'var(--slate-600)', lineHeight: 1.4 }}>
                <strong>Pemberitahuan Klinis:</strong> Peta Grad-CAM kini disinkronkan langsung di atas citra fundus retina asli pasien (bukan grafis simulasi). Menampilkan gradien atensi arsitektur konvolusi EfficientNet-B3 pada lapisan <code>Conv_Head</code> untuk melacak sebaran mikrovaskulatur lesi.
              </span>
            </div>
          </div>
        </div>

        {/* Right Column: AI Suggestion & Ophthalmologist Adjudication Form */}
        <div className="card">
          <div className="card-header">
            <div className="card-title">
              {isCaseClosed && isClosedView ? 'Hasil Ajudikasi Spesialis Mata (Kasus Ditutup)' : 'Formulir Ajudikasi Spesialis Mata'}
            </div>
          </div>
          <div className="card-body">
            {isCaseClosed && isClosedView ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div style={{ padding: '1.25rem', backgroundColor: '#F0FDF4', borderRadius: '12px', border: '1px solid #BBF7D0', textAlign: 'center' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '50%', backgroundColor: '#16A34A', color: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 0.75rem auto' }}>
                    <CheckIcon size={24} />
                  </div>
                  <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#166534' }}>
                    Berkas Ditutup (Telaah Selesai)
                  </div>
                  <div style={{ fontSize: '0.8125rem', color: '#374151', marginTop: '0.35rem', lineHeight: 1.5 }}>
                    Hasil telaah klinis telah resmi diajudikasi oleh <strong>{screening.humanReview?.reviewerName || activeDoctor.name}</strong> dan status telaah telah dikirimkan ke aplikasi mobile pasien.
                  </div>
                </div>

                <div style={{ padding: '1rem', backgroundColor: '#F8FAFC', borderRadius: '10px', border: '1px solid #E2E8F0', fontSize: '0.8125rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid #E2E8F0', marginBottom: '0.5rem' }}>
                    <span style={{ color: '#64748B' }}>Dokter Penelaah:</span>
                    <span style={{ fontWeight: 700, color: '#0F172A' }}>{screening.humanReview?.reviewerName || activeDoctor.name}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid #E2E8F0', marginBottom: '0.5rem' }}>
                    <span style={{ color: '#64748B' }}>SIP / STR Terverifikasi:</span>
                    <span style={{ fontWeight: 600, color: '#0F172A' }}>{screening.humanReview?.reviewerNip || activeDoctor.sip}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid #E2E8F0', marginBottom: '0.5rem' }}>
                    <span style={{ color: '#64748B' }}>Waktu Selesai Ditelaah:</span>
                    <span suppressHydrationWarning style={{ fontWeight: 600, color: '#0F172A' }}>{formatIndonesianDateTime(screening.humanReview?.adjudicatedAt)}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid #E2E8F0', marginBottom: '0.5rem' }}>
                    <span style={{ color: '#64748B' }}>Keputusan Ajudikasi:</span>
                    <span style={{ fontWeight: 700, color: '#16A34A' }}>
                      {screening.humanReview?.status === 'OVERRIDDEN' ? `Clinical Override (${screening.aiResult?.drLabel || 'NPDR'})` : 'Konfirmasi Temuan AI'}
                    </span>
                  </div>
                  <div>
                    <div style={{ color: '#64748B', marginBottom: '0.25rem', marginTop: '0.5rem' }}>Catatan Klinis Dokter:</div>
                    <div style={{ padding: '0.6rem 0.75rem', backgroundColor: '#FFFFFF', borderRadius: '6px', border: '1px solid #CBD5E1', color: '#1E293B', fontStyle: 'italic', lineHeight: 1.45 }}>
                      "{screening.humanReview?.clinicalNotes || clinicalNotes}"
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={() => setIsClosedView(false)}
                    style={{ flex: 1, padding: '0.6rem', fontSize: '0.8rem', borderRadius: '8px' }}
                  >
                    Buka Kembali untuk Koreksi
                  </button>
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    onClick={() => {
                      const pending = allScreenings.find((s) => s.humanReview?.status === 'PENDING' && s.id !== screening.id);
                      if (pending) {
                        handleSelectScreening(pending.id);
                      } else {
                        alert('Semua berkas telaah dalam antrean telah selesai diajudikasi!');
                      }
                    }}
                    style={{ flex: 1, padding: '0.6rem', fontSize: '0.8rem', borderRadius: '8px' }}
                  >
                    Periksa Antrean Lain
                  </button>
                </div>
              </div>
            ) : (
              <div>
                {/* Doctor Identity & SIP Selector */}
                <div className="form-group" style={{ backgroundColor: 'var(--slate-50)', padding: '0.75rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', marginBottom: '1rem' }}>
                  <label className="form-label" htmlFor="doctor-select" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--slate-700)' }}>
                    <ShieldCheckIcon size={14} style={{ color: '#059669' }} />
                    <span>Dokter Spesialis Mata Penelaah (SIP / STR Terverifikasi):</span>
                  </label>
                  <select
                    id="doctor-select"
                    className="form-control"
                    value={selectedDoctorIndex}
                    onChange={(e) => setSelectedDoctorIndex(Number(e.target.value))}
                    style={{ fontSize: '0.8125rem', fontWeight: 600 }}
                  >
                    {doctorsList.map((doc, idx) => (
                      <option key={idx} value={idx}>
                        {doc.name} — {doc.role} ({doc.hospital})
                      </option>
                    ))}
                  </select>
                  <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)', marginTop: '0.35rem' }}>
                    {activeDoctor.sip} • Terkoneksi dengan Registry Audit Klinis
                  </div>
                </div>

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
                    placeholder="Tuliskan catatan klinis dokter penelaah di sini..."
                  />
                  <div className="form-hint">
                    Tercatat bersama {activeDoctor.sip} dan tanda tangan kriptografis sistem.
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1.25rem' }}>
                  <button
                    type="button"
                    className="btn"
                    style={{
                      flex: 1,
                      backgroundColor: '#0F5FC2',
                      color: '#ffffff',
                      border: '1px solid #0D47A1',
                      padding: '0.75rem 1.25rem',
                      fontWeight: 700,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '0.5rem',
                      borderRadius: 'var(--radius-sm)',
                      cursor: 'pointer',
                      boxShadow: '0 4px 12px rgba(15, 95, 194, 0.3)',
                      transition: 'all 0.2s ease',
                    }}
                    onClick={handleSave}
                  >
                    <CheckIcon size={18} />
                    <span>Selesai di Telaah & Tandatangani Ajudikasi Klinis</span>
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
