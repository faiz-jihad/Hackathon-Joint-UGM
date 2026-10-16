'use client';

import React, { useState, useEffect, useRef } from 'react';
import Image from 'next/image';

export type CharacterRole = 'pengguna' | 'admin' | 'dokter';

interface CharacterInfo {
  id: CharacterRole;
  roleNumberLabel: string;
  displayTitle: string;
  categoryTag: string;
  tagline: string;
  imageSrc: string;
  imageAlt: string;
}

const CHARACTERS: CharacterInfo[] = [
  {
    id: 'admin',
    roleNumberLabel: 'PERAN 01',
    displayTitle: 'ADMINISTRATOR',
    categoryTag: 'ADMIN',
    tagline: 'Verifikasi & Pengawasan Skrining',
    imageSrc: '/images/character/Admin.png',
    imageAlt: 'Foto Profil Dewi Sartika - Admin Tenaga Kesehatan Primer',
  },
  {
    id: 'dokter',
    roleNumberLabel: 'PERAN 02',
    displayTitle: 'DOKTER',
    categoryTag: 'DOKTER',
    tagline: 'Telaah Vitreoretina & Adjudikasi',
    imageSrc: '/images/character/Dokter.png',
    imageAlt: 'Foto Profil dr. Harianto, Sp.M(K) - Dokter Spesialis Mata',
  },
];

interface CharacterSelectViewProps {
  onSelectRole: (role: CharacterRole) => void;
  initialRole?: CharacterRole;
}

export function CharacterSelectView({
  onSelectRole,
  initialRole = 'admin',
}: CharacterSelectViewProps) {
  const [selectedIndex, setSelectedIndex] = useState<number>(() => {
    const idx = CHARACTERS.findIndex((c) => c.id === initialRole);
    return idx >= 0 ? idx : 0; // Default to Administrator (index 0)
  });

  useEffect(() => {
    if (initialRole) {
      const idx = CHARACTERS.findIndex((c) => c.id === initialRole);
      if (idx >= 0) {
        setSelectedIndex(idx);
      }
    }
  }, [initialRole]);

  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);
  const [isConfirming, setIsConfirming] = useState<boolean>(false);
  const [confirmingRole, setConfirmingRole] = useState<CharacterRole | null>(null);
  const [burstIndex, setBurstIndex] = useState<number | null>(null);
  const [burstKey, setBurstKey] = useState<number>(0);
  const audioCtxRef = useRef<AudioContext | null>(null);

  // Modern UI Sound Synthesizer
  const getAudioContext = () => {
    if (typeof window === 'undefined') return null;
    if (!audioCtxRef.current) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        audioCtxRef.current = new AudioCtx();
      }
    }
    if (audioCtxRef.current && audioCtxRef.current.state === 'suspended') {
      audioCtxRef.current.resume();
    }
    return audioCtxRef.current;
  };

  const playHoverChime = () => {
    if (!soundEnabled) return;
    requestAnimationFrame(() => {
      try {
        const ctx = getAudioContext();
        if (!ctx) return;
        const now = ctx.currentTime;

        // Sub bass game punch
        const subOsc = ctx.createOscillator();
        const subGain = ctx.createGain();
        subOsc.type = 'sine';
        subOsc.frequency.setValueAtTime(160, now);
        subOsc.frequency.exponentialRampToValueAtTime(50, now + 0.12);
        subGain.gain.setValueAtTime(0.12, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
        subOsc.connect(subGain);
        subGain.connect(ctx.destination);
        subOsc.start(now);
        subOsc.stop(now + 0.12);

        // Rising sci-fi select tone
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(523.25, now); // C5
        osc.frequency.exponentialRampToValueAtTime(987.77, now + 0.1); // B5
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.14);
      } catch {
        // Audio error ignored
      }
    });
  };

  const playConfirmFanfare = () => {
    if (!soundEnabled) return;
    requestAnimationFrame(() => {
      try {
        const ctx = getAudioContext();
        if (!ctx) return;
        const now = ctx.currentTime;

        const chord = [523.25, 659.25, 783.99, 1046.5];
        chord.forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();

          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now + idx * 0.05);

          gain.gain.setValueAtTime(0.08, now + idx * 0.05);
          gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.05 + 0.18);

          osc.connect(gain);
          gain.connect(ctx.destination);

          osc.start(now + idx * 0.05);
          osc.stop(now + idx * 0.05 + 0.18);
        });
      } catch {
        // Audio error ignored
      }
    });
  };

  // Keyboard navigation: [Left], [Right], [Enter], [1], [2], [3]
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (isConfirming) return;

      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        const next = selectedIndex > 0 ? selectedIndex - 1 : CHARACTERS.length - 1;
        setSelectedIndex(next);
        triggerSelectAnim(next);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        const next = selectedIndex < CHARACTERS.length - 1 ? selectedIndex + 1 : 0;
        setSelectedIndex(next);
        triggerSelectAnim(next);
      } else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        handleConfirm(CHARACTERS[selectedIndex].id);
      } else if (e.key === '1') {
        setSelectedIndex(0);
        triggerSelectAnim(0);
      } else if (e.key === '2') {
        setSelectedIndex(1);
        triggerSelectAnim(1);
      } else if (e.key === '3') {
        setSelectedIndex(2);
        triggerSelectAnim(2);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedIndex, isConfirming, soundEnabled]);

  const triggerSelectAnim = (idx: number) => {
    setBurstIndex(idx);
    setBurstKey((k) => k + 1);
    playHoverChime();
  };

  const handleSelect = (idx: number) => {
    setSelectedIndex(idx);
    try {
      localStorage.setItem('retiva_last_role', CHARACTERS[idx].id);
    } catch {}
    triggerSelectAnim(idx);
  };

  const handleConfirm = (role: CharacterRole) => {
    if (isConfirming) return;
    try {
      localStorage.setItem('retiva_last_role', role);
    } catch {}
    setIsConfirming(true);
    setConfirmingRole(role);
    playConfirmFanfare();
    setTimeout(() => {
      onSelectRole(role);
    }, 850);
  };

  return (
    <div className="modern-character-stage">
      {/* Ambient Radial Lighting */}
      <div className="modern-ambient-glow glow-top-left" />
      <div className="modern-ambient-glow glow-bottom-right" />
      <div className="modern-grid-overlay" />

      {/* Top Bar Header */}
      <header className="modern-character-topbar">
        <div className="modern-brand-cluster">
          <div className="modern-brand-item">
            <Image
              src="/logo/logo.png"
              alt="RETIVA Logo"
              width={44}
              height={34}
              priority
              className="modern-brand-logo-img"
            />
            <span className="modern-brand-name">RETIVA</span>
          </div>
          <div className="modern-brand-divider" />
          <span className="modern-brand-subtitle">
            Sistem Pendukung Keputusan Klinis Skrining Retinopati Diabetik
          </span>
        </div>

        <div className="modern-topbar-controls">
          <button
            type="button"
            className="modern-audio-toggle-btn"
            onClick={() => setSoundEnabled(!soundEnabled)}
            title={soundEnabled ? 'Matikan Suara Audio' : 'Nyalakan Suara Audio'}
          >
            <span>{soundEnabled ? '🔊 Audio Aktif' : '🔇 Audio Mute'}</span>
          </button>
        </div>
      </header>

      {/* Main Container */}
      <main className="modern-character-main">
        {/* Title Section */}
        <div className="modern-title-section">
          <h1 className="modern-main-heading">PILIH PERAN ANDA</h1>
          <p className="modern-main-subheading">
            Tentukan identitas anda sesuai dengan kebutuhan anda sekarang.
          </p>
        </div>

        {/* 3 Character Cards matching user reference concept */}
        <div className="modern-cards-row">
          {CHARACTERS.map((char, index) => {
            const isSelected = selectedIndex === index;
            const isBursting = burstIndex === index;
            const isLoading = isConfirming && (confirmingRole === char.id || (confirmingRole === null && isSelected));

            return (
              <div
                key={char.id}
                className={`modern-character-card ${isSelected ? 'is-active' : ''} ${isBursting ? 'is-selected-burst' : ''} ${isLoading ? 'is-card-loading' : ''}`}
                onClick={() => {
                  if (!isConfirming) {
                    handleSelect(index);
                  }
                }}
              >
                {/* Shockwave Glow Pulse Ring */}
                {isBursting && (
                  <div key={`shockwave-${burstKey}`} className="game-card-shockwave" />
                )}

                {/* Full-Bleed Card Frame */}
                <div className="modern-card-inner">
                  {/* Card Loading Overlay */}
                  {isLoading && (
                    <div className="card-loading-overlay">
                      <div className="card-loading-spinner" />
                      <span className="card-loading-text">Memuat...</span>
                    </div>
                  )}

                  {/* Diagonal Laser Light Sweep (Glint) */}
                  {isBursting && !isLoading && (
                    <div key={`sheen-${burstKey}`} className="game-card-light-sweep" />
                  )}

                  {/* Instant Flash Glint */}
                  {isBursting && !isLoading && (
                    <div key={`flash-${burstKey}`} className="game-card-flash" />
                  )}

                  {/* Full Background Photo Layer */}
                  <div className="modern-card-bg-layer">
                    <Image
                      src={char.imageSrc}
                      alt={char.imageAlt}
                      fill
                      sizes="(max-width: 768px) 100vw, 550px"
                      priority
                      className="modern-character-image-full"
                    />
                  </div>

                  {/* Bottom Content Area */}
                  <div className="modern-card-bottom-content">
                    <h2 className="modern-card-role-title">{char.displayTitle}</h2>
                    <p className="modern-card-role-tagline">{char.tagline}</p>

                    {/* Bottom Action Button */}
                    <button
                      type="button"
                      disabled={isConfirming}
                      className={`modern-card-action-btn ${isSelected ? 'btn-active' : 'btn-ghost'} ${isLoading ? 'is-loading' : ''}`}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSelect(index);
                        handleConfirm(char.id);
                      }}
                    >
                      {isLoading ? (
                        <span className="btn-loading-content">
                          <span className="btn-inline-spinner" />
                          <span>Memuat...</span>
                        </span>
                      ) : (
                        <span>PILIH PERAN</span>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Download App Banner */}
        <div className="modern-download-banner">
          <div className="modern-download-inner">
            <div className="modern-download-icon">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9l3 3 3-3h-2V8h-2v8z" fill="currentColor"/>
              </svg>
            </div>
            <div className="modern-download-text">
              <span className="modern-download-title">📱 Unduh Aplikasi RETIVA</span>
              <span className="modern-download-subtitle">Android · v1.0.0 · 22.8 MB · ARM64</span>
            </div>
            <a
              href="/retiva-app.apk"
              download="retiva-app.apk"
              className="modern-download-btn"
              onClick={(e) => {
                // Play a small chime on download
                try {
                  const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
                  const ctx = new AudioCtx();
                  const osc = ctx.createOscillator();
                  const gain = ctx.createGain();
                  osc.type = 'sine';
                  osc.frequency.setValueAtTime(880, ctx.currentTime);
                  osc.frequency.exponentialRampToValueAtTime(1760, ctx.currentTime + 0.15);
                  gain.gain.setValueAtTime(0.07, ctx.currentTime);
                  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.2);
                  osc.connect(gain);
                  gain.connect(ctx.destination);
                  osc.start();
                  osc.stop(ctx.currentTime + 0.2);
                } catch { /* ignore */ }
              }}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: 0 }}>
                <path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z" fill="currentColor"/>
              </svg>
              <span>Download APK</span>
            </a>
          </div>
        </div>
      </main>
    </div>
  );
}
