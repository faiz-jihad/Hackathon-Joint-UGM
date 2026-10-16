import React, { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import {
  LayoutDashboardIcon,
  UsersIcon,
  ShieldCheckIcon,
  UtensilsIcon,
  HeartHandshakeIcon,
  EyeIcon,
  HospitalIcon,
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
    hospital?: string;
    facilityType?: string;
  } | null;
  currentRole?: 'admin' | 'dokter' | 'pengguna' | null;
  onLogout?: () => void;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
}

export function AdminSidebar({
  activeTab,
  onTabChange,
  reviewCount = 0,
  patientCount = 0,
  currentUser,
  currentRole = 'admin',
  onLogout,
  isOpenMobile = false,
  onCloseMobile,
}: AdminSidebarProps) {
  const [pendingDoctorCount, setPendingDoctorCount] = useState<number>(0);
  const [activeSosCount, setActiveSosCount] = useState<number>(0);
  const [mounted, setMounted] = useState<boolean>(false);
  const [activeHospital, setActiveHospital] = useState<string>('Puskesmas Mlati II');
  const [activeFacilityType, setActiveFacilityType] = useState<string>('FKTP Sleman');
  const lastKnownNameRef = useRef<string>(currentUser?.fullName || '');
  if (currentUser?.fullName) {
    lastKnownNameRef.current = currentUser.fullName;
  }

  const isDoctorRole =
    currentRole === 'dokter' ||
    currentUser?.role === 'DOKTER' ||
    currentUser?.role === 'OPHTHALMOLOGIST' ||
    currentUser?.role?.toLowerCase()?.includes('dokter') ||
    currentUser?.role?.toLowerCase()?.includes('ophthalmologist') ||
    currentUser?.role?.toLowerCase()?.includes('spesialis');

  useEffect(() => {
    try {
      const stored = localStorage.getItem('retiva_active_facility');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed.name) setActiveHospital(parsed.name);
        if (parsed.type) setActiveFacilityType(parsed.type);
      } else if (currentUser?.hospital) {
        setActiveHospital(currentUser.hospital);
        setActiveFacilityType(currentUser.facilityType || (currentRole === 'dokter' ? 'RS Mata Rujukan' : 'FKTP Mitra'));
      } else if (currentRole === 'dokter') {
        setActiveHospital('RS Mata Dr. Yap');
        setActiveFacilityType('RS Khusus Mata Tipe A');
      }
    } catch (_) {}
  }, [currentUser, currentRole]);

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

    const fetchSosCount = async () => {
      try {
        const res = await fetch('/api/v1/sos/incidents?status=ACTIVE');
        if (res.ok) {
          const json = await res.json();
          setActiveSosCount(json.stats?.active || (json.data || []).length || 0);
        }
      } catch {
        // Fallback
      }
    };

    updateCount();
    fetchSosCount();
    window.addEventListener('storage', updateCount);
    const interval = setInterval(fetchSosCount, 15000);
    return () => {
      window.removeEventListener('storage', updateCount);
      clearInterval(interval);
    };
  }, [activeTab]);

  const handleNavClick = (tab: string) => {
    onTabChange(tab);
    if (onCloseMobile) {
      onCloseMobile();
    }
  };

  return (
    <aside className={`admin-sidebar ${isOpenMobile ? 'mobile-open' : ''}`}>
      <div>
        {/* Header & Brand */}
        <div className="admin-sidebar-header">
          <div className="admin-brand" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
              <Image
                src="/images/logo/logo-white.png"
                alt="Logo RETIVA"
                width={34}
                height={30}
                style={{
                  objectFit: 'contain',
                  width: '34px',
                  height: '30px',
                  filter: 'brightness(0) invert(1) drop-shadow(0 2px 10px rgba(255,255,255,0.25))',
                }}
                priority
              />
              <span
                className="admin-brand-name"
                style={{
                  fontSize: '1.25rem',
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
            {onCloseMobile && (
              <button
                type="button"
                className="admin-sidebar-mobile-close"
                onClick={onCloseMobile}
                title="Tutup Menu"
                aria-label="Tutup Menu"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
            )}
          </div>

          {/* Active Facility Context */}
          <div className="admin-facility-box">
            <div className="admin-facility-name">{currentUser?.hospital || activeHospital}</div>
            <div className="admin-facility-type">
              <span>{currentUser?.facilityType || activeFacilityType}</span>
            </div>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="admin-sidebar-nav" style={{ padding: '0.85rem 0.75rem', display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
          {/* Main Menu: Dashboard */}
          <button
            type="button"
            className={`admin-nav-btn ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => handleNavClick('dashboard')}
          >
            <div className="admin-nav-item-left">
              <span className="admin-nav-icon">
                <LayoutDashboardIcon size={18} />
              </span>
              <span>Dashboard &amp; Antrean</span>
            </div>
          </button>

          {/* Main Menu: Portal Telaah Spesialis */}
          <button
            type="button"
            className={`admin-nav-btn ${activeTab === 'review' ? 'active' : ''}`}
            onClick={() => handleNavClick('review')}
          >
            <div className="admin-nav-item-left" style={{ minWidth: 0, overflow: 'hidden' }}>
              <span className="admin-nav-icon">
                <EyeIcon size={18} />
              </span>
              <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Telaah Spesialis</span>
            </div>
            {mounted && reviewCount > 0 && (
              <span
                style={{
                  backgroundColor: activeTab === 'review' ? 'rgba(255, 255, 255, 0.22)' : 'rgba(33, 150, 243, 0.2)',
                  color: activeTab === 'review' ? '#FFFFFF' : '#90CAF9',
                  border: '1px solid rgba(144, 202, 249, 0.4)',
                  padding: '0.12rem 0.5rem',
                  borderRadius: '9999px',
                  fontSize: '0.6875rem',
                  fontWeight: 700,
                  whiteSpace: 'nowrap',
                  flexShrink: 0,
                  marginLeft: '0.4rem',
                }}
              >
                {reviewCount} Kasus
              </span>
            )}
          </button>

          {/* Main Menu: Retiva SOS Emergency Monitoring (Tampilan Disamakan, Badge Tetap Merah) */}
          <button
            type="button"
            className={`admin-nav-btn ${activeTab === 'sos-monitoring' ? 'active' : ''}`}
            onClick={() => handleNavClick('sos-monitoring')}
          >
            <div className="admin-nav-item-left" style={{ minWidth: 0, overflow: 'hidden' }}>
              <span className="admin-nav-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                  <line x1="12" y1="8" x2="12" y2="12" />
                  <line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
              </span>
              <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Monitoring SOS</span>
            </div>
            {mounted && activeSosCount > 0 && (
              <span
                style={{
                  background: '#EF4444',
                  color: '#FFFFFF',
                  padding: '0.12rem 0.5rem',
                  borderRadius: '9999px',
                  fontSize: '0.6875rem',
                  fontWeight: 800,
                  whiteSpace: 'nowrap',
                  flexShrink: 0,
                  marginLeft: '0.4rem',
                  boxShadow: '0 0 8px rgba(239,68,68,0.5)',
                }}
              >
                {activeSosCount} SOS
              </span>
            )}
          </button>

          {/* Group Menu: Master Data */}
          <div style={{ marginTop: '0.85rem', marginBottom: '0.2rem' }}>
            <div className="admin-nav-group-title" style={{ paddingLeft: '0.5rem', paddingBottom: '0.4rem' }}>
              Master Data
            </div>
            {!isDoctorRole && (
              <button
                type="button"
                className={`admin-nav-btn ${activeTab === 'users' ? 'active' : ''}`}
                onClick={() => handleNavClick('users')}
              >
                <div className="admin-nav-item-left">
                  <span className="admin-nav-icon">
                    <UsersIcon size={18} />
                  </span>
                  <span>Pengguna</span>
                </div>
              </button>
            )}
            <button
              type="button"
              className={`admin-nav-btn ${activeTab === 'roles' ? 'active' : ''}`}
              onClick={() => handleNavClick('roles')}
            >
              <div className="admin-nav-item-left">
                <span className="admin-nav-icon">
                  <ShieldCheckIcon size={18} />
                </span>
                <span>Role &amp; Hak Akses</span>
              </div>
            </button>
            <button
              type="button"
              className={`admin-nav-btn ${activeTab === 'care-companion-master' ? 'active' : ''}`}
              onClick={() => handleNavClick('care-companion-master')}
            >
              <div className="admin-nav-item-left">
                <span className="admin-nav-icon">
                  <HeartHandshakeIcon size={18} />
                </span>
                <span>Pendamping Perawatan</span>
              </div>
            </button>
            {!isDoctorRole && (
              <button
                type="button"
                className={`admin-nav-btn ${activeTab === 'facilities-master' ? 'active' : ''}`}
                onClick={() => handleNavClick('facilities-master')}
              >
                <div className="admin-nav-item-left">
                  <span className="admin-nav-icon">
                    <HospitalIcon size={18} />
                  </span>
                  <span>Faskes Rujukan &amp; FKTP</span>
                </div>
              </button>
            )}
          </div>

          {/* Group Menu: Verifikasi (Hanya Admin) */}
          {!isDoctorRole && (
            <div style={{ marginTop: '0.85rem', marginBottom: '0.2rem' }}>
              <div className="admin-nav-group-title" style={{ paddingLeft: '0.5rem', paddingBottom: '0.4rem' }}>
                Verifikasi
              </div>
              <button
                type="button"
                className={`admin-nav-btn ${activeTab === 'doctor-verification' ? 'active' : ''}`}
                onClick={() => handleNavClick('doctor-verification')}
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
          )}
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
