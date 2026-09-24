import React from 'react';
import {
  EyeIcon,
  LayoutDashboardIcon,
  ClockIcon,
  UsersIcon,
  HospitalIcon,
  LockIcon,
  ShieldCheckIcon,
} from './Icons';

interface AdminSidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  reviewCount?: number;
  patientCount?: number;
}

export function AdminSidebar({
  activeTab,
  onTabChange,
  reviewCount = 0,
  patientCount = 0,
}: AdminSidebarProps) {
  const navSections = [
    {
      title: 'Alur Skrining',
      items: [
        {
          id: 'dashboard',
          label: 'Dashboard & Antrean',
          icon: <LayoutDashboardIcon size={16} />,
        },
        {
          id: 'screening',
          label: 'Skrining Baru (OD/OS)',
          icon: <EyeIcon size={16} />,
        },
        {
          id: 'review',
          label: 'Telaah Spesialis Mata',
          icon: <ClockIcon size={16} />,
          badge: reviewCount,
          badgeType: 'review',
        },
      ],
    },
    {
      title: 'Manajemen Rekam Medis',
      items: [
        {
          id: 'patients',
          label: 'Direktori Pasien',
          icon: <UsersIcon size={16} />,
          badge: patientCount > 0 ? patientCount : undefined,
          badgeType: 'neutral',
        },
        {
          id: 'referrals',
          label: 'Faskes Rujukan & BPJS',
          icon: <HospitalIcon size={16} />,
        },
      ],
    },
    {
      title: 'Keamanan & Kepatuhan',
      items: [
        {
          id: 'audit',
          label: 'Audit Trail & Model',
          icon: <LockIcon size={16} />,
        },
      ],
    },
  ];

  return (
    <aside className="admin-sidebar">
      <div>
        {/* Header & Brand */}
        <div className="admin-sidebar-header">
          <div className="admin-brand">
            <div className="admin-brand-icon">
              <EyeIcon size={20} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <span className="admin-brand-name">RETIVA</span>
                <span className="admin-brand-badge">CDSS</span>
              </div>
              <div style={{ fontSize: '0.6875rem', color: '#94a3b8' }}>Skrining Retinopati Diabetik</div>
            </div>
          </div>

          {/* Active Facility Context */}
          <div className="admin-facility-box">
            <div className="admin-facility-name">Puskesmas Mlati II</div>
            <div className="admin-facility-type">
              <span className="status-dot-pulse" />
              <span>FKTP Sleman • Terhubung SatuSehat</span>
            </div>
          </div>
        </div>

        {/* Navigation Groups */}
        <nav className="admin-sidebar-nav">
          {navSections.map((section) => (
            <div key={section.title} style={{ marginBottom: '0.5rem' }}>
              <div className="admin-nav-group-title">{section.title}</div>
              {section.items.map((item) => {
                const isActive = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    className={`admin-nav-btn ${isActive ? 'active' : ''}`}
                    onClick={() => onTabChange(item.id)}
                  >
                    <div className="admin-nav-item-left">
                      <span style={{ color: isActive ? '#2dd4bf' : '#94a3b8' }}>
                        {item.icon}
                      </span>
                      <span>{item.label}</span>
                    </div>

                    {item.badge !== undefined && item.badge > 0 && (
                      <span
                        className={`badge ${item.badgeType === 'review' ? 'badge-review' : 'badge-neutral'}`}
                        style={{ fontSize: '0.6875rem', padding: '0.1rem 0.45rem' }}
                      >
                        {item.badge}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          ))}
        </nav>
      </div>

      {/* Operator User Card */}
      <div className="admin-sidebar-footer">
        <div className="admin-user-card">
          <div className="admin-user-avatar">
            <span>DH</span>
          </div>
          <div className="admin-user-info">
            <div className="admin-user-name">dr. Hendra, Sp.M</div>
            <div className="admin-user-role">Spesialis Mata (Reviewer)</div>
          </div>
          <div title="Terverifikasi SIP Kemenkes" style={{ color: '#2dd4bf' }}>
            <ShieldCheckIcon size={16} />
          </div>
        </div>
      </div>
    </aside>
  );
}
