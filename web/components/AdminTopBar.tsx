import React from 'react';
import { ShieldCheckIcon, EyeIcon, CheckIcon } from './Icons';

interface AdminTopBarProps {
  activeTab: string;
  onStartScreening: () => void;
}

export function AdminTopBar({ activeTab, onStartScreening }: AdminTopBarProps) {
  const titles: Record<string, { section: string; title: string }> = {
    dashboard: { section: 'Alur Skrining', title: 'Dashboard & Antrean Aktif' },
    screening: { section: 'Alur Skrining', title: 'Skrining Baru Bilateral (OD/OS)' },
    review: { section: 'Alur Skrining', title: 'Portal Telaah Spesialis Mata & Grad-CAM' },
    patients: { section: 'Manajemen Rekam Medis', title: 'Direktori Pasien & Riwayat Longitudinal' },
    referrals: { section: 'Manajemen Rekam Medis', title: 'Jaringan Faskes Rujukan & BPJS' },
    audit: { section: 'Keamanan & Kepatuhan', title: 'Log Audit Non-Repudiation & Model Registry' },
  };

  const current = titles[activeTab] || { section: 'Alur Skrining', title: 'Dashboard' };

  return (
    <header className="admin-topbar">
      <div className="admin-breadcrumbs">
        <span>{current.section}</span>
        <span style={{ color: 'var(--slate-400)' }}>/</span>
        <span className="admin-breadcrumb-current">{current.title}</span>
      </div>

      <div className="admin-topbar-actions">
        {/* Compliance Badge */}
        <div className="header-status-badge" style={{ backgroundColor: 'var(--slate-50)' }}>
          <ShieldCheckIcon size={14} style={{ color: 'var(--brand-700)' }} />
          <span>Perdami &amp; ADA 2024</span>
        </div>

        {/* System Health */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.75rem', color: 'var(--slate-600)', padding: '0.35rem 0.65rem', backgroundColor: 'var(--status-pass-bg)', border: '1px solid var(--status-pass-border)', borderRadius: '9999px' }}>
          <CheckIcon size={12} style={{ color: 'var(--status-pass-text)' }} />
          <span style={{ fontWeight: 600, color: 'var(--status-pass-text)' }}>Sistem Normal</span>
        </div>

        {/* Quick Screening CTA */}
        {activeTab !== 'screening' && (
          <button
            type="button"
            className="btn btn-primary btn-sm"
            onClick={onStartScreening}
          >
            <EyeIcon size={14} />
            <span>+ Skrining Baru</span>
          </button>
        )}
      </div>
    </header>
  );
}
