import React, { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import {
  LayoutDashboardIcon,
  UsersIcon,
  ShieldCheckIcon,
} from './Icons';

interface AdminSidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  reviewCount?: number;
  patientCount?: number;
  currentUser?: {
    fullName?: string;
    email?: string;
    role?: string;
  } | null;
  currentRole?: 'admin' | 'dokter' | 'pengguna' | null;
  onLogout?: () => void;
}

export function AdminSidebar({
  activeTab,
  onTabChange,
  reviewCount = 0,
  patientCount = 0,
  currentUser,
  currentRole = 'admin',
  onLogout,
}: AdminSidebarProps) {
  const [pendingDoctorCount, setPendingDoctorCount] = useState<number>(0);
  const [mounted, setMounted] = useState<boolean>(false);
  const lastKnownNameRef = useRef<string>(currentUser?.fullName || '');
  if (currentUser?.fullName) {
    lastKnownNameRef.current = currentUser.fullName;
  }

  useEffect(() => {
    setMounted(true);
    const updateCount = () => {
      try {
        const stored = localStorage.getItem('retiva_doctor_verifications');
        if (stored) {
          const apps = JSON.parse(stored);
          if (Array.isArray(apps)) {
            const dummyIds = ['DOC-REG-2026-0101', 'DOC-REG-2026-0102', 'DOC-REG-2026-0098', 'DOC-REG-2026-0089'];
            setPendingDoctorCount(apps.filter((a: any) => !dummyIds.includes(a.id) && a.status === 'PENDING').length);
            return;
          }
        }
        setPendingDoctorCount(0);
      } catch {
        setPendingDoctorCount(0);
      }
    };

    updateCount();
    window.addEventListener('storage', updateCount);
    return () => window.removeEventListener('storage', updateCount);
  }, [activeTab]);

  return (
    <aside className="admin-sidebar">
      <div>
        {/* Header & Brand */}
        <div className="admin-sidebar-header">
          <div className="admin-brand" style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
            <Image
              src="/images/logo/logo-white.png"
              alt="Logo RETIVA"
              width={42}
              height={38}
              style={{
                objectFit: 'contain',
                width: '42px',
                height: '38px',
                filter: 'brightness(0) invert(1) drop-shadow(0 2px 10px rgba(255,255,255,0.25))',
              }}
              priority
            />
            <div>
              <span
                className="admin-brand-name"
                style={{
                  fontSize: '1.5rem',
                  fontWeight: 800,
                  letterSpacing: '0.02em',
                  color: '#FFFFFF',
                  lineHeight: 1,
                  display: 'block',
                }}
              >
                RETIVA
              </span>
            </div>
          </div>

          {/* Active Facility Context */}
          <div className="admin-facility-box">
            <div className="admin-facility-name">Puskesmas Mlati II</div>
            <div className="admin-facility-type">
              <span>FKTP Sleman</span>
            </div>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="admin-sidebar-nav" style={{ padding: '0.85rem 0.75rem', display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
          {/* Main Menu: Dashboard */}
          <button
            type="button"
            className={`admin-nav-btn ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => onTabChange('dashboard')}
          >
            <div className="admin-nav-item-left">
              <span className="admin-nav-icon">
                <LayoutDashboardIcon size={18} />
              </span>
              <span>Dashboard &amp; Antrean</span>
            </div>
          </button>

          {/* Group Menu: Master Data */}
          <div style={{ marginTop: '0.85rem', marginBottom: '0.2rem' }}>
            <div className="admin-nav-group-title" style={{ paddingLeft: '0.5rem', paddingBottom: '0.4rem' }}>
              Master Data
            </div>
            <button
              type="button"
              className={`admin-nav-btn ${activeTab === 'users' ? 'active' : ''}`}
              onClick={() => onTabChange('users')}
            >
              <div className="admin-nav-item-left">
                <span className="admin-nav-icon">
                  <UsersIcon size={18} />
                </span>
                <span>Pengguna</span>
              </div>
            </button>
            <button
              type="button"
              className={`admin-nav-btn ${activeTab === 'roles' ? 'active' : ''}`}
              onClick={() => onTabChange('roles')}
            >
              <div className="admin-nav-item-left">
                <span className="admin-nav-icon">
                  <ShieldCheckIcon size={18} />
                </span>
                <span>Role &amp; Hak Akses</span>
              </div>
            </button>
          </div>

          {/* Group Menu: Verifikasi */}
          <div style={{ marginTop: '0.85rem', marginBottom: '0.2rem' }}>
            <div className="admin-nav-group-title" style={{ paddingLeft: '0.5rem', paddingBottom: '0.4rem' }}>
              Verifikasi
            </div>
            <button
              type="button"
              className={`admin-nav-btn ${activeTab === 'doctor-verification' ? 'active' : ''}`}
              onClick={() => onTabChange('doctor-verification')}
            >
              <div className="admin-nav-item-left">
                <span className="admin-nav-icon">
                  <ShieldCheckIcon size={18} />
                </span>
                <span>Dokter</span>
              </div>
              {mounted && pendingDoctorCount > 0 && (
                <span className={`admin-nav-badge ${activeTab === 'doctor-verification' ? 'active' : ''}`}>
                  {pendingDoctorCount} Baru
                </span>
              )}
            </button>
          </div>
        </nav>
      </div>

      {/* Operator User Card */}
      <div className="admin-sidebar-footer">
        {(() => {
          const displayName = currentUser?.fullName || lastKnownNameRef.current || (currentRole === 'dokter' ? 'dr. Harianto, Sp.M(K)' : 'Administrator RETIVA');
          const displayRole = currentRole === 'dokter' ? 'Spesialis Mata (Reviewer)' : 'Tenaga Kesehatan Primer';
          const initials = displayName
            .split(' ')
            .filter(Boolean)
            .slice(0, 2)
            .map((w) => w[0].toUpperCase())
            .join('');

          return (
            <div className="admin-user-card">
              <div className="admin-user-avatar">
                <span>{initials || 'US'}</span>
              </div>
              <div className="admin-user-info">
                <div className="admin-user-name" title={displayName}>{displayName}</div>
                <div className="admin-user-role">{displayRole}</div>
              </div>
              {onLogout ? (
                <button
                  type="button"
                  onClick={onLogout}
                  className="admin-sidebar-logout-icon-btn"
                  title="Keluar dari Akun"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                  </svg>
                </button>
              ) : (
                <div title="Terverifikasi SIP Kemenkes" style={{ color: '#2196F3' }}>
                  <ShieldCheckIcon size={16} />
                </div>
              )}
            </div>
          );
        })()}
      </div>
    </aside>
  );
}
