import React from 'react';
import { EyeIcon, ShieldCheckIcon, HospitalIcon, UserIcon } from './Icons';

interface AppHeaderProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  reviewCount?: number;
}

export function AppHeader({ activeTab, onTabChange, reviewCount = 5 }: AppHeaderProps) {
  const tabs = [
    { id: 'dashboard', label: 'Dashboard & Antrean' },
    { id: 'screening', label: 'Skrining Baru (OD/OS)' },
    { id: 'review', label: 'Tinjauan Dokter', badge: reviewCount },
    { id: 'patients', label: 'Direktori Pasien' },
    { id: 'referrals', label: 'Rujukan & Faskes' },
    { id: 'audit', label: 'Audit & Tata Kelola' },
  ];

  return (
    <header className="top-bar">
      <div className="top-bar-inner">
        <div className="brand-section">
          <div className="brand-logo-mark">
            <EyeIcon size={20} />
          </div>
          <div>
            <div className="brand-title">RETIVA</div>
            <div className="brand-tagline">Skrining Retinopati Diabetik Nasional</div>
          </div>
          <div className="header-status-badge">
            <ShieldCheckIcon size={14} className="text-teal" />
            <span>Perdami & ADA 2024</span>
          </div>
        </div>

        <div className="header-meta">
          <div className="facility-badge">
            <div className="facility-name">Puskesmas Mlati II — Sleman</div>
            <div className="facility-role">Fasilitas Kesehatan Tingkat Pertama (FKTP)</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.35rem 0.75rem', backgroundColor: 'var(--slate-100)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--slate-200)' }}>
            <UserIcon size={16} />
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontSize: '0.75rem', fontWeight: 600 }}>dr. Hendra, Sp.M</div>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Ophthalmologist Reviewer</div>
            </div>
          </div>
        </div>
      </div>

      <nav className="nav-bar">
        <div className="nav-bar-inner">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              className={`nav-item ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => onTabChange(tab.id)}
            >
              <span>{tab.label}</span>
              {tab.badge !== undefined && tab.badge > 0 && (
                <span className="badge badge-review" style={{ fontSize: '0.7rem', padding: '0.1rem 0.45rem' }}>
                  {tab.badge}
                </span>
              )}
            </button>
          ))}
        </div>
      </nav>
    </header>
  );
}
