'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
  BellIcon,
  CheckIcon,
  ClockIcon,
  EyeIcon,
  ShieldCheckIcon,
  UserIcon,
  XIcon,
  AlertTriangleIcon,
} from './Icons';

export interface AdminNotification {
  id: string;
  type: 'doctor-verification' | 'clinical-review' | 'system-kki' | 'audit';
  title: string;
  message: string;
  timestamp: string;
  isRead: boolean;
  targetTab: string;
  badgeText?: string;
  badgeType?: 'primary' | 'success' | 'warning' | 'danger';
}

interface AdminNotificationCenterProps {
  onNavigateTab?: (tab: string) => void;
}

export function AdminNotificationCenter({ onNavigateTab }: AdminNotificationCenterProps) {
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [activeFilter, setActiveFilter] = useState<'all' | 'doctor' | 'clinical'>('all');
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Load and sync real notifications from system events & localStorage
  const loadNotifications = () => {
    try {
      // 1. Check pending doctor verifications
      let doctorNotifs: AdminNotification[] = [];
      const storedDoctors = localStorage.getItem('retiva_doctor_verifications');
      if (storedDoctors) {
        const parsedDocs = JSON.parse(storedDoctors);
        if (Array.isArray(parsedDocs)) {
          const pendingDocs = parsedDocs.filter((d: any) => d.status === 'PENDING');
          doctorNotifs = pendingDocs.map((doc: any) => ({
            id: `notif-doc-${doc.id}`,
            type: 'doctor-verification' as const,
            title: 'Permohonan Verifikasi Dokter',
            message: `${doc.fullName} (${doc.subSpecialty || 'Dokter Umum'}) mengajukan kredensial STR ${doc.strNumber} untuk verifikasi faskes ${doc.primaryFacility}.`,
            timestamp: doc.submittedAt || new Date().toISOString(),
            isRead: false,
            targetTab: 'doctor-verification',
            badgeText: doc.kkiCheck === 'MATCHED' ? 'KKI Cocok' : 'Perlu Audit',
            badgeType: doc.kkiCheck === 'MATCHED' ? ('success' as const) : ('warning' as const),
          }));
        }
      }

      // 2. Base clinical and system alerts
      const baseAlerts: AdminNotification[] = [
        {
          id: 'notif-review-01',
          type: 'clinical-review',
          title: 'Kasus Butuh Telaah Spesialis',
          message: 'Citra retina bilateral Pasien Bambang Sudarmono (RM-2026-0891) terindikasi NPDR derajat sedang dan memerlukan adjudikasi.',
          timestamp: new Date(Date.now() - 1000 * 60 * 35).toISOString(),
          isRead: false,
          targetTab: 'review',
          badgeText: 'Prioritas Klinis',
          badgeType: 'warning',
        },
        {
          id: 'notif-kki-01',
          type: 'system-kki',
          title: 'Sinkronisasi Basis Data KKI Aktif',
          message: 'Pangkalan data Konsil Kedokteran Indonesia (KKI) telah terhubung secara otomatis untuk validasi e-STR seumur hidup.',
          timestamp: new Date(Date.now() - 1000 * 60 * 120).toISOString(),
          isRead: true,
          targetTab: 'doctor-verification',
          badgeText: 'SATUSEHAT',
          badgeType: 'primary',
        },
        {
          id: 'notif-audit-01',
          type: 'audit',
          title: 'Log Audit Keamanan & Kepatuhan',
          message: 'Pencatatan kriptografis SHA-256 non-repudiation berjalan normal untuk seluruh riwayat adjudikasi klinis.',
          timestamp: new Date(Date.now() - 1000 * 60 * 300).toISOString(),
          isRead: true,
          targetTab: 'audit',
          badgeText: 'Kepatuhan ISO',
          badgeType: 'success',
        },
      ];

      // Retrieve read IDs from localStorage
      const readIdsStr = localStorage.getItem('retiva_admin_read_notif_ids');
      const readIds: string[] = readIdsStr ? JSON.parse(readIdsStr) : [];

      const combined = [...doctorNotifs, ...baseAlerts].map((n) => ({
        ...n,
        isRead: readIds.includes(n.id) || n.isRead,
      }));

      // Sort newest first
      combined.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      setNotifications(combined);
    } catch {
      // Fallback
    }
  };

  useEffect(() => {
    loadNotifications();

    const handleStorageChange = () => {
      loadNotifications();
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  const markAllAsRead = () => {
    const updated = notifications.map((n) => ({ ...n, isRead: true }));
    setNotifications(updated);
    try {
      const allIds = updated.map((n) => n.id);
      localStorage.setItem('retiva_admin_read_notif_ids', JSON.stringify(allIds));
    } catch {}
  };

  const handleNotificationClick = (notif: AdminNotification) => {
    // Mark this one as read
    const updated = notifications.map((n) => (n.id === notif.id ? { ...n, isRead: true } : n));
    setNotifications(updated);
    try {
      const readIdsStr = localStorage.getItem('retiva_admin_read_notif_ids');
      const readIds: string[] = readIdsStr ? JSON.parse(readIdsStr) : [];
      if (!readIds.includes(notif.id)) {
        readIds.push(notif.id);
        localStorage.setItem('retiva_admin_read_notif_ids', JSON.stringify(readIds));
      }
    } catch {}

    setIsOpen(false);
    if (onNavigateTab && notif.targetTab) {
      onNavigateTab(notif.targetTab);
    }
  };

  const clearNotification = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setNotifications((prev) => prev.filter((n) => n.id !== id));
  };

  const filteredNotifs = notifications.filter((n) => {
    if (activeFilter === 'doctor') return n.type === 'doctor-verification';
    if (activeFilter === 'clinical') return n.type === 'clinical-review' || n.type === 'system-kki';
    return true;
  });

  const getFormatTime = (isoString: string) => {
    try {
      const date = new Date(isoString);
      const diffMs = Date.now() - date.getTime();
      const diffMins = Math.floor(diffMs / (1000 * 60));
      if (diffMins < 1) return 'Baru saja';
      if (diffMins < 60) return `${diffMins} mnt lalu`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours} jam lalu`;
      return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
    } catch {
      return 'Hari ini';
    }
  };

  return (
    <div style={{ position: 'relative' }} ref={dropdownRef}>
      {/* Notification Bell Button */}
      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        style={{
          width: '38px',
          height: '38px',
          borderRadius: '50%',
          backgroundColor: isOpen ? '#E3F2FD' : '#FFFFFF',
          border: `1.5px solid ${isOpen ? '#2196F3' : '#E2E8F0'}`,
          color: isOpen ? '#0D47A1' : '#475569',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer',
          position: 'relative',
          transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
          boxShadow: isOpen ? '0 0 0 3px rgba(33, 150, 243, 0.15)' : '0 1px 2px rgba(0, 0, 0, 0.05)',
        }}
        title="Pusat Notifikasi Admin"
        aria-label="Pusat Notifikasi Admin"
      >
        <BellIcon size={19} style={{ color: isOpen ? '#0D47A1' : '#475569' }} />

        {/* Unread Counter Badge */}
        {unreadCount > 0 && (
          <span
            style={{
              position: 'absolute',
              top: '-3px',
              right: '-3px',
              backgroundColor: '#DC2626',
              color: '#FFFFFF',
              fontSize: '0.65rem',
              fontWeight: 800,
              minWidth: '18px',
              height: '18px',
              borderRadius: '9999px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '0 4px',
              boxShadow: '0 2px 5px rgba(220, 38, 38, 0.4)',
              border: '2px solid #FFFFFF',
              animation: 'pulse 2s infinite',
            }}
          >
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {/* Notification Center Dropdown Panel */}
      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: 'calc(100% + 10px)',
            right: 0,
            width: '400px',
            maxWidth: '92vw',
            backgroundColor: '#FFFFFF',
            borderRadius: '14px',
            boxShadow: '0 20px 45px -10px rgba(15, 23, 42, 0.18), 0 0 0 1px rgba(0, 0, 0, 0.06)',
            border: '1px solid #E2E8F0',
            zIndex: 1000,
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
            animation: 'fadeInUp 0.2s ease',
          }}
        >
          {/* Header */}
          <div
            style={{
              padding: '1rem 1.25rem',
              borderBottom: '1px solid #F1F5F9',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              backgroundColor: '#F8FAFC',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <div
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '6px',
                  backgroundColor: '#E3F2FD',
                  color: '#0D47A1',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <BellIcon size={15} />
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '0.9rem', fontWeight: 800, color: '#0F172A' }}>
                  Pusat Notifikasi
                </h4>
                <div style={{ fontSize: '0.7rem', color: '#64748B', marginTop: '0.1rem' }}>
                  {unreadCount > 0 ? `${unreadCount} pemberitahuan baru` : 'Semua telah dibaca'}
                </div>
              </div>
            </div>

            {unreadCount > 0 && (
              <button
                type="button"
                onClick={markAllAsRead}
                style={{
                  background: 'none',
                  border: 'none',
                  fontSize: '0.725rem',
                  fontWeight: 700,
                  color: '#0D47A1',
                  cursor: 'pointer',
                  padding: '0.25rem 0.5rem',
                  borderRadius: '4px',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.25rem',
                }}
              >
                <CheckIcon size={12} />
                <span>Tandai dibaca</span>
              </button>
            )}
          </div>

          {/* Filter Pills */}
          <div
            style={{
              display: 'flex',
              padding: '0.5rem 1rem',
              gap: '0.35rem',
              backgroundColor: '#FFFFFF',
              borderBottom: '1px solid #F1F5F9',
            }}
          >
            <button
              type="button"
              onClick={() => setActiveFilter('all')}
              style={{
                border: 'none',
                padding: '0.25rem 0.65rem',
                borderRadius: '6px',
                fontSize: '0.725rem',
                fontWeight: 700,
                cursor: 'pointer',
                backgroundColor: activeFilter === 'all' ? '#0D47A1' : '#F1F5F9',
                color: activeFilter === 'all' ? '#FFFFFF' : '#64748B',
                transition: 'all 0.15s ease',
              }}
            >
              Semua ({notifications.length})
            </button>
            <button
              type="button"
              onClick={() => setActiveFilter('doctor')}
              style={{
                border: 'none',
                padding: '0.25rem 0.65rem',
                borderRadius: '6px',
                fontSize: '0.725rem',
                fontWeight: 700,
                cursor: 'pointer',
                backgroundColor: activeFilter === 'doctor' ? '#0D47A1' : '#F1F5F9',
                color: activeFilter === 'doctor' ? '#FFFFFF' : '#64748B',
                transition: 'all 0.15s ease',
              }}
            >
              Verifikasi Dokter ({notifications.filter((n) => n.type === 'doctor-verification').length})
            </button>
            <button
              type="button"
              onClick={() => setActiveFilter('clinical')}
              style={{
                border: 'none',
                padding: '0.25rem 0.65rem',
                borderRadius: '6px',
                fontSize: '0.725rem',
                fontWeight: 700,
                cursor: 'pointer',
                backgroundColor: activeFilter === 'clinical' ? '#0D47A1' : '#F1F5F9',
                color: activeFilter === 'clinical' ? '#FFFFFF' : '#64748B',
                transition: 'all 0.15s ease',
              }}
            >
              Klinis ({notifications.filter((n) => n.type === 'clinical-review' || n.type === 'system-kki').length})
            </button>
          </div>

          {/* Notification List Scroll Area */}
          <div style={{ maxHeight: '340px', overflowY: 'auto' }}>
            {filteredNotifs.length === 0 ? (
              <div style={{ padding: '2.5rem 1.5rem', textAlign: 'center', color: '#94A3B8' }}>
                <div
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: '#F1F5F9',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    margin: '0 auto 0.65rem auto',
                    color: '#94A3B8',
                  }}
                >
                  <BellIcon size={20} />
                </div>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#475569' }}>
                  Tidak ada notifikasi
                </div>
                <div style={{ fontSize: '0.725rem', marginTop: '0.2rem' }}>
                  Pemberitahuan aktivitas verifikasi dan telaah klinis akan muncul di sini.
                </div>
              </div>
            ) : (
              filteredNotifs.map((notif) => {
                const getIcon = () => {
                  switch (notif.type) {
                    case 'doctor-verification':
                      return <UserIcon size={15} style={{ color: '#0D47A1' }} />;
                    case 'clinical-review':
                      return <EyeIcon size={15} style={{ color: '#D97706' }} />;
                    case 'system-kki':
                      return <CheckIcon size={15} style={{ color: '#059669' }} />;
                    default:
                      return <ShieldCheckIcon size={15} style={{ color: '#4F46E5' }} />;
                  }
                };

                const getIconBg = () => {
                  switch (notif.type) {
                    case 'doctor-verification':
                      return '#E3F2FD';
                    case 'clinical-review':
                      return '#FEF3C7';
                    case 'system-kki':
                      return '#ECFDF5';
                    default:
                      return '#EEF2FF';
                  }
                };

                return (
                  <div
                    key={notif.id}
                    onClick={() => handleNotificationClick(notif)}
                    style={{
                      padding: '0.85rem 1.15rem',
                      borderBottom: '1px solid #F1F5F9',
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: '0.75rem',
                      cursor: 'pointer',
                      backgroundColor: notif.isRead ? '#FFFFFF' : 'rgba(227, 242, 253, 0.25)',
                      borderLeft: notif.isRead ? '3px solid transparent' : '3px solid #2196F3',
                      transition: 'background-color 0.15s ease',
                      position: 'relative',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = notif.isRead ? '#F8FAFC' : 'rgba(227, 242, 253, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = notif.isRead ? '#FFFFFF' : 'rgba(227, 242, 253, 0.25)';
                    }}
                  >
                    {/* Icon Category */}
                    <div
                      style={{
                        width: '32px',
                        height: '32px',
                        borderRadius: '8px',
                        backgroundColor: getIconBg(),
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                        marginTop: '2px',
                      }}
                    >
                      {getIcon()}
                    </div>

                    {/* Content */}
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.5rem', marginBottom: '0.15rem' }}>
                        <span style={{ fontSize: '0.8rem', fontWeight: notif.isRead ? 600 : 800, color: '#0F172A' }}>
                          {notif.title}
                        </span>
                        <span style={{ fontSize: '0.675rem', color: '#94A3B8', whiteSpace: 'nowrap' }}>
                          {getFormatTime(notif.timestamp)}
                        </span>
                      </div>

                      <p style={{ margin: 0, fontSize: '0.75rem', color: '#475569', lineHeight: 1.45 }}>
                        {notif.message}
                      </p>

                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '0.45rem' }}>
                        {notif.badgeText && (
                          <span
                            style={{
                              fontSize: '0.65rem',
                              fontWeight: 700,
                              padding: '0.1rem 0.45rem',
                              borderRadius: '4px',
                              backgroundColor:
                                notif.badgeType === 'success'
                                  ? '#ECFDF5'
                                  : notif.badgeType === 'warning'
                                  ? '#FEF3C7'
                                  : '#E3F2FD',
                              color:
                                notif.badgeType === 'success'
                                  ? '#065F46'
                                  : notif.badgeType === 'warning'
                                  ? '#92400E'
                                  : '#0D47A1',
                              border: `1px solid ${
                                notif.badgeType === 'success'
                                  ? '#A7F3D0'
                                  : notif.badgeType === 'warning'
                                  ? '#FDE68A'
                                  : '#BBDEFB'
                              }`,
                            }}
                          >
                            {notif.badgeText}
                          </span>
                        )}

                        <span
                          style={{
                            fontSize: '0.7rem',
                            fontWeight: 700,
                            color: '#2196F3',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '0.2rem',
                          }}
                        >
                          Lihat detail →
                        </span>
                      </div>
                    </div>

                    {/* Quick Dismiss button */}
                    <button
                      type="button"
                      onClick={(e) => clearNotification(notif.id, e)}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: '#CBD5E1',
                        cursor: 'pointer',
                        padding: '2px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        position: 'absolute',
                        top: '8px',
                        right: '8px',
                      }}
                      title="Hapus notifikasi"
                    >
                      <XIcon size={12} />
                    </button>
                  </div>
                );
              })
            )}
          </div>

          {/* Footer Action */}
          <div
            style={{
              padding: '0.65rem 1rem',
              backgroundColor: '#F8FAFC',
              borderTop: '1px solid #F1F5F9',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                if (onNavigateTab) onNavigateTab('doctor-verification');
              }}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '0.725rem',
                fontWeight: 700,
                color: '#0D47A1',
                cursor: 'pointer',
                padding: 0,
              }}
            >
              Lihat Antrean Verifikasi Dokter
            </button>
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                if (onNavigateTab) onNavigateTab('audit');
              }}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '0.725rem',
                fontWeight: 600,
                color: '#64748B',
                cursor: 'pointer',
                padding: 0,
              }}
            >
              Buka Log Audit
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
