import React, { useState, useEffect } from 'react';
import {
  UsersIcon,
  UserIcon,
  SearchIcon,
  ShieldCheckIcon,
  StethoscopeIcon,
  CheckIcon,
  XIcon,
  PlusIcon,
  EditIcon,
  TrashIcon,
  RotateCwIcon,
  AlertTriangleIcon,
  MailIcon,
  PhoneIcon,
  HospitalIcon,
} from './Icons';

interface DbUser {
  id: string;
  email: string;
  fullName: string;
  role: string;
  phoneNumber?: string | null;
  isActive: boolean;
  facilityId?: string | null;
  hospital?: string;
  facilityType?: string;
  createdAt: string;
  updatedAt?: string;
  deletedAt?: string | null;
}

interface RoleDefinition {
  id: string;
  code: string;
  displayName: string;
  category: string;
  description: string;
  permissions: string[];
  badgeColor: string;
  badgeBg: string;
  badgeBorder: string;
}

interface FacilityOption {
  id: string;
  name: string;
  category: 'FKTP' | 'FKRTL';
  categoryLabel?: string;
  address?: string;
}

const DEFAULT_FACILITIES: FacilityOption[] = [
  { id: 'fac-mlati-02', name: 'Puskesmas Mlati II (FKTP)', category: 'FKTP', categoryLabel: 'FKTP (Puskesmas & Klinik Tingkat Pertama)' },
  { id: 'fac-sleman-01', name: 'Puskesmas Sleman (FKTP)', category: 'FKTP', categoryLabel: 'FKTP (Puskesmas & Klinik Tingkat Pertama)' },
  { id: 'fac-depok-01', name: 'Puskesmas Depok I (FKTP)', category: 'FKTP', categoryLabel: 'FKTP (Puskesmas & Klinik Tingkat Pertama)' },
  { id: 'fac-gamping-01', name: 'Puskesmas Gamping I (FKTP)', category: 'FKTP', categoryLabel: 'FKTP (Puskesmas & Klinik Tingkat Pertama)' },
  { id: 'fac-yap-01', name: 'RS Mata Dr. Yap Yogyakarta', category: 'FKRTL', categoryLabel: 'FKRTL (RS Khusus Mata Tipe B)' },
  { id: 'fac-sardjito-01', name: 'RSUP Dr. Sardjito (Pusat Subspesialis Retina FKRTL)', category: 'FKRTL', categoryLabel: 'FKRTL (Rujukan Nasional Tipe A)' },
  { id: 'fac-rsa-ugm-01', name: 'RS Akademik UGM (RSA UGM)', category: 'FKRTL', categoryLabel: 'FKRTL (RS Rujukan Tipe B)' },
  { id: 'fac-rsud-sleman-01', name: 'RSUD Sleman (FKRTL - Tipe B)', category: 'FKRTL', categoryLabel: 'FKRTL (RSUD Rujukan Tipe B)' },
  { id: 'fac-bethesda-01', name: 'RS Bethesda Yogyakarta (FKRTL - Tipe B)', category: 'FKRTL', categoryLabel: 'FKRTL (RS Rujukan Tipe B)' },
];

interface UsersMasterViewProps {
  initialTab?: 'users' | 'roles';
}

export function UsersMasterView({ initialTab = 'users' }: UsersMasterViewProps) {
  const [users, setUsers] = useState<DbUser[]>([]);
  const [facilities, setFacilities] = useState<FacilityOption[]>(DEFAULT_FACILITIES);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  const [viewMode, setViewMode] = useState<'table' | 'cards'>('cards');
  const [activeSubTab, setActiveSubTab] = useState<'users' | 'roles'>(initialTab);

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);
  const [editingUser, setEditingUser] = useState<DbUser | null>(null);
  const [deletingUser, setDeletingUser] = useState<DbUser | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [alertFeedback, setAlertFeedback] = useState<{ message: string; type: 'success' | 'danger' } | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phoneNumber: '',
    role: 'ADMIN',
    password: '',
    hospital: 'Puskesmas Mlati II (FKTP)',
    facilityType: 'FKTP Sleman',
    isActive: true,
  });

  useEffect(() => {
    setActiveSubTab(initialTab);
  }, [initialTab]);

  // Master 3 Roles Definition
  const SYSTEM_ROLES: RoleDefinition[] = [
    {
      id: 'role-admin',
      code: 'ADMIN',
      displayName: 'Admin',
      category: 'Administrator Sistem',
      description: 'Pengelola penuh platform RETIVA, manajemen operasional, data master pengguna, serta pemantauan audit trail.',
      permissions: [
        'Manajemen Master Data',
        'Akses Seluruh Antrean Skrining',
        'Audit & Model Governance',
        'Pengaturan Faskes Rujukan & BPJS',
      ],
      badgeColor: '#0D47A1',
      badgeBg: '#E3F2FD',
      badgeBorder: '#90CAF9',
    },
    {
      id: 'role-dokter',
      code: 'DOKTER',
      displayName: 'Dokter',
      category: 'Spesialis Mata (Ophthalmologist)',
      description: 'Tenaga medis spesialis mata yang bertugas memvalidasi hasil inferensi AI, membaca citra fundus bilateral, dan adjudikasi rujukan.',
      permissions: [
        'Portal Telaah Spesialis Mata',
        'Inspeksi Peta Grad-CAM AI',
        'Adjudikasi & Verifikasi Diagnostik',
        'Penerbitan Surat Rujukan FKRTL',
      ],
      badgeColor: '#0284C7',
      badgeBg: '#F0F9FF',
      badgeBorder: '#BAE6FD',
    },
    {
      id: 'role-pengguna',
      code: 'PENGGUNA',
      displayName: 'Pengguna',
      category: 'Pasien / Masyarakat',
      description: 'Pasien diabetes melitus atau masyarakat yang menerima layanan skrining retina berkala dan mengakses rekam medis mandiri.',
      permissions: [
        'Akses Rekam Medis Retina Mandiri',
        'Riwayat Hasil Skrining Terkini',
        'Pemantauan Status Rujukan BPJS',
        'Edu-Klinis Pencegahan Retinopati',
      ],
      badgeColor: '#059669',
      badgeBg: '#ECFDF5',
      badgeBorder: '#A7F3D0',
    },
  ];

  const fetchFacilities = async () => {
    try {
      const res = await fetch('/api/v1/master/facilities');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data) && json.data.length > 0) {
          const mapped: FacilityOption[] = json.data.map((f: any) => {
            const isFKTP =
              f.category === 'FKTP' ||
              f.name.toLowerCase().includes('puskesmas') ||
              f.name.toLowerCase().includes('klinik') ||
              f.name.toLowerCase().includes('fktp');
            return {
              id: f.id,
              name: f.name,
              category: isFKTP ? 'FKTP' : 'FKRTL',
              categoryLabel: isFKTP ? 'FKTP (Puskesmas & Klinik Tingkat Pertama)' : 'FKRTL (Rumah Sakit Rujukan Vitreoretina)',
              address: f.address,
            };
          });
          setFacilities(mapped);
          return;
        }
      }
    } catch (e) {
      console.warn('Gagal memuat faskes master dari API:', e);
    }
  };

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/v1/users');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          const mapped = json.data.map((u: any) => ({
            ...u,
            hospital: u.hospital || (u.role === 'DOKTER' || u.role === 'OPHTHALMOLOGIST' ? 'RS Mata Dr. Yap Yogyakarta' : 'Puskesmas Mlati II (FKTP)'),
            facilityType: u.facilityType || (u.hospital?.includes('FKTP') || u.hospital?.includes('Puskesmas') ? 'FKTP Sleman' : 'FKRTL Rujukan'),
          }));
          setUsers(mapped);
          return;
        }
      }
    } catch (e) {
      console.error('Gagal mengambil data pengguna dari API:', e);
    } finally {
      setIsLoading(false);
    }

    // Fallback data jika API offline
    setUsers([
      {
        id: '8d70d02f-5159-4dba-95a8-b691b085301d',
        email: 'admin@gmail.com',
        fullName: 'Administrator RETIVA',
        role: 'ADMIN',
        phoneNumber: '081234567890',
        isActive: true,
        hospital: 'Puskesmas Mlati II (FKTP)',
        facilityType: 'FKTP Sleman',
        createdAt: '2026-09-28T02:59:47.104Z',
      },
      {
        id: 'cad17074-adc5-40da-85e7-d5ca616ffd69',
        email: 'guntoroloa@gmail.com',
        fullName: 'Guntoro Loa',
        role: 'ADMIN',
        phoneNumber: '081298765432',
        isActive: true,
        hospital: 'Puskesmas Mlati II (FKTP)',
        facilityType: 'FKTP Sleman',
        createdAt: '2026-09-28T02:59:47.218Z',
      },
      {
        id: 'e1075f92-563d-4cba-a567-33fa123011a9',
        email: 'tioramadhan3106@gmail.com',
        fullName: 'dr. Yunani Setyandriana, Sp.M',
        role: 'DOKTER',
        phoneNumber: '0895358641445',
        isActive: true,
        hospital: 'RS Mata Dr. Yap Yogyakarta',
        facilityType: 'RS Khusus Mata Tipe B',
        createdAt: '2026-09-28T03:00:00.000Z',
      },
    ]);
  };

  useEffect(() => {
    fetchUsers();
    fetchFacilities();
  }, []);

  const showAlert = (message: string, type: 'success' | 'danger') => {
    setAlertFeedback({ message, type });
    setTimeout(() => {
      setAlertFeedback(null);
    }, 4000);
  };

  const formatRoleLabel = (roleStr: string) => {
    const upper = (roleStr || '').toUpperCase();
    if (upper === 'ADMIN') return 'Admin';
    if (upper === 'DOKTER' || upper === 'OPHTHALMOLOGIST' || upper === 'HEALTHCARE_WORKER') return 'Dokter';
    return 'Pengguna';
  };

  const getRoleStyle = (roleStr: string) => {
    const upper = (roleStr || '').toUpperCase();
    if (upper === 'ADMIN') {
      return {
        color: '#0D47A1',
        backgroundColor: '#E3F2FD',
        border: '1px solid #90CAF9',
      };
    }
    if (upper === 'DOKTER' || upper === 'OPHTHALMOLOGIST' || upper === 'HEALTHCARE_WORKER') {
      return {
        color: '#0284C7',
        backgroundColor: '#F0F9FF',
        border: '1px solid #BAE6FD',
      };
    }
    return {
      color: '#059669',
      backgroundColor: '#ECFDF5',
      border: '1px solid #A7F3D0',
    };
  };

  const getRoleIcon = (roleStr: string, size = 20, style?: React.CSSProperties) => {
    const upper = (roleStr || '').toUpperCase();
    if (upper === 'ADMIN') {
      return <ShieldCheckIcon size={size} style={style} />;
    }
    if (upper === 'DOKTER' || upper === 'OPHTHALMOLOGIST' || upper === 'HEALTHCARE_WORKER') {
      return <StethoscopeIcon size={size} style={style} />;
    }
    return <UserIcon size={size} style={style} />;
  };

  const handleOpenAdd = () => {
    const defaultFac = facilities.find((f) => f.category === 'FKTP') || facilities[0];
    const defaultHosp = defaultFac ? defaultFac.name : 'Puskesmas Mlati II (FKTP)';
    const defaultType = defaultFac ? (defaultFac.category === 'FKTP' ? 'FKTP Sleman' : 'FKRTL Rujukan') : 'FKTP Sleman';

    setFormData({
      fullName: '',
      email: '',
      phoneNumber: '',
      role: 'ADMIN',
      password: '',
      hospital: defaultHosp,
      facilityType: defaultType,
      isActive: true,
    });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (user: DbUser) => {
    setEditingUser(user);
    const roleUpper = formatRoleLabel(user.role).toUpperCase();
    const defaultFac = roleUpper === 'DOKTER'
      ? facilities.find((f) => f.category === 'FKRTL') || facilities[0]
      : facilities.find((f) => f.category === 'FKTP') || facilities[0];
    const defaultHosp = defaultFac ? defaultFac.name : 'Puskesmas Mlati II (FKTP)';
    const defaultType = defaultFac ? (defaultFac.category === 'FKTP' ? 'FKTP Sleman' : 'FKRTL Rujukan') : 'FKTP Sleman';

    setFormData({
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber || '',
      role: roleUpper,
      password: '',
      hospital: user.hospital || defaultHosp,
      facilityType: user.facilityType || defaultType,
      isActive: user.isActive,
    });
  };

  const handleSaveAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.fullName || !formData.email) {
      showAlert('Nama lengkap dan email wajib diisi.', 'danger');
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        if (formData.hospital && (formData.role === 'ADMIN' || formData.role === 'DOKTER')) {
          try {
            localStorage.setItem(
              'retiva_active_facility',
              JSON.stringify({
                name: formData.hospital,
                type: formData.facilityType || (formData.role === 'DOKTER' ? 'RS Khusus Mata Tipe A' : 'FKTP Sleman'),
              })
            );
            window.dispatchEvent(new Event('storage'));
          } catch {}
        }
        showAlert('Pengguna baru berhasil ditambahkan.', 'success');
        setIsAddModalOpen(false);
        fetchUsers();
      } else {
        showAlert(data.error?.message || 'Gagal menambahkan pengguna.', 'danger');
      }
    } catch (err: any) {
      showAlert('Terjadi kesalahan jaringan.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;

    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/users/${editingUser.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        if (formData.hospital && (formData.role === 'ADMIN' || formData.role === 'DOKTER')) {
          try {
            localStorage.setItem(
              'retiva_active_facility',
              JSON.stringify({
                name: formData.hospital,
                type: formData.facilityType || (formData.role === 'DOKTER' ? 'RS Khusus Mata Tipe A' : 'FKTP Sleman'),
              })
            );
            window.dispatchEvent(new Event('storage'));
          } catch {}
        }
        showAlert('Data pengguna berhasil diperbarui.', 'success');
        setEditingUser(null);
        fetchUsers();
      } else {
        showAlert(data.error?.message || 'Gagal memperbarui pengguna.', 'danger');
      }
    } catch (err: any) {
      showAlert('Terjadi kesalahan jaringan.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deletingUser) return;

    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/users/${deletingUser.id}`, {
        method: 'DELETE',
      });
      const data = await res.json();
      if (res.ok && data.success) {
        showAlert(`Pengguna ${deletingUser.fullName} berhasil di-soft delete (dinonaktifkan & diarsipkan).`, 'success');
        setDeletingUser(null);
        fetchUsers();
      } else {
        showAlert(data.error?.message || 'Gagal menghapus pengguna.', 'danger');
      }
    } catch (err: any) {
      showAlert('Terjadi kesalahan jaringan.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRestoreUser = async (user: DbUser) => {
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/users/${user.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'restore' }),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        showAlert(`Akun ${user.fullName} berhasil dipulihkan (Aktif kembali).`, 'success');
        fetchUsers();
      } else {
        showAlert(data.error?.message || 'Gagal memulihkan pengguna.', 'danger');
      }
    } catch {
      showAlert('Terjadi kesalahan jaringan.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Generate a clean, tidy, sequential user ID (e.g. RTV-0001, RTV-0002)
  const getUserDisplayId = (user: DbUser | null | undefined): string => {
    if (!user || !user.id) return 'RTV-0001';

    // If ID is already a custom structured code, return as-is
    if (/^RTV-\d{3,4}$/.test(user.id) || /^[A-Z]{3}-\d{3,4}$/.test(user.id)) {
      return user.id;
    }

    // Sort chronologically by createdAt (ascending) to maintain stable, persistent sequential numbering
    const sorted = [...users].sort((a, b) => {
      const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      if (timeA !== timeB) return timeA - timeB;
      return a.id.localeCompare(b.id);
    });

    const index = sorted.findIndex((u) => u.id === user.id);
    const seqNum = index !== -1 ? index + 1 : 1;
    return `RTV-${String(seqNum).padStart(4, '0')}`;
  };

  // Active vs Soft-Deleted
  const activeUsers = users.filter((u) => !u.deletedAt);
  const deletedUsers = users.filter((u) => !!u.deletedAt);

  const totalCount = activeUsers.length;
  const adminCount = activeUsers.filter((u) => formatRoleLabel(u.role) === 'Admin').length;
  const doctorCount = activeUsers.filter((u) => formatRoleLabel(u.role) === 'Dokter').length;
  const patientCount = activeUsers.filter((u) => formatRoleLabel(u.role) === 'Pengguna').length;
  const trashCount = deletedUsers.length;

  const filteredUsers = users.filter((u) => {
    // If filter is TRASH, show soft-deleted accounts
    if (roleFilter === 'TRASH') {
      if (!u.deletedAt) return false;
    } else {
      // By default, only show active (non-deleted) accounts
      if (u.deletedAt) return false;
      if (roleFilter !== 'ALL') {
        const userRoleNorm = formatRoleLabel(u.role).toUpperCase();
        if (userRoleNorm !== roleFilter.toUpperCase()) return false;
      }
    }

    const displayId = getUserDisplayId(u);
    const matchesSearch =
      searchQuery.trim() === '' ||
      u.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      displayId.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (u.phoneNumber && u.phoneNumber.includes(searchQuery));

    return matchesSearch;
  });

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', paddingBottom: '3rem' }}>
      {/* Alert Feedback Toast */}
      {alertFeedback && (
        <div
          style={{
            marginBottom: '1rem',
            padding: '0.75rem 1rem',
            borderRadius: '8px',
            backgroundColor: alertFeedback.type === 'success' ? '#ECFDF5' : '#FEF2F2',
            color: alertFeedback.type === 'success' ? '#065F46' : '#991B1B',
            border: `1.5px solid ${alertFeedback.type === 'success' ? '#A7F3D0' : '#FECDD3'}`,
            display: 'flex',
            alignItems: 'center',
            gap: '0.65rem',
            fontSize: '0.85rem',
            fontWeight: 600,
            animation: 'fadeInUp 0.25s ease',
          }}
        >
          {alertFeedback.type === 'success' ? <CheckIcon size={18} /> : <AlertTriangleIcon size={18} />}
          <span>{alertFeedback.message}</span>
        </div>
      )}

      {/* Section Header */}
      <div className="section-header" style={{ alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.5rem' }}>
        <div>
          <h1 className="section-title" style={{ fontSize: '1.45rem', fontWeight: 800, margin: 0 }}>
            {activeSubTab === 'users' ? 'Daftar Pengguna' : 'Data Master Role & Hak Akses'}
          </h1>
        </div>

        {/* Action Buttons: Add User & Refresh */}
        <div style={{ display: 'flex', gap: '0.65rem', alignItems: 'center' }}>
          {activeSubTab === 'users' && (
            <button
              type="button"
              className="btn btn-primary btn-sm"
              style={{
                backgroundColor: '#0D47A1',
                color: '#ffffff',
                border: 'none',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.45rem',
                fontWeight: 700,
                padding: '0.45rem 0.95rem',
                borderRadius: '6px',
                boxShadow: '0 2px 8px rgba(13, 71, 161, 0.25)',
              }}
              onClick={handleOpenAdd}
              title="Tambah pengguna baru ke sistem"
            >
              <PlusIcon size={15} />
              <span>Tambah Pengguna</span>
            </button>
          )}
        </div>
      </div>

      {/* FILTER CARDS ROW (Identik dengan Verifikasi Dokter) */}
      {activeSubTab === 'users' && (
        <div className="metrics-grid" style={{ marginBottom: '1.75rem' }}>
          <div
            className={`metric-card ${roleFilter === 'ALL' ? 'active' : ''}`}
            onClick={() => setRoleFilter('ALL')}
            title="Klik untuk melihat semua pengguna aktif"
          >
            <div className="metric-header">
              <span className="metric-label">Semua Pengguna</span>
              <div className="metric-icon-box">
                <UsersIcon size={16} />
              </div>
            </div>
            <div className="metric-value">{totalCount}</div>
          </div>

          <div
            className={`metric-card ${roleFilter === 'ADMIN' ? 'active' : ''}`}
            onClick={() => setRoleFilter('ADMIN')}
            title="Klik untuk memfilter Administrator Sistem"
          >
            <div className="metric-header">
              <span className="metric-label">Admin Sistem</span>
              <div className="metric-icon-box">
                <ShieldCheckIcon size={16} />
              </div>
            </div>
            <div className="metric-value">{adminCount}</div>
          </div>

          <div
            className={`metric-card ${roleFilter === 'DOKTER' ? 'active' : ''}`}
            onClick={() => setRoleFilter('DOKTER')}
            title="Klik untuk memfilter Dokter Spesialis Mata"
          >
            <div className="metric-header">
              <span className="metric-label">Dokter Spesialis</span>
              <div className="metric-icon-box">
                <StethoscopeIcon size={16} />
              </div>
            </div>
            <div className="metric-value">{doctorCount}</div>
          </div>

          <div
            className={`metric-card ${roleFilter === 'PENGGUNA' ? 'active' : ''}`}
            onClick={() => setRoleFilter('PENGGUNA')}
            title="Klik untuk memfilter Pasien / Pengguna Mandiri"
          >
            <div className="metric-header">
              <span className="metric-label">Pengguna / Pasien</span>
              <div className="metric-icon-box">
                <UserIcon size={16} />
              </div>
            </div>
            <div className="metric-value">{patientCount}</div>
          </div>

          {trashCount > 0 && (
            <div
              className={`metric-card ${roleFilter === 'TRASH' ? 'active' : ''}`}
              onClick={() => setRoleFilter('TRASH')}
              title="Klik untuk melihat akun yang di-soft delete (Arsip)"
              style={{
                borderColor: roleFilter === 'TRASH' ? '#EF4444' : undefined,
              }}
            >
              <div className="metric-header">
                <span className="metric-label" style={{ color: roleFilter === 'TRASH' ? '#FFFFFF' : '#EF4444' }}>
                  Arsip / Terhapus
                </span>
                <div
                  className="metric-icon-box"
                  style={{
                    backgroundColor: roleFilter === 'TRASH' ? 'rgba(255,255,255,0.2)' : '#FEE2E2',
                    color: roleFilter === 'TRASH' ? '#FFFFFF' : '#DC2626',
                  }}
                >
                  <TrashIcon size={16} />
                </div>
              </div>
              <div className="metric-value" style={{ color: roleFilter === 'TRASH' ? '#FFFFFF' : '#DC2626' }}>
                {trashCount}
              </div>
            </div>
          )}
        </div>
      )}

      {/* VIEW 1: DAFTAR PENGGUNA */}
      {activeSubTab === 'users' && (
        <div className="card">
          {/* Card Header with Counter Indicator, Search and View Switcher */}
          <div
            style={{
              padding: '1rem 1.25rem',
              borderBottom: '1px solid var(--border-subtle)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: '0.875rem',
              backgroundColor: '#ffffff',
            }}
          >
            {/* Active Filter Indicator */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--slate-800)' }}>
                {roleFilter === 'ALL' && 'Semua Akun Pengguna'}
                {roleFilter === 'ADMIN' && 'Daftar Administrator'}
                {roleFilter === 'DOKTER' && 'Daftar Dokter Spesialis Mata'}
                {roleFilter === 'PENGGUNA' && 'Daftar Pengguna / Pasien'}
                {roleFilter === 'TRASH' && 'Daftar Akun Terhapus (Soft Delete)'}
              </span>
              <span
                style={{
                  fontSize: '0.725rem',
                  fontWeight: 800,
                  backgroundColor: roleFilter === 'TRASH' ? '#FEE2E2' : '#E3F2FD',
                  color: roleFilter === 'TRASH' ? '#B91C1C' : '#0D47A1',
                  padding: '0.15rem 0.55rem',
                  borderRadius: '9999px',
                  border: `1px solid ${roleFilter === 'TRASH' ? '#FECDD3' : '#BBDEFB'}`,
                }}
              >
                {filteredUsers.length} Akun
              </span>
            </div>

            {/* Search Input & View Toggle */}
            <div style={{ display: 'flex', gap: '0.65rem', alignItems: 'center' }}>
              <div style={{ position: 'relative', width: '240px' }}>
                <SearchIcon
                  size={14}
                  style={{ position: 'absolute', left: '0.65rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--slate-400)' }}
                />
                <input
                  type="text"
                  className="form-control"
                  style={{ paddingLeft: '2rem', fontSize: '0.75rem', padding: '0.4rem 0.65rem 0.4rem 2rem' }}
                  placeholder="Cari nama, email, ID..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>

              {/* View Toggle: Cards (first) vs Table (second) */}
              <div style={{ display: 'flex', border: '1px solid var(--slate-300)', borderRadius: 'var(--radius-sm)', overflow: 'hidden' }}>
                <button
                  type="button"
                  style={{
                    border: 'none',
                    padding: '0.4rem 0.65rem',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    backgroundColor: viewMode === 'cards' ? '#0D47A1' : '#ffffff',
                    color: viewMode === 'cards' ? '#ffffff' : 'var(--slate-700)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.35rem',
                  }}
                  onClick={() => setViewMode('cards')}
                  title="Tampilan Kartu (Grid)"
                >
                  <span>⊞ Kartu</span>
                </button>
                <button
                  type="button"
                  style={{
                    border: 'none',
                    padding: '0.4rem 0.65rem',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    backgroundColor: viewMode === 'table' ? '#0D47A1' : '#ffffff',
                    color: viewMode === 'table' ? '#ffffff' : 'var(--slate-700)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.35rem',
                  }}
                  onClick={() => setViewMode('table')}
                  title="Tampilan Tabel"
                >
                  <span>☰ Tabel</span>
                </button>
              </div>
            </div>
          </div>

          {/* VIEW MODE 1: TABEL PENGGUNA */}
          {viewMode === 'table' ? (
            <div className="table-responsive">
              <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '2px solid #E2E8F0' }}>
                    <th style={{ width: '28%', padding: '0.85rem 1.25rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      Pengguna
                    </th>
                    <th style={{ width: '18%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      ID Akun
                    </th>
                    <th style={{ width: '16%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      Kontak / Telp
                    </th>
                    <th style={{ width: '14%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px', textAlign: 'center' }}>
                      Role Sistem
                    </th>
                    <th style={{ width: '10%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px', textAlign: 'center' }}>
                      Status
                    </th>
                    <th style={{ width: '14%', padding: '0.85rem 1.25rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.5px', textAlign: 'right' }}>
                      Aksi
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filteredUsers.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', padding: '3rem 1.5rem', color: 'var(--slate-500)' }}>
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.5rem' }}>
                          <UsersIcon size={32} style={{ color: 'var(--slate-400)' }} />
                          <div style={{ fontWeight: 600 }}>Tidak ada akun pengguna yang cocok</div>
                          <div style={{ fontSize: '0.75rem' }}>Silakan sesuaikan filter role atau kata kunci pencarian Anda.</div>
                        </div>
                      </td>
                    </tr>
                  ) : (
                    filteredUsers.map((u) => {
                      const roleLabel = formatRoleLabel(u.role);
                      const roleStyle = getRoleStyle(u.role);

                      return (
                        <tr key={u.id} style={{ borderBottom: '1px solid var(--border-subtle)', transition: 'background-color 0.15s ease' }}>
                          {/* Pengguna: Avatar, Name & Email */}
                          <td style={{ padding: '0.95rem 1.25rem', verticalAlign: 'middle' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                              <div
                                style={{
                                  width: '36px',
                                  height: '36px',
                                  borderRadius: '50%',
                                  backgroundColor: '#E3F2FD',
                                  color: '#0D47A1',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  border: '1.5px solid #BBDEFB',
                                  flexShrink: 0,
                                }}
                                title={`Peran: ${roleLabel}`}
                              >
                                {getRoleIcon(u.role, 18, { color: '#0D47A1' })}
                              </div>
                              <div style={{ minWidth: 0 }}>
                                <div style={{ fontWeight: 700, fontSize: '0.85rem', color: 'var(--slate-900)' }}>
                                  {u.fullName}
                                </div>
                                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>
                                  {u.email}
                                </div>
                              </div>
                            </div>
                          </td>

                          {/* ID Akun */}
                          <td style={{ padding: '0.95rem 1rem', verticalAlign: 'middle' }}>
                            <code
                              title={`UUID Database: ${u.id}`}
                              style={{
                                fontSize: '0.75rem',
                                fontWeight: 700,
                                padding: '0.25rem 0.55rem',
                                backgroundColor: '#EFF6FF',
                                border: '1px solid #BFDBFE',
                                borderRadius: '5px',
                                color: '#0D47A1',
                                fontFamily: 'monospace',
                                letterSpacing: '0.03em',
                              }}
                            >
                              {getUserDisplayId(u)}
                            </code>
                          </td>

                          {/* Kontak / Telp */}
                          <td style={{ padding: '0.95rem 1rem', verticalAlign: 'middle', fontSize: '0.775rem', color: 'var(--slate-700)' }}>
                            {u.phoneNumber || '—'}
                          </td>

                          {/* Role Sistem */}
                          <td style={{ padding: '0.95rem 1rem', verticalAlign: 'middle', textAlign: 'center' }}>
                            <span
                              style={{
                                fontSize: '0.725rem',
                                fontWeight: 700,
                                padding: '0.2rem 0.65rem',
                                borderRadius: '9999px',
                                display: 'inline-flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                ...roleStyle,
                              }}
                            >
                              <span>{roleLabel}</span>
                            </span>
                          </td>

                          {/* Status */}
                          <td style={{ padding: '0.95rem 1rem', verticalAlign: 'middle', textAlign: 'center' }}>
                            {u.deletedAt ? (
                              <span className="badge" style={{ backgroundColor: '#FEE2E2', color: '#B91C1C', border: '1px solid #FECDD3', fontSize: '0.7rem', padding: '0.2rem 0.55rem', fontWeight: 700 }}>
                                <TrashIcon size={11} />
                                <span>Terhapus</span>
                              </span>
                            ) : u.isActive ? (
                              <span className="badge badge-pass" style={{ fontSize: '0.7rem', padding: '0.2rem 0.55rem', fontWeight: 700 }}>
                                <CheckIcon size={11} />
                                <span>Aktif</span>
                              </span>
                            ) : (
                              <span className="badge badge-retake" style={{ fontSize: '0.7rem', padding: '0.2rem 0.55rem', fontWeight: 700 }}>
                                <XIcon size={11} />
                                <span>Nonaktif</span>
                              </span>
                            )}
                          </td>

                          {/* Aksi Kolom: Edit & Delete / Restore */}
                          <td style={{ padding: '0.95rem 1.25rem', verticalAlign: 'middle', textAlign: 'right' }}>
                            <div style={{ display: 'flex', gap: '0.45rem', justifyContent: 'flex-end', alignItems: 'center' }}>
                              {u.deletedAt ? (
                                <button
                                  type="button"
                                  style={{
                                    padding: '0.35rem 0.65rem',
                                    fontSize: '0.725rem',
                                    fontWeight: 700,
                                    borderRadius: '5px',
                                    border: '1px solid #A7F3D0',
                                    backgroundColor: '#ECFDF5',
                                    color: '#065F46',
                                    cursor: 'pointer',
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    gap: '0.3rem',
                                  }}
                                  onClick={() => handleRestoreUser(u)}
                                  title="Pulihkan akun ini"
                                >
                                  <RotateCwIcon size={12} />
                                  <span>Pulihkan</span>
                                </button>
                              ) : (
                                <>
                                  <button
                                    type="button"
                                    style={{
                                      padding: '0.35rem 0.65rem',
                                      fontSize: '0.725rem',
                                      fontWeight: 600,
                                      borderRadius: '5px',
                                      border: '1px solid #90CAF9',
                                      backgroundColor: '#E3F2FD',
                                      color: '#0D47A1',
                                      cursor: 'pointer',
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: '0.3rem',
                                      transition: 'all 0.15s ease',
                                    }}
                                    onClick={() => handleOpenEdit(u)}
                                    title="Edit data pengguna"
                                  >
                                    <EditIcon size={12} />
                                    <span>Edit</span>
                                  </button>
                                  <button
                                    type="button"
                                    style={{
                                      padding: '0.35rem 0.65rem',
                                      fontSize: '0.725rem',
                                      fontWeight: 600,
                                      borderRadius: '5px',
                                      border: '1px solid #FECDD3',
                                      backgroundColor: '#FEF2F2',
                                      color: '#DC2626',
                                      cursor: 'pointer',
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: '0.3rem',
                                      transition: 'all 0.15s ease',
                                    }}
                                    onClick={() => setDeletingUser(u)}
                                    title="Hapus pengguna ini (Soft Delete)"
                                  >
                                    <TrashIcon size={12} />
                                    <span>Hapus</span>
                                  </button>
                                </>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          ) : (
            /* VIEW MODE 2: KARTU PENGGUNA (GRID) */
            <div style={{ padding: '1.5rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.25rem', backgroundColor: '#F8FAFC', borderTop: '1px solid #E2E8F0' }}>
              {filteredUsers.length === 0 ? (
                <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '3rem 1.5rem', color: 'var(--slate-500)' }}>
                  <UsersIcon size={36} style={{ color: 'var(--slate-400)', marginBottom: '0.5rem' }} />
                  <div style={{ fontWeight: 600 }}>Tidak ada akun pengguna yang cocok</div>
                </div>
              ) : (
                filteredUsers.map((u) => {
                  const roleLabel = formatRoleLabel(u.role);

                  return (
                    <div
                      key={u.id}
                      className="master-user-card"
                      onClick={() => handleOpenEdit(u)}
                      title="Klik untuk melihat atau mengedit pengguna"
                    >
                      <div>
                        {/* Top Row: User Avatar, Name, Role Badge & Status */}
                        <div className="vcard-header">
                          <div className="vcard-doctor-info">
                            <div className="vcard-avatar" title={`Peran: ${roleLabel}`}>
                              {getRoleIcon(u.role, 22, { color: '#0D47A1' })}
                            </div>
                            <div style={{ minWidth: 0 }}>
                              <h3 className="vcard-name">{u.fullName}</h3>
                              <span className="vcard-specialty-badge">
                                {roleLabel}
                              </span>
                            </div>
                          </div>

                          <div style={{ flexShrink: 0 }}>
                            {u.deletedAt ? (
                              <span className="badge" style={{ backgroundColor: '#FEE2E2', color: '#B91C1C', border: '1px solid #FECDD3', fontSize: '0.725rem', padding: '0.25rem 0.65rem', fontWeight: 700, whiteSpace: 'nowrap' }}>
                                <TrashIcon size={12} /> Terhapus
                              </span>
                            ) : u.isActive ? (
                              <span className="badge badge-pass" style={{ fontSize: '0.725rem', padding: '0.25rem 0.65rem', fontWeight: 700, whiteSpace: 'nowrap' }}>
                                <CheckIcon size={12} /> Aktif
                              </span>
                            ) : (
                              <span className="badge badge-retake" style={{ fontSize: '0.725rem', padding: '0.25rem 0.65rem', fontWeight: 700, whiteSpace: 'nowrap' }}>
                                <XIcon size={12} /> Nonaktif
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Email & Contact Info */}
                        <div className="vcard-meta-section" style={{ marginTop: '0.85rem' }}>
                          <div className="vcard-meta-row">
                            <MailIcon size={14} style={{ color: '#FFFFFF', flexShrink: 0 }} />
                            <div style={{ minWidth: 0, overflow: 'hidden' }}>
                              <span className="vcard-facility-name" style={{ wordBreak: 'break-all', fontSize: '0.8rem' }}>{u.email}</span>
                              <span className="vcard-facility-sub">Email Terdaftar</span>
                            </div>
                          </div>
                          <div className="vcard-meta-row" style={{ marginTop: '0.25rem' }}>
                            <PhoneIcon size={14} style={{ color: '#FFFFFF', flexShrink: 0 }} />
                            <span className="vcard-date">
                              {u.phoneNumber ? `Telepon: ${u.phoneNumber}` : 'Telepon: —'}
                            </span>
                          </div>
                          {(roleLabel === 'Admin' || roleLabel === 'Dokter' || u.hospital) && (
                            <div className="vcard-meta-row" style={{ marginTop: '0.45rem', paddingTop: '0.45rem', borderTop: '1px solid rgba(255,255,255,0.18)' }}>
                              <HospitalIcon size={14} style={{ color: '#FFFFFF', flexShrink: 0 }} />
                              <div style={{ minWidth: 0, overflow: 'hidden' }}>
                                <span className="vcard-facility-name" style={{ fontSize: '0.82rem', fontWeight: 700, color: '#FFFFFF', display: 'block' }}>
                                  {u.hospital || (roleLabel === 'Dokter' ? 'RS Mata Dr. Yap' : 'Puskesmas Mlati II')}
                                </span>
                                <span className="vcard-facility-sub" style={{ opacity: 0.9 }}>
                                  {u.facilityType || (roleLabel === 'Dokter' ? 'RS Khusus Mata Tipe A' : 'FKTP Sleman')} • Tempat Bekerja
                                </span>
                              </div>
                            </div>
                          )}
                        </div>

                        {/* ID & Registered Date Box */}
                        <div className="vcard-credentials-box" style={{ marginTop: '0.75rem' }}>
                          <div className="vcard-cred-row">
                            <span className="vcard-cred-label">No. ID Pengguna:</span>
                            <code
                              className="vcard-cred-code"
                              title={`UUID Database: ${u.id}`}
                              style={{ fontFamily: 'monospace', letterSpacing: '0.04em', fontWeight: 800 }}
                            >
                              {getUserDisplayId(u)}
                            </code>
                          </div>
                          <div className="vcard-cred-row">
                            <span className="vcard-cred-label">Terdaftar:</span>
                            <code className="vcard-cred-code str" style={{ fontSize: '0.7rem' }}>
                              {new Date(u.createdAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                            </code>
                          </div>
                        </div>
                      </div>

                      {/* Card Actions: Edit & Hapus or Restore */}
                      <div className="vcard-actions" onClick={(e) => e.stopPropagation()}>
                        {u.deletedAt ? (
                          <button
                            type="button"
                            onClick={() => handleRestoreUser(u)}
                            title="Pulihkan akun ini ke daftar aktif"
                            style={{
                              flex: 1,
                              padding: '0.55rem 1rem',
                              borderRadius: '8px',
                              backgroundColor: '#10B981',
                              color: '#FFFFFF',
                              border: '1.5px solid #34D399',
                              cursor: 'pointer',
                              display: 'inline-flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              gap: '0.4rem',
                              fontWeight: 700,
                              fontSize: '0.8rem',
                              boxShadow: '0 2px 8px rgba(16, 185, 129, 0.25)',
                              transition: 'all 0.2s ease',
                            }}
                          >
                            <RotateCwIcon size={14} />
                            <span>Pulihkan Akun (Restore)</span>
                          </button>
                        ) : (
                          <>
                            <button
                              type="button"
                              className="vcard-btn-review"
                              onClick={() => handleOpenEdit(u)}
                              title="Edit data pengguna"
                              style={{ flex: 1 }}
                            >
                              <EditIcon size={14} />
                              <span>Edit Pengguna</span>
                            </button>
                            <button
                              type="button"
                              onClick={() => setDeletingUser(u)}
                              title="Hapus pengguna (Soft Delete)"
                              style={{
                                padding: '0.55rem 1rem',
                                borderRadius: '8px',
                                backgroundColor: '#EF4444',
                                color: '#FFFFFF',
                                border: '1.5px solid #F87171',
                                cursor: 'pointer',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '0.4rem',
                                fontWeight: 700,
                                fontSize: '0.8rem',
                                boxShadow: '0 2px 8px rgba(0, 0, 0, 0.25)',
                                transition: 'all 0.2s ease',
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.backgroundColor = '#DC2626';
                                e.currentTarget.style.borderColor = '#EF4444';
                                e.currentTarget.style.transform = 'translateY(-2px)';
                                e.currentTarget.style.boxShadow = '0 4px 14px rgba(220, 38, 38, 0.45)';
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.backgroundColor = '#EF4444';
                                e.currentTarget.style.borderColor = '#F87171';
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.25)';
                              }}
                            >
                              <TrashIcon size={14} style={{ color: '#FFFFFF' }} />
                              <span>Hapus</span>
                            </button>
                          </>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          )}
        </div>
      )}

      {/* VIEW 2: DATA MASTER ROLE & HAK AKSES */}
      {activeSubTab === 'roles' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {/* 3 Role Quick Cards */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
            {SYSTEM_ROLES.map((r) => {
              const countInRole = users.filter((u) => formatRoleLabel(u.role).toUpperCase() === r.displayName.toUpperCase()).length;
              return (
                <div
                  key={r.id}
                  style={{
                    backgroundColor: '#ffffff',
                    border: `1px solid ${r.badgeBorder}`,
                    borderRadius: 'var(--radius-md)',
                    padding: '1.25rem',
                    boxShadow: 'var(--shadow-sm)',
                    position: 'relative',
                    overflow: 'hidden',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                    <span
                      style={{
                        fontSize: '0.75rem',
                        fontWeight: 800,
                        color: r.badgeColor,
                        backgroundColor: r.badgeBg,
                        border: `1px solid ${r.badgeBorder}`,
                        padding: '0.2rem 0.65rem',
                        borderRadius: '9999px',
                        textTransform: 'uppercase',
                        letterSpacing: '0.05em',
                      }}
                    >
                      ROLE {r.code}
                    </span>
                    <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--slate-500)' }}>
                      {countInRole} Pengguna Terdaftar
                    </span>
                  </div>
                  <div style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--slate-900)', marginBottom: '0.25rem' }}>
                    {r.displayName}
                  </div>
                  <div style={{ fontSize: '0.775rem', color: 'var(--slate-600)', lineHeight: 1.5, marginBottom: '0.85rem' }}>
                    {r.description}
                  </div>
                  <div>
                    <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--slate-500)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.35rem' }}>
                      Kewenangan Kunci:
                    </div>
                    <ul style={{ margin: 0, paddingLeft: '1.2rem', fontSize: '0.75rem', color: 'var(--slate-700)', lineHeight: 1.6 }}>
                      {r.permissions.map((perm, idx) => (
                        <li key={idx}>{perm}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Master Roles Specification Table */}
          <div className="card">
            <div style={{ padding: '1rem 1.25rem', borderBottom: '1px solid var(--border-subtle)', backgroundColor: '#ffffff' }}>
              <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--slate-900)', margin: 0 }}>
                Spesifikasi Matriks Hak Akses &amp; Otorisasi
              </h3>
            </div>
            <div className="table-responsive">
              <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '2px solid #E2E8F0' }}>
                    <th style={{ width: '16%', padding: '0.85rem 1.25rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase' }}>
                      Kode Role
                    </th>
                    <th style={{ width: '22%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase' }}>
                      Nama &amp; Kategori
                    </th>
                    <th style={{ width: '42%', padding: '0.85rem 1rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase' }}>
                      Deskripsi Fungsional &amp; Tanggung Jawab
                    </th>
                    <th style={{ width: '20%', padding: '0.85rem 1.25rem', fontSize: '0.75rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', textAlign: 'center' }}>
                      Anggota Terdaftar
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {SYSTEM_ROLES.map((r) => {
                    const countInRole = users.filter((u) => formatRoleLabel(u.role).toUpperCase() === r.displayName.toUpperCase()).length;
                    return (
                      <tr key={r.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                        <td style={{ padding: '1rem 1.25rem', verticalAlign: 'top' }}>
                          <span
                            style={{
                              fontSize: '0.725rem',
                              fontWeight: 800,
                              color: r.badgeColor,
                              backgroundColor: r.badgeBg,
                              border: `1px solid ${r.badgeBorder}`,
                              padding: '0.2rem 0.65rem',
                              borderRadius: '9999px',
                            }}
                          >
                            {r.code}
                          </span>
                        </td>
                        <td style={{ padding: '1rem 1rem', verticalAlign: 'top' }}>
                          <div style={{ fontWeight: 700, fontSize: '0.85rem', color: 'var(--slate-900)' }}>
                            {r.displayName}
                          </div>
                          <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                            {r.category}
                          </div>
                        </td>
                        <td style={{ padding: '1rem 1rem', verticalAlign: 'top', fontSize: '0.785rem', color: 'var(--slate-600)', lineHeight: 1.5 }}>
                          {r.description}
                        </td>
                        <td style={{ padding: '1rem 1.25rem', verticalAlign: 'top', textAlign: 'center' }}>
                          <span
                            style={{
                              fontSize: '0.85rem',
                              fontWeight: 800,
                              color: '#0D47A1',
                              backgroundColor: '#E3F2FD',
                              padding: '0.2rem 0.65rem',
                              borderRadius: '6px',
                              border: '1px solid #BBDEFB',
                            }}
                          >
                            {countInRole} Akun
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 1: TAMBAH PENGGUNA */}
      {isAddModalOpen && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1rem',
          }}
          onClick={() => !isSubmitting && setIsAddModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '12px',
              maxWidth: '500px',
              width: '100%',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
              overflow: 'hidden',
              animation: 'fadeInUp 0.25s ease',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '6px', backgroundColor: '#E3F2FD', color: '#0D47A1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <PlusIcon size={18} />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  Tambah Pengguna Baru
                </h3>
              </div>
              <button
                type="button"
                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#64748B' }}
                onClick={() => setIsAddModalOpen(false)}
              >
                <XIcon size={18} />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSaveAdd} style={{ padding: '1.5rem' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Nama Lengkap <span style={{ color: '#EF4444' }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    required
                    placeholder="Contoh: dr. Budi Santoso, Sp.M"
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Alamat Email <span style={{ color: '#EF4444' }}>*</span>
                  </label>
                  <input
                    type="email"
                    className="form-control"
                    required
                    placeholder="nama@email.com"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Nomor Telepon
                    </label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="08123456789"
                      value={formData.phoneNumber}
                      onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Role Sistem <span style={{ color: '#EF4444' }}>*</span>
                    </label>
                    <select
                      className="form-control"
                      value={formData.role}
                      onChange={(e) => {
                        const newRole = e.target.value;
                        const defFac = newRole === 'DOKTER' 
                          ? facilities.find((f) => f.category === 'FKRTL') || facilities[0]
                          : facilities.find((f) => f.category === 'FKTP') || facilities[0];
                        const defHosp = defFac ? defFac.name : (newRole === 'DOKTER' ? 'RS Mata Dr. Yap Yogyakarta' : 'Puskesmas Mlati II (FKTP)');
                        const defType = defFac ? (defFac.category === 'FKRTL' ? 'FKRTL Rujukan' : 'FKTP Sleman') : 'FKTP Sleman';
                        setFormData({ ...formData, role: newRole, hospital: defHosp, facilityType: defType });
                      }}
                    >
                      <option value="ADMIN">Admin</option>
                      <option value="DOKTER">Dokter</option>
                      <option value="PENGGUNA">Pengguna</option>
                    </select>
                  </div>
                </div>

                {(formData.role === 'ADMIN' || formData.role === 'DOKTER') && (
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Rumah Sakit / Faskes Tempat Bekerja <span style={{ color: '#EF4444' }}>*</span>
                    </label>
                    <select
                      className="form-control"
                      value={formData.hospital}
                      onChange={(e) => {
                        const hName = e.target.value;
                        const selectedFac = facilities.find((f) => f.name === hName);
                        const fType = selectedFac
                          ? (selectedFac.category === 'FKTP'
                              ? 'FKTP Sleman'
                              : selectedFac.name.includes('Sardjito')
                              ? 'RSUP Rujukan Nasional Tipe A'
                              : selectedFac.name.includes('Yap')
                              ? 'RS Khusus Mata Tipe B'
                              : 'FKRTL Rujukan')
                          : 'FKTP Sleman';
                        setFormData({ ...formData, hospital: hName, facilityType: fType });
                      }}
                    >
                      <optgroup label="FKTP (Puskesmas & Klinik Pratama Tingkat Pertama)">
                        {facilities
                          .filter((f) => f.category === 'FKTP')
                          .map((f) => (
                            <option key={f.id} value={f.name}>
                              {f.name}
                            </option>
                          ))}
                      </optgroup>
                      <optgroup label="FKRTL (Rumah Sakit Rujukan Vitreoretina & Khusus Mata)">
                        {facilities
                          .filter((f) => f.category === 'FKRTL')
                          .map((f) => (
                            <option key={f.id} value={f.name}>
                              {f.name}
                            </option>
                          ))}
                      </optgroup>
                    </select>
                    <span style={{ fontSize: '0.7rem', color: '#64748B', marginTop: '0.2rem', display: 'block' }}>
                      Terhubung langsung dengan seluruh <strong>{facilities.length} faskes</strong> yang terdaftar di database.
                    </span>
                  </div>
                )}

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Kata Sandi Awal
                  </label>
                  <input
                    type="password"
                    className="form-control"
                    placeholder="Default: Retiva123! (kosongkan jika default)"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  />
                  <span style={{ fontSize: '0.7rem', color: '#64748B', marginTop: '0.2rem', display: 'block' }}>
                    Jika dikosongkan, kata sandi awal otomatis diatur ke <code>Retiva123!</code>
                  </span>
                </div>
              </div>

              {/* Modal Actions */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem', marginTop: '1.75rem', paddingTop: '1rem', borderTop: '1px solid #E2E8F0' }}>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  disabled={isSubmitting}
                  onClick={() => setIsAddModalOpen(false)}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="btn btn-primary btn-sm"
                  style={{ backgroundColor: '#0D47A1', border: 'none', color: '#ffffff', fontWeight: 700 }}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? 'Menyimpan...' : 'Simpan Pengguna'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 2: EDIT PENGGUNA */}
      {editingUser && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1rem',
          }}
          onClick={() => !isSubmitting && setEditingUser(null)}
        >
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '12px',
              maxWidth: '500px',
              width: '100%',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
              overflow: 'hidden',
              animation: 'fadeInUp 0.25s ease',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '6px', backgroundColor: '#E3F2FD', color: '#0D47A1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <EditIcon size={16} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                    Edit Data Pengguna
                  </h3>
                  <div style={{ fontSize: '0.725rem', color: '#64748B', marginTop: '0.15rem' }}>
                    ID: <strong style={{ color: '#0D47A1', fontFamily: 'monospace' }}>{getUserDisplayId(editingUser)}</strong>
                  </div>
                </div>
              </div>
              <button
                type="button"
                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#64748B' }}
                onClick={() => setEditingUser(null)}
              >
                <XIcon size={18} />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSaveEdit} style={{ padding: '1.5rem' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Nama Lengkap <span style={{ color: '#EF4444' }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    required
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Alamat Email <span style={{ color: '#EF4444' }}>*</span>
                  </label>
                  <input
                    type="email"
                    className="form-control"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Nomor Telepon
                    </label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.phoneNumber}
                      onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Role Sistem <span style={{ color: '#EF4444' }}>*</span>
                    </label>
                    <select
                      className="form-control"
                      value={formData.role}
                      onChange={(e) => {
                        const newRole = e.target.value;
                        const defFac = newRole === 'DOKTER' 
                          ? facilities.find((f) => f.category === 'FKRTL') || facilities[0]
                          : facilities.find((f) => f.category === 'FKTP') || facilities[0];
                        const defHosp = defFac ? defFac.name : (newRole === 'DOKTER' ? 'RS Mata Dr. Yap Yogyakarta' : 'Puskesmas Mlati II (FKTP)');
                        const defType = defFac ? (defFac.category === 'FKRTL' ? 'FKRTL Rujukan' : 'FKTP Sleman') : 'FKTP Sleman';
                        setFormData({ ...formData, role: newRole, hospital: defHosp, facilityType: defType });
                      }}
                    >
                      <option value="ADMIN">Admin</option>
                      <option value="DOKTER">Dokter</option>
                      <option value="PENGGUNA">Pengguna</option>
                    </select>
                  </div>
                </div>

                {(formData.role === 'ADMIN' || formData.role === 'DOKTER') && (
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Rumah Sakit / Faskes Tempat Bekerja <span style={{ color: '#EF4444' }}>*</span>
                    </label>
                    <select
                      className="form-control"
                      value={formData.hospital}
                      onChange={(e) => {
                        const hName = e.target.value;
                        const selectedFac = facilities.find((f) => f.name === hName);
                        const fType = selectedFac
                          ? (selectedFac.category === 'FKTP'
                              ? 'FKTP Sleman'
                              : selectedFac.name.includes('Sardjito')
                              ? 'RSUP Rujukan Nasional Tipe A'
                              : selectedFac.name.includes('Yap')
                              ? 'RS Khusus Mata Tipe B'
                              : 'FKRTL Rujukan')
                          : 'FKTP Sleman';
                        setFormData({ ...formData, hospital: hName, facilityType: fType });
                      }}
                    >
                      <optgroup label="FKTP (Puskesmas & Klinik Pratama Tingkat Pertama)">
                        {facilities
                          .filter((f) => f.category === 'FKTP')
                          .map((f) => (
                            <option key={f.id} value={f.name}>
                              {f.name}
                            </option>
                          ))}
                      </optgroup>
                      <optgroup label="FKRTL (Rumah Sakit Rujukan Vitreoretina & Khusus Mata)">
                        {facilities
                          .filter((f) => f.category === 'FKRTL')
                          .map((f) => (
                            <option key={f.id} value={f.name}>
                              {f.name}
                            </option>
                          ))}
                      </optgroup>
                    </select>
                    <span style={{ fontSize: '0.7rem', color: '#64748B', marginTop: '0.2rem', display: 'block' }}>
                      Terhubung langsung dengan seluruh <strong>{facilities.length} faskes</strong> yang terdaftar di database.
                    </span>
                  </div>
                )}

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Status Akun
                    </label>
                    <select
                      className="form-control"
                      value={formData.isActive ? 'true' : 'false'}
                      onChange={(e) => setFormData({ ...formData, isActive: e.target.value === 'true' })}
                    >
                      <option value="true">Aktif</option>
                      <option value="false">Nonaktif</option>
                    </select>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Ubah Kata Sandi
                    </label>
                    <input
                      type="password"
                      className="form-control"
                      placeholder="Biarkan kosong jika tetap"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    />
                  </div>
                </div>
              </div>

              {/* Modal Actions */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem', marginTop: '1.75rem', paddingTop: '1rem', borderTop: '1px solid #E2E8F0' }}>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  disabled={isSubmitting}
                  onClick={() => setEditingUser(null)}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="btn btn-primary btn-sm"
                  style={{ backgroundColor: '#0D47A1', border: 'none', color: '#ffffff', fontWeight: 700 }}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 3: KONFIRMASI HAPUS PENGGUNA */}
      {deletingUser && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.65)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1rem',
          }}
          onClick={() => !isSubmitting && setDeletingUser(null)}
        >
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '12px',
              maxWidth: '440px',
              width: '100%',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.2)',
              overflow: 'hidden',
              padding: '1.5rem',
              animation: 'fadeInUp 0.25s ease',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#FEF2F2', color: '#DC2626', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <AlertTriangleIcon size={22} />
              </div>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  Hapus Pengguna (Soft Delete)?
                </h3>
                <span style={{ fontSize: '0.75rem', color: '#64748B' }}>Akun akan dinonaktifkan &amp; diarsipkan</span>
              </div>
            </div>

            <p style={{ fontSize: '0.85rem', color: '#334155', lineHeight: 1.5, margin: '0.5rem 0 1rem 0' }}>
              Apakah Anda yakin ingin menghapus akun <strong>{deletingUser.fullName}</strong> ({deletingUser.email} &bull; ID: <code>{getUserDisplayId(deletingUser)}</code>)?
            </p>

            <div style={{ backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0', borderRadius: '8px', padding: '0.75rem', fontSize: '0.75rem', color: '#475569', marginBottom: '1.25rem', lineHeight: 1.5 }}>
              🛡️ <strong>Keamanan Data Medis (Soft Delete):</strong> Akun akan dinonaktifkan sehingga tidak dapat masuk ke sistem, tetapi seluruh riwayat telaah retina, rekam medis, dan catatan audit kepatuhan klinis tetap tersimpan aman serta dapat dipulihkan sewaktu-waktu.
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem' }}>
              <button
                type="button"
                className="btn btn-outline btn-sm"
                disabled={isSubmitting}
                onClick={() => setDeletingUser(null)}
              >
                Batal
              </button>
              <button
                type="button"
                className="btn btn-sm"
                style={{ backgroundColor: '#DC2626', color: '#ffffff', border: 'none', fontWeight: 700 }}
                disabled={isSubmitting}
                onClick={handleConfirmDelete}
              >
                {isSubmitting ? 'Memproses...' : 'Ya, Hapus (Soft Delete)'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
