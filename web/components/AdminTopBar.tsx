import React from 'react';
import { AdminNotificationCenter } from './AdminNotificationCenter';
import { UserIcon } from './Icons';

interface AdminTopBarProps {
  activeTab: string;
  onStartScreening: () => void;
  onSwitchCharacter?: () => void;
  onLogout?: () => void;
  onNavigateTab?: (tab: string) => void;
  currentRole?: 'admin' | 'dokter' | 'pengguna' | null;
  currentUser?: {
    fullName?: string;
    email?: string;
    role?: string;
  } | null;
}

export function AdminTopBar({
  activeTab,
  onStartScreening,
  onSwitchCharacter,
  onLogout,
  onNavigateTab,
  currentRole = 'admin',
  currentUser,
}: AdminTopBarProps) {
  const titles: Record<string, { section: string; title: string }> = {
    dashboard: { section: 'Alur Skrining', title: 'Dashboard & Antrean Aktif' },
    users: { section: 'Master Data', title: 'Daftar Pengguna' },
    roles: { section: 'Master Data', title: 'Data Master Role & Hak Akses' },
    'doctor-verification': { section: 'Verifikasi', title: 'Verifikasi Akun Dokter' },
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

      {/* Topbar Right Actions: Notification Center & Profile */}
      <div className="admin-topbar-actions" style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
        {/* Central Notification Bell Component */}
        <AdminNotificationCenter onNavigateTab={onNavigateTab} />

        {/* User Profile Avatar */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            paddingLeft: '0.75rem',
            borderLeft: '1px solid #E2E8F0',
          }}
        >
          <button
            type="button"
            onClick={onSwitchCharacter || onLogout}
            style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              backgroundColor: '#E3F2FD',
              border: '1.5px solid #BBDEFB',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#0D47A1',
              cursor: onSwitchCharacter || onLogout ? 'pointer' : 'default',
              transition: 'all 0.2s ease',
              padding: 0,
            }}
            title={currentUser?.email ? `Akun: ${currentUser.email}` : 'Profil Pengguna'}
          >
            <UserIcon size={17} />
          </button>
        </div>
      </div>
    </header>
  );
}
