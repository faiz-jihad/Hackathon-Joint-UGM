import React, { useState, useEffect, useRef } from 'react';
import { AdminNotificationCenter } from './AdminNotificationCenter';
import { UserIcon, LogOutIcon } from './Icons';

interface AdminTopBarProps {
  activeTab: string;
  onStartScreening: () => void;
  onSwitchCharacter?: () => void;
  onLogout?: () => void;
  onNavigateTab?: (tab: string) => void;
  onToggleMobileMenu?: () => void;
  currentRole?: 'admin' | 'dokter' | 'pengguna' | null;
  currentUser?: {
    fullName?: string;
    email?: string;
    role?: string;
    hospital?: string;
    facilityType?: string;
  } | null;
}

export function AdminTopBar({
  activeTab,
  onStartScreening,
  onSwitchCharacter,
  onLogout,
  onNavigateTab,
  onToggleMobileMenu,
  currentRole = 'admin',
  currentUser,
}: AdminTopBarProps) {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsDropdownOpen(false);
      }
    };
    if (isDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isDropdownOpen]);

  const titles: Record<string, { section: string; title: string }> = {
    dashboard: { section: 'Alur Skrining', title: 'Dashboard & Antrean Aktif' },
    users: { section: 'Master Data', title: 'Daftar Pengguna' },
    roles: { section: 'Master Data', title: 'Data Master Role & Hak Akses' },
    'care-companion-master': { section: 'Master Data', title: 'Pendamping Perawatan' },
    'facilities-master': { section: 'Master Data', title: 'Fasilitas Kesehatan (FKTP & Faskes Rujukan)' },
    'doctor-verification': { section: 'Verifikasi', title: 'Verifikasi Akun Dokter' },
    screening: { section: 'Alur Skrining', title: 'Skrining Baru Bilateral (OD/OS)' },
    review: { section: 'Alur Skrining', title: 'Portal Telaah Spesialis Mata & Grad-CAM' },
    patients: { section: 'Manajemen Rekam Medis', title: 'Direktori Pasien & Riwayat Longitudinal' },
    referrals: { section: 'Manajemen Rekam Medis', title: 'Jaringan Faskes Rujukan & BPJS' },
    'sos-monitoring': { section: 'Alur Skrining', title: 'Monitoring SOS' },
    audit: { section: 'Keamanan & Kepatuhan', title: 'Log Audit Non-Repudiation & Model Registry' },
  };

  const current = titles[activeTab] || { section: 'Alur Skrining', title: 'Dashboard' };

  const displayName = currentUser?.fullName || (currentRole === 'dokter' ? 'dr. Yunani Setyandriana, Sp.M' : 'Administrator RETIVA');
  const displayEmail = currentUser?.email || (currentRole === 'dokter' ? 'tioramadhan3106@gmail.com' : 'admin@gmail.com');

  return (
    <header className="admin-topbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', minWidth: 0, flex: 1 }}>
        {onToggleMobileMenu && (
          <button
            type="button"
            className="admin-mobile-menu-btn"
            onClick={onToggleMobileMenu}
            title="Buka Menu Navigasi"
            aria-label="Buka Menu Navigasi"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
        )}
        <div className="admin-breadcrumbs">
          <span className="admin-breadcrumb-section">{current.section}</span>
          <span className="admin-breadcrumb-sep" style={{ color: 'var(--slate-400)' }}>/</span>
          <span className="admin-breadcrumb-current">{current.title}</span>
        </div>
      </div>

      {/* Topbar Right Actions: Notification Center & Profile */}
      <div className="admin-topbar-actions" style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
        {/* Central Notification Bell Component */}
        <AdminNotificationCenter onNavigateTab={onNavigateTab} />

        {/* User Profile Avatar with Dropdown */}
        <div
          ref={dropdownRef}
          style={{
            position: 'relative',
            display: 'flex',
            alignItems: 'center',
            paddingLeft: '0.75rem',
            borderLeft: '1px solid #E2E8F0',
          }}
        >
          <button
            type="button"
            onClick={() => setIsDropdownOpen((prev) => !prev)}
            style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              backgroundColor: isDropdownOpen ? '#0F5FC2' : '#EFF6FF',
              border: '1.5px solid #BFDBFE',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: isDropdownOpen ? '#FFFFFF' : '#0F5FC2',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              padding: 0,
              boxShadow: isDropdownOpen ? '0 0 0 3px rgba(15, 95, 194, 0.2)' : 'none',
            }}
            title={displayEmail ? `Akun: ${displayEmail}` : 'Profil Pengguna'}
            aria-expanded={isDropdownOpen}
          >
            <UserIcon size={17} />
          </button>

          {/* Interactive Profile Dropdown */}
          {isDropdownOpen && (
            <div
              style={{
                position: 'absolute',
                top: 'calc(100% + 10px)',
                right: 0,
                width: '240px',
                backgroundColor: '#FFFFFF',
                borderRadius: '12px',
                border: '1px solid #E2E8F0',
                boxShadow: '0 10px 25px -5px rgba(15, 23, 42, 0.15), 0 8px 10px -6px rgba(15, 23, 42, 0.08)',
                padding: '0.5rem 0',
                zIndex: 1000,
              }}
            >
              {/* User Header Details */}
              <div style={{ padding: '0.65rem 1rem', borderBottom: '1px solid #F1F5F9' }}>
                <div style={{ fontWeight: 700, fontSize: '0.875rem', color: '#0F172A', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {displayName}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#64748B', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginTop: '2px' }}>
                  {displayEmail}
                </div>
              </div>

              {/* Logout Action */}
              <div style={{ padding: '0.35rem 0' }}>
                <button
                  type="button"
                  onClick={() => {
                    setIsDropdownOpen(false);
                    if (onLogout) {
                      onLogout();
                    }
                  }}
                  style={{
                    width: '100%',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.65rem',
                    padding: '0.55rem 1rem',
                    background: 'none',
                    border: 'none',
                    textAlign: 'left',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    color: '#EF4444',
                    cursor: 'pointer',
                    transition: 'background 0.15s ease',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#FEF2F2')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <LogOutIcon size={16} />
                  <span>Keluar (Logout)</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
