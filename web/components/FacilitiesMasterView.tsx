'use client';

import React, { useState, useEffect } from 'react';
import {
  HospitalIcon,
  SearchIcon,
  PlusIcon,
  EditIcon,
  TrashIcon,
  RotateCwIcon,
  CheckIcon,
  XIcon,
  AlertTriangleIcon,
  MapPinIcon,
  PhoneIcon,
  ShieldCheckIcon,
} from './Icons';
import { clinicalStore } from '../lib/clinical-store';

export interface MasterFacility {
  id: string;
  name: string;
  category: 'FKTP' | 'FKRTL';
  categoryLabel: string;
  address: string;
  latitude: number;
  longitude: number;
  bpjsStatus: 'ACCEPTED' | 'NEEDS_CONFIRMATION' | 'NOT_AVAILABLE';
  isVerified: boolean;
  contactPhone: string;
  services: string[];
  insurances: string[];
  createdAt?: string;
  updatedAt?: string;
}

const COMMON_SERVICES = [
  { key: 'PRIMARY_DIABETES_CARE', label: 'Perawatan Diabetes Primer' },
  { key: 'FUNDUS_CAMERA_SCREENING', label: 'Skrining Kamera Fundus' },
  { key: 'CDSS_TRIAGE', label: 'Triase AI / CDSS Retiva' },
  { key: 'RETINA_SUBSPECIALIST', label: 'Poli Sub-spesialis Retina' },
  { key: 'VITREORETINAL_SURGERY', label: 'Bedah Vitreoretinal Kompleks' },
  { key: 'LASER_PHOTOCOAGULATION_PRP', label: 'Laser Fotokoagulasi (PRP)' },
  { key: 'OCT_MACULAR_SCAN', label: 'Pemindaian OCT Makula' },
  { key: 'ANTI_VEGF_INJECTION', label: 'Injeksi Anti-VEGF Intravitreal' },
  { key: 'FLUORESCEIN_ANGIOGRAPHY', label: 'Angiografi Fluoresens' },
];

const COMMON_INSURANCES = [
  'BPJS_KESEHATAN',
  'MANDIRI_INHEALTH',
  'JAMKESDA',
  'ASURANSI_SWASTA',
];

export function FacilitiesMasterView() {
  const [facilities, setFacilities] = useState<MasterFacility[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<'ALL' | 'FKTP' | 'FKRTL'>('ALL');
  const [bpjsFilter, setBpjsFilter] = useState<string>('ALL');
  const [viewMode, setViewMode] = useState<'cards' | 'table'>('cards');

  // Modals
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);
  const [editingFacility, setEditingFacility] = useState<MasterFacility | null>(null);
  const [deletingFacility, setDeletingFacility] = useState<MasterFacility | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [alertFeedback, setAlertFeedback] = useState<{ message: string; type: 'success' | 'danger' } | null>(null);

  // Form State
  const [formData, setFormData] = useState<{
    id?: string;
    name: string;
    category: 'FKTP' | 'FKRTL';
    address: string;
    latitude: string;
    longitude: string;
    bpjsStatus: 'ACCEPTED' | 'NEEDS_CONFIRMATION' | 'NOT_AVAILABLE';
    isVerified: boolean;
    contactPhone: string;
    services: string[];
    insurances: string[];
  }>({
    name: '',
    category: 'FKRTL',
    address: '',
    latitude: '-7.7828',
    longitude: '110.3671',
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '',
    services: ['RETINA_SUBSPECIALIST', 'OCT_MACULAR_SCAN'],
    insurances: ['BPJS_KESEHATAN'],
  });

  const fetchFacilities = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/v1/master/facilities');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          setFacilities(json.data);
          return;
        }
      }
    } catch (e) {
      console.warn('Fallback loading facilities:', e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchFacilities();
  }, []);

  const showAlert = (message: string, type: 'success' | 'danger' = 'success') => {
    setAlertFeedback({ message, type });
    setTimeout(() => setAlertFeedback(null), 4500);
  };

  const handleOpenAddModal = () => {
    setFormData({
      name: '',
      category: 'FKTP',
      address: '',
      latitude: '-7.7828',
      longitude: '110.3671',
      bpjsStatus: 'ACCEPTED',
      isVerified: true,
      contactPhone: '',
      services: ['PRIMARY_DIABETES_CARE', 'FUNDUS_CAMERA_SCREENING'],
      insurances: ['BPJS_KESEHATAN'],
    });
    setIsAddModalOpen(true);
  };

  const handleOpenEditModal = (f: MasterFacility) => {
    setEditingFacility(f);
    setFormData({
      id: f.id,
      name: f.name,
      category: f.category,
      address: f.address,
      latitude: String(f.latitude),
      longitude: String(f.longitude),
      bpjsStatus: f.bpjsStatus,
      isVerified: f.isVerified,
      contactPhone: f.contactPhone === '-' ? '' : f.contactPhone,
      services: [...f.services],
      insurances: [...f.insurances],
    });
  };

  const toggleService = (srvKey: string) => {
    setFormData((prev) => {
      const exists = prev.services.includes(srvKey);
      return {
        ...prev,
        services: exists ? prev.services.filter((s) => s !== srvKey) : [...prev.services, srvKey],
      };
    });
  };

  const toggleInsurance = (insKey: string) => {
    setFormData((prev) => {
      const exists = prev.insurances.includes(insKey);
      return {
        ...prev,
        insurances: exists ? prev.insurances.filter((i) => i !== insKey) : [...prev.insurances, insKey],
      };
    });
  };

  const handleSaveFacility = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.address.trim()) {
      showAlert('Nama fasilitas dan alamat wajib diisi.', 'danger');
      return;
    }

    setIsSubmitting(true);
    try {
      const isEdit = Boolean(editingFacility);
      const url = isEdit
        ? `/api/v1/master/facilities/${editingFacility?.id}`
        : '/api/v1/master/facilities';
      const method = isEdit ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      const json = await res.json();
      if (!res.ok || !json.success) {
        throw new Error(json.error || 'Gagal menyimpan fasilitas kesehatan.');
      }

      // Sync to clinicalStore
      try {
        clinicalStore.addFacility({
          name: formData.name.trim(),
          type: formData.category === 'FKTP' ? 'FKTP (Puskesmas / Klinik)' : 'Rumah Sakit Rujukan Retina',
          service: formData.services.join(', '),
          distanceKm: 4.0,
          bpjsStatus: formData.bpjsStatus === 'ACCEPTED' ? 'Menerima BPJS / JKN' : 'Status BPJS Perlu Konfirmasi',
          bpjsVerified: formData.bpjsStatus === 'ACCEPTED',
          address: formData.address.trim(),
          phone: formData.contactPhone || '-',
          schedule: 'Senin - Sabtu (08:00 - 15:00 WIB)',
        });
      } catch (err) {
        console.warn('Clinical store sync note:', err);
      }

      showAlert(
        isEdit
          ? `Data faskes "${formData.name}" berhasil diperbarui.`
          : `Fasilitas kesehatan "${formData.name}" berhasil ditambahkan.`
      );

      setIsAddModalOpen(false);
      setEditingFacility(null);
      await fetchFacilities();
    } catch (err: any) {
      showAlert(err.message || 'Terjadi kesalahan sistem saat menyimpan data.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteFacility = async () => {
    if (!deletingFacility) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/master/facilities/${deletingFacility.id}`, {
        method: 'DELETE',
      });
      const json = await res.json();
      if (!res.ok || !json.success) {
        throw new Error(json.error || 'Gagal menghapus fasilitas kesehatan.');
      }

      showAlert(`Fasilitas "${deletingFacility.name}" berhasil dihapus dari master data.`);
      setDeletingFacility(null);
      await fetchFacilities();
    } catch (err: any) {
      showAlert(err.message || 'Gagal menghapus fasilitas kesehatan.', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Metrics
  const countAll = facilities.length;
  const countFKTP = facilities.filter((f) => f.category === 'FKTP').length;
  const countFKRTL = facilities.filter((f) => f.category === 'FKRTL').length;
  const countBPJS = facilities.filter((f) => f.bpjsStatus === 'ACCEPTED').length;

  // Filtered List
  const filteredFacilities = facilities.filter((f) => {
    if (categoryFilter !== 'ALL' && f.category !== categoryFilter) return false;
    if (bpjsFilter !== 'ALL' && f.bpjsStatus !== bpjsFilter) return false;

    if (searchQuery.trim() !== '') {
      const q = searchQuery.toLowerCase();
      const match =
        f.name.toLowerCase().includes(q) ||
        f.address.toLowerCase().includes(q) ||
        f.contactPhone.toLowerCase().includes(q) ||
        f.services.some((s) => s.toLowerCase().includes(q));
      if (!match) return false;
    }
    return true;
  });

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', paddingBottom: '3rem' }}>
      {/* Toast Feedback */}
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

      {/* Header Section */}
      <div
        className="section-header"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '1rem',
          marginBottom: '1.25rem',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '10px',
                backgroundColor: '#EFF6FF',
                color: '#0F5FC2',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <HospitalIcon size={20} />
            </div>
            <div>
              <h1 className="section-title" style={{ fontSize: '1.45rem', fontWeight: 800, margin: 0, color: '#0F172A' }}>
                Fasilitas Kesehatan (FKTP &amp; Faskes Rujukan)
              </h1>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '0.65rem', alignItems: 'center' }}>
          <button
            type="button"
            className="btn btn-primary btn-sm"
            onClick={handleOpenAddModal}
            style={{
              backgroundColor: '#0F5FC2',
              color: '#ffffff',
              border: 'none',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.45rem',
              fontWeight: 700,
              padding: '0.55rem 1.05rem',
              borderRadius: '8px',
              fontSize: '0.85rem',
              cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(15, 95, 194, 0.25)',
              transition: 'all 0.2s ease',
            }}
          >
            <PlusIcon size={16} />
            <span>Tambah Faskes Baru</span>
          </button>
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={fetchFacilities}
            disabled={isLoading}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.45rem',
              padding: '0.55rem 0.9rem',
              borderRadius: '8px',
              fontSize: '0.85rem',
              fontWeight: 600,
              border: '1px solid #CBD5E1',
              backgroundColor: '#FFFFFF',
              color: '#334155',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
            }}
          >
            <RotateCwIcon size={15} className={isLoading ? 'animate-spin' : ''} />
            <span>Muat Ulang</span>
          </button>
        </div>
      </div>

      {/* Embedded CSS for Metric Cards Interactive Hover & Icon Animation */}
      <style>{`
        .facility-kpi-card {
          background-color: #FFFFFF;
          border: 1px solid #E2E8F0;
          border-radius: 14px;
          padding: 1.15rem 1.25rem;
          box-shadow: 0 2px 6px rgba(15, 23, 42, 0.04);
          display: flex;
          align-items: center;
          justify-content: space-between;
          transition: all 0.28s cubic-bezier(0.4, 0, 0.2, 1);
          cursor: pointer;
          position: relative;
          overflow: hidden;
        }
        .facility-kpi-card:hover {
          background-color: #0F5FC2 !important;
          border-color: #0F5FC2 !important;
          transform: translateY(-4px);
          box-shadow: 0 12px 24px -4px rgba(15, 95, 194, 0.35);
        }
        .facility-kpi-card .fkc-label {
          font-size: 0.78rem;
          color: #64748B;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.02em;
          transition: color 0.2s ease;
        }
        .facility-kpi-card:hover .fkc-label {
          color: rgba(255, 255, 255, 0.88) !important;
        }
        .facility-kpi-card .fkc-val {
          font-size: 1.75rem;
          font-weight: 800;
          color: #0F172A;
          margin-top: 0.25rem;
          line-height: 1.1;
          transition: color 0.2s ease;
        }
        .facility-kpi-card:hover .fkc-val {
          color: #FFFFFF !important;
        }
        .facility-kpi-card .fkc-icon-box {
          width: 44px;
          height: 44px;
          border-radius: 10px;
          background-color: #EFF6FF;
          color: #0F5FC2;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 800;
          font-size: 0.82rem;
          transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .facility-kpi-card:hover .fkc-icon-box {
          background-color: rgba(255, 255, 255, 0.22) !important;
          color: #FFFFFF !important;
          transform: scale(1.18) rotate(-6deg);
        }
        .facility-kpi-card .fkc-icon-box svg {
          transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .facility-kpi-card:hover .fkc-icon-box svg {
          transform: scale(1.12);
        }
      `}</style>

      {/* Metric Cards Banner */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}
      >
        <div className="facility-kpi-card">
          <div>
            <div className="fkc-label">Total Faskes Terdaftar</div>
            <div className="fkc-val" suppressHydrationWarning>{countAll}</div>
          </div>
          <div className="fkc-icon-box">
            <HospitalIcon size={22} />
          </div>
        </div>

        <div className="facility-kpi-card">
          <div>
            <div className="fkc-label">FKTP (Puskesmas / Klinik)</div>
            <div className="fkc-val" suppressHydrationWarning>{countFKTP}</div>
          </div>
          <div className="fkc-icon-box">
            FKTP
          </div>
        </div>

        <div className="facility-kpi-card">
          <div>
            <div className="fkc-label">FKRTL / RS Rujukan Retina</div>
            <div className="fkc-val" suppressHydrationWarning>{countFKRTL}</div>
          </div>
          <div className="fkc-icon-box">
            FKRTL
          </div>
        </div>

        <div className="facility-kpi-card">
          <div>
            <div className="fkc-label">Mitra Aktif BPJS Kesehatan</div>
            <div className="fkc-val" suppressHydrationWarning>{countBPJS}</div>
          </div>
          <div className="fkc-icon-box">
            <ShieldCheckIcon size={22} />
          </div>
        </div>
      </div>

      {/* Filter and Search Navigation Bar */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          padding: '0.85rem 1.2rem',
          marginBottom: '1.25rem',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '0.85rem',
        }}
      >
        {/* Category Tabs */}
        <div style={{ display: 'flex', gap: '0.4rem', backgroundColor: '#F1F5F9', padding: '0.25rem', borderRadius: '8px' }}>
          <button
            type="button"
            onClick={() => setCategoryFilter('ALL')}
            style={{
              padding: '0.4rem 0.85rem',
              borderRadius: '6px',
              fontSize: '0.82rem',
              fontWeight: 700,
              border: 'none',
              cursor: 'pointer',
              backgroundColor: categoryFilter === 'ALL' ? '#FFFFFF' : 'transparent',
              color: categoryFilter === 'ALL' ? '#0F172A' : '#64748B',
              boxShadow: categoryFilter === 'ALL' ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Semua Faskes ({countAll})
          </button>
          <button
            type="button"
            onClick={() => setCategoryFilter('FKTP')}
            style={{
              padding: '0.4rem 0.85rem',
              borderRadius: '6px',
              fontSize: '0.82rem',
              fontWeight: 700,
              border: 'none',
              cursor: 'pointer',
              backgroundColor: categoryFilter === 'FKTP' ? '#FFFFFF' : 'transparent',
              color: categoryFilter === 'FKTP' ? '#0D9488' : '#64748B',
              boxShadow: categoryFilter === 'FKTP' ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            FKTP (Puskesmas &amp; Klinik) ({countFKTP})
          </button>
          <button
            type="button"
            onClick={() => setCategoryFilter('FKRTL')}
            style={{
              padding: '0.4rem 0.85rem',
              borderRadius: '6px',
              fontSize: '0.82rem',
              fontWeight: 700,
              border: 'none',
              cursor: 'pointer',
              backgroundColor: categoryFilter === 'FKRTL' ? '#FFFFFF' : 'transparent',
              color: categoryFilter === 'FKRTL' ? '#4338CA' : '#64748B',
              boxShadow: categoryFilter === 'FKRTL' ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Faskes Rujukan (FKRTL) ({countFKRTL})
          </button>
        </div>

        {/* Search & BPJS Dropdown & Mode Toggle */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', flexWrap: 'wrap', flex: 1, justifyContent: 'flex-end' }}>
          <div style={{ position: 'relative', minWidth: '220px', maxWidth: '320px', width: '100%' }}>
            <span style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }}>
              <SearchIcon size={15} />
            </span>
            <input
              type="text"
              placeholder="Cari faskes, alamat, layanan..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%',
                padding: '0.42rem 0.75rem 0.42rem 2rem',
                borderRadius: '8px',
                border: '1px solid #CBD5E1',
                fontSize: '0.82rem',
                outline: 'none',
              }}
            />
          </div>

          <select
            value={bpjsFilter}
            onChange={(e) => setBpjsFilter(e.target.value)}
            style={{
              padding: '0.42rem 0.75rem',
              borderRadius: '8px',
              border: '1px solid #CBD5E1',
              fontSize: '0.82rem',
              backgroundColor: '#FFFFFF',
              color: '#334155',
              outline: 'none',
              fontWeight: 600,
            }}
          >
            <option value="ALL">Semua Status BPJS</option>
            <option value="ACCEPTED">Menerima BPJS</option>
            <option value="NEEDS_CONFIRMATION">Perlu Konfirmasi</option>
            <option value="NOT_AVAILABLE">Non-BPJS</option>
          </select>

          <div style={{ display: 'flex', border: '1px solid #CBD5E1', borderRadius: '8px', overflow: 'hidden' }}>
            <button
              type="button"
              onClick={() => setViewMode('cards')}
              style={{
                padding: '0.42rem 0.65rem',
                border: 'none',
                backgroundColor: viewMode === 'cards' ? '#0D47A1' : '#FFFFFF',
                color: viewMode === 'cards' ? '#FFFFFF' : '#64748B',
                cursor: 'pointer',
                fontSize: '0.78rem',
                fontWeight: 700,
              }}
            >
              Kartu
            </button>
            <button
              type="button"
              onClick={() => setViewMode('table')}
              style={{
                padding: '0.42rem 0.65rem',
                border: 'none',
                backgroundColor: viewMode === 'table' ? '#0D47A1' : '#FFFFFF',
                color: viewMode === 'table' ? '#FFFFFF' : '#64748B',
                cursor: 'pointer',
                fontSize: '0.78rem',
                fontWeight: 700,
              }}
            >
              Tabel
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '4rem 1rem', color: '#64748B' }}>
          <RotateCwIcon size={28} className="animate-spin" style={{ margin: '0 auto 0.75rem' }} />
          <p style={{ fontWeight: 600, fontSize: '0.9rem' }}>Memuat data fasilitas kesehatan dari database...</p>
        </div>
      ) : filteredFacilities.length === 0 ? (
        <div
          style={{
            backgroundColor: '#FFFFFF',
            border: '1.5px dashed #CBD5E1',
            borderRadius: '12px',
            padding: '3rem 2rem',
            textAlign: 'center',
          }}
        >
          <HospitalIcon size={40} style={{ color: '#94A3B8', margin: '0 auto 0.75rem' }} />
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#1E293B', margin: '0 0 0.4rem' }}>
            Tidak ada fasilitas kesehatan yang cocok
          </h3>
          <p style={{ fontSize: '0.85rem', color: '#64748B', maxWidth: '420px', margin: '0 auto 1.25rem' }}>
            Coba periksa kata kunci pencarian atau ubah filter kategori/status BPJS.
          </p>
          <button
            type="button"
            className="btn btn-primary btn-sm"
            onClick={handleOpenAddModal}
            style={{
              backgroundColor: '#0D47A1',
              color: '#FFFFFF',
              border: 'none',
              padding: '0.5rem 1rem',
              borderRadius: '8px',
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            + Tambah Fasilitas Baru
          </button>
        </div>
      ) : viewMode === 'cards' ? (
        /* CARDS GRID VIEW */
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))',
            gap: '1.15rem',
          }}
        >
          {filteredFacilities.map((f) => {
            const isFKTP = f.category === 'FKTP';
            return (
              <div
                key={f.id}
                style={{
                  backgroundColor: '#FFFFFF',
                  borderRadius: '14px',
                  border: isFKTP ? '1.5px solid #CCFBF1' : '1.5px solid #E0E7FF',
                  boxShadow: '0 2px 5px rgba(0,0,0,0.03)',
                  overflow: 'hidden',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.2s ease, box-shadow 0.2s ease',
                }}
              >
                {/* Card Top Banner */}
                <div
                  style={{
                    padding: '0.85rem 1.15rem',
                    backgroundColor: isFKTP ? '#F0FDFA' : '#F5F7FF',
                    borderBottom: '1px solid #E2E8F0',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span
                      style={{
                        padding: '0.2rem 0.55rem',
                        borderRadius: '6px',
                        fontSize: '0.72rem',
                        fontWeight: 800,
                        backgroundColor: isFKTP ? '#0D9488' : '#4338CA',
                        color: '#FFFFFF',
                        letterSpacing: '0.04em',
                      }}
                    >
                      {f.category}
                    </span>
                    <span
                      style={{
                        fontSize: '0.72rem',
                        fontWeight: 700,
                        color: isFKTP ? '#0F766E' : '#3730A3',
                      }}
                    >
                      {isFKTP ? 'Faskes Tingkat Pertama' : 'Faskes Rujukan (FKRTL)'}
                    </span>
                  </div>

                  {f.bpjsStatus === 'ACCEPTED' ? (
                    <span
                      style={{
                        padding: '0.2rem 0.55rem',
                        borderRadius: '6px',
                        fontSize: '0.7rem',
                        fontWeight: 700,
                        backgroundColor: '#DCFCE7',
                        color: '#15803D',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.25rem',
                      }}
                    >
                      <CheckIcon size={12} />
                      <span>BPJS Aktif</span>
                    </span>
                  ) : f.bpjsStatus === 'NEEDS_CONFIRMATION' ? (
                    <span
                      style={{
                        padding: '0.2rem 0.55rem',
                        borderRadius: '6px',
                        fontSize: '0.7rem',
                        fontWeight: 700,
                        backgroundColor: '#FEF9C3',
                        color: '#A16207',
                      }}
                    >
                      Perlu Konfirmasi
                    </span>
                  ) : (
                    <span
                      style={{
                        padding: '0.2rem 0.55rem',
                        borderRadius: '6px',
                        fontSize: '0.7rem',
                        fontWeight: 700,
                        backgroundColor: '#F1F5F9',
                        color: '#64748B',
                      }}
                    >
                      Non-BPJS
                    </span>
                  )}
                </div>

                {/* Card Body */}
                <div style={{ padding: '1.15rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem', marginBottom: '0.75rem' }}>
                    <div
                      style={{
                        width: '38px',
                        height: '38px',
                        borderRadius: '10px',
                        backgroundColor: isFKTP ? '#E6FFFA' : '#EEF2FF',
                        color: isFKTP ? '#0D9488' : '#4338CA',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                      }}
                    >
                      <HospitalIcon size={20} />
                    </div>
                    <div>
                      <h3 style={{ fontSize: '1.02rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                        {f.name}
                      </h3>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.25rem' }}>
                        {f.isVerified && (
                          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.2rem', fontSize: '0.7rem', color: '#0284C7', fontWeight: 700 }}>
                            <ShieldCheckIcon size={12} />
                            <span>Terverifikasi Kemenkes</span>
                          </span>
                        )}
                        <span style={{ fontSize: '0.7rem', color: '#94A3B8' }}>• ID: {f.id}</span>
                      </div>
                    </div>
                  </div>

                  {/* Address */}
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.45rem', fontSize: '0.8rem', color: '#475569', marginBottom: '0.5rem' }}>
                    <MapPinIcon size={14} style={{ color: '#94A3B8', marginTop: '2px', flexShrink: 0 }} />
                    <span style={{ lineHeight: '1.35' }}>{f.address}</span>
                  </div>

                  {/* Phone & Coordinates */}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.85rem', fontSize: '0.78rem', color: '#64748B', marginBottom: '0.85rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
                      <PhoneIcon size={13} style={{ color: '#0284C7' }} />
                      <span>{f.contactPhone}</span>
                    </div>
                    <div>
                      <span>Koordinat: </span>
                      <a
                        href={`https://maps.google.com/?q=${f.latitude},${f.longitude}`}
                        target="_blank"
                        rel="noreferrer"
                        style={{ color: '#0D47A1', fontWeight: 600, textDecoration: 'none' }}
                      >
                        {f.latitude.toFixed(4)}, {f.longitude.toFixed(4)} ↗
                      </a>
                    </div>
                  </div>

                  {/* Services Tags */}
                  <div style={{ marginTop: 'auto', paddingTop: '0.75rem', borderTop: '1px solid #F1F5F9' }}>
                    <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#64748B', marginBottom: '0.35rem', textTransform: 'uppercase' }}>
                      Layanan &amp; Kemampuan Medis:
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.35rem' }}>
                      {f.services.map((srv, idx) => (
                        <span
                          key={idx}
                          style={{
                            padding: '0.2rem 0.5rem',
                            borderRadius: '5px',
                            fontSize: '0.68rem',
                            fontWeight: 600,
                            backgroundColor: '#F8FAFC',
                            color: '#334155',
                            border: '1px solid #E2E8F0',
                          }}
                        >
                          {srv.replace(/_/g, ' ')}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Insurances Tags */}
                  <div style={{ marginTop: '0.65rem' }}>
                    <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#64748B', marginBottom: '0.25rem', textTransform: 'uppercase' }}>
                      Jaminan / Asuransi Rekanan:
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.35rem' }}>
                      {f.insurances.map((ins, idx) => (
                        <span
                          key={idx}
                          style={{
                            padding: '0.15rem 0.45rem',
                            borderRadius: '4px',
                            fontSize: '0.65rem',
                            fontWeight: 700,
                            backgroundColor: ins === 'BPJS_KESEHATAN' ? '#ECFDF5' : '#F1F5F9',
                            color: ins === 'BPJS_KESEHATAN' ? '#047857' : '#475569',
                            border: `1px solid ${ins === 'BPJS_KESEHATAN' ? '#A7F3D0' : '#E2E8F0'}`,
                          }}
                        >
                          {ins.replace(/_/g, ' ')}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Card Actions */}
                <div
                  style={{
                    padding: '0.75rem 1.15rem',
                    backgroundColor: '#FAFAFA',
                    borderTop: '1px solid #E2E8F0',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-end',
                    gap: '0.5rem',
                  }}
                >
                  <button
                    type="button"
                    onClick={() => handleOpenEditModal(f)}
                    style={{
                      padding: '0.35rem 0.75rem',
                      borderRadius: '6px',
                      fontSize: '0.78rem',
                      fontWeight: 600,
                      border: '1px solid #CBD5E1',
                      backgroundColor: '#FFFFFF',
                      color: '#0D47A1',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.3rem',
                    }}
                  >
                    <EditIcon size={13} />
                    <span>Ubah</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setDeletingFacility(f)}
                    style={{
                      padding: '0.35rem 0.75rem',
                      borderRadius: '6px',
                      fontSize: '0.78rem',
                      fontWeight: 600,
                      border: '1px solid #FCA5A5',
                      backgroundColor: '#FEF2F2',
                      color: '#DC2626',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.3rem',
                    }}
                  >
                    <TrashIcon size={13} />
                    <span>Hapus</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* TABLE VIEW */
        <div
          style={{
            backgroundColor: '#FFFFFF',
            borderRadius: '12px',
            border: '1px solid #E2E8F0',
            overflow: 'hidden',
            boxShadow: '0 1px 3px rgba(0,0,0,0.03)',
          }}
        >
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.84rem' }}>
              <thead>
                <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '1.5px solid #E2E8F0', color: '#475569', fontSize: '0.78rem', textTransform: 'uppercase' }}>
                  <th style={{ padding: '0.85rem 1rem' }}>Fasilitas Kesehatan</th>
                  <th style={{ padding: '0.85rem 1rem' }}>Tingkat (Kategori)</th>
                  <th style={{ padding: '0.85rem 1rem' }}>Status BPJS</th>
                  <th style={{ padding: '0.85rem 1rem' }}>Alamat &amp; Kontak</th>
                  <th style={{ padding: '0.85rem 1rem' }}>Layanan Unggulan</th>
                  <th style={{ padding: '0.85rem 1rem', textAlign: 'right' }}>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredFacilities.map((f, idx) => {
                  const isFKTP = f.category === 'FKTP';
                  return (
                    <tr
                      key={f.id}
                      style={{
                        borderBottom: '1px solid #E2E8F0',
                        backgroundColor: idx % 2 === 0 ? '#FFFFFF' : '#FBFDFF',
                      }}
                    >
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <div style={{ fontWeight: 800, color: '#0F172A' }}>{f.name}</div>
                        <div style={{ fontSize: '0.72rem', color: '#94A3B8' }}>{f.id}</div>
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <span
                          style={{
                            padding: '0.2rem 0.55rem',
                            borderRadius: '6px',
                            fontSize: '0.72rem',
                            fontWeight: 800,
                            backgroundColor: isFKTP ? '#CCFBF1' : '#EEF2FF',
                            color: isFKTP ? '#0F766E' : '#3730A3',
                          }}
                        >
                          {f.category}
                        </span>
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        {f.bpjsStatus === 'ACCEPTED' ? (
                          <span style={{ padding: '0.2rem 0.5rem', borderRadius: '4px', fontSize: '0.72rem', fontWeight: 700, backgroundColor: '#DCFCE7', color: '#15803D' }}>
                            Menerima BPJS
                          </span>
                        ) : (
                          <span style={{ padding: '0.2rem 0.5rem', borderRadius: '4px', fontSize: '0.72rem', fontWeight: 700, backgroundColor: '#FEF9C3', color: '#A16207' }}>
                            Perlu Konfirmasi
                          </span>
                        )}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', maxWidth: '300px' }}>
                        <div style={{ fontSize: '0.78rem', color: '#334155', lineHeight: '1.3' }}>{f.address}</div>
                        <div style={{ fontSize: '0.72rem', color: '#0284C7', marginTop: '0.2rem' }}>📞 {f.contactPhone}</div>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', maxWidth: '260px' }}>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.25rem' }}>
                          {f.services.slice(0, 3).map((s, i) => (
                            <span key={i} style={{ fontSize: '0.68rem', backgroundColor: '#F1F5F9', padding: '0.15rem 0.4rem', borderRadius: '4px' }}>
                              {s.replace(/_/g, ' ')}
                            </span>
                          ))}
                          {f.services.length > 3 && (
                            <span style={{ fontSize: '0.68rem', color: '#64748B' }}>+{f.services.length - 3}</span>
                          )}
                        </div>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: '0.4rem' }}>
                          <button
                            type="button"
                            onClick={() => handleOpenEditModal(f)}
                            style={{
                              padding: '0.3rem 0.6rem',
                              borderRadius: '6px',
                              fontSize: '0.75rem',
                              border: '1px solid #CBD5E1',
                              backgroundColor: '#FFFFFF',
                              color: '#0D47A1',
                              cursor: 'pointer',
                            }}
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            onClick={() => setDeletingFacility(f)}
                            style={{
                              padding: '0.3rem 0.6rem',
                              borderRadius: '6px',
                              fontSize: '0.75rem',
                              border: '1px solid #FCA5A5',
                              backgroundColor: '#FEF2F2',
                              color: '#DC2626',
                              cursor: 'pointer',
                            }}
                          >
                            Hapus
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* MODAL TAMBAH / UBAH FASILITAS */}
      {(isAddModalOpen || editingFacility) && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.6)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1rem',
            backdropFilter: 'blur(3px)',
          }}
        >
          <div
            style={{
              backgroundColor: '#FFFFFF',
              borderRadius: '16px',
              maxWidth: '680px',
              width: '100%',
              maxHeight: '90vh',
              overflowY: 'auto',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            }}
          >
            {/* Modal Header */}
            <div
              style={{
                padding: '1.25rem 1.5rem',
                borderBottom: '1px solid #E2E8F0',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '8px',
                    backgroundColor: '#EFF6FF',
                    color: '#0D47A1',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <HospitalIcon size={18} />
                </div>
                <h3 style={{ fontSize: '1.15rem', fontWeight: 800, margin: 0, color: '#0F172A' }}>
                  {editingFacility ? 'Ubah Data Fasilitas Kesehatan' : 'Tambah Fasilitas Kesehatan Baru'}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsAddModalOpen(false);
                  setEditingFacility(null);
                }}
                style={{ background: 'none', border: 'none', color: '#94A3B8', cursor: 'pointer', padding: 4 }}
              >
                <XIcon size={20} />
              </button>
            </div>

            {/* Modal Body / Form */}
            <form onSubmit={handleSaveFacility} style={{ padding: '1.5rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1rem', marginBottom: '1rem' }}>
                {/* Nama Faskes */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Nama Fasilitas Kesehatan *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Contoh: Puskesmas Mlati II (FKTP) atau RSUP Dr. Sardjito"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '0.55rem 0.85rem',
                      borderRadius: '8px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '0.88rem',
                      outline: 'none',
                    }}
                  />
                </div>

                {/* Kategori Faskes */}
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Kategori Tingkat Faskes *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value as any })}
                    style={{
                      width: '100%',
                      padding: '0.55rem 0.85rem',
                      borderRadius: '8px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '0.88rem',
                      backgroundColor: '#FFFFFF',
                      outline: 'none',
                    }}
                  >
                    <option value="FKTP">FKTP (Puskesmas / Klinik Pratama)</option>
                    <option value="FKRTL">FKRTL (Rumah Sakit Rujukan Retina)</option>
                  </select>
                </div>

                {/* Status BPJS */}
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Status Penerimaan BPJS / JKN *
                  </label>
                  <select
                    value={formData.bpjsStatus}
                    onChange={(e) => setFormData({ ...formData, bpjsStatus: e.target.value as any })}
                    style={{
                      width: '100%',
                      padding: '0.55rem 0.85rem',
                      borderRadius: '8px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '0.88rem',
                      backgroundColor: '#FFFFFF',
                      outline: 'none',
                    }}
                  >
                    <option value="ACCEPTED">Menerima Rujukan BPJS (Aktif)</option>
                    <option value="NEEDS_CONFIRMATION">Perlu Konfirmasi Pasien / Faskes</option>
                    <option value="NOT_AVAILABLE">Tidak Menerima BPJS</option>
                  </select>
                </div>

                {/* Alamat Lengkap */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Alamat Lengkap *
                  </label>
                  <textarea
                    required
                    rows={2}
                    placeholder="Alamat jalan, kelurahan/desa, kecamatan, kabupaten..."
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '0.55rem 0.85rem',
                      borderRadius: '8px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '0.85rem',
                      outline: 'none',
                    }}
                  />
                </div>

                {/* Nomor Telepon */}
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                    Nomor Telepon / Call Center
                  </label>
                  <input
                    type="text"
                    placeholder="Contoh: (0274) 631190"
                    value={formData.contactPhone}
                    onChange={(e) => setFormData({ ...formData, contactPhone: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '0.55rem 0.85rem',
                      borderRadius: '8px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '0.85rem',
                      outline: 'none',
                    }}
                  />
                </div>

                {/* Koordinat Lat/Long */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Latitude
                    </label>
                    <input
                      type="text"
                      placeholder="-7.7686"
                      value={formData.latitude}
                      onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '0.55rem 0.65rem',
                        borderRadius: '8px',
                        border: '1.5px solid #CBD5E1',
                        fontSize: '0.85rem',
                        outline: 'none',
                      }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.35rem' }}>
                      Longitude
                    </label>
                    <input
                      type="text"
                      placeholder="110.3737"
                      value={formData.longitude}
                      onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '0.55rem 0.65rem',
                        borderRadius: '8px',
                        border: '1.5px solid #CBD5E1',
                        fontSize: '0.85rem',
                        outline: 'none',
                      }}
                    />
                  </div>
                </div>
              </div>

              {/* Layanan Medis Selector */}
              <div style={{ marginBottom: '1.25rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.45rem' }}>
                  Layanan &amp; Fasilitas Terkait Retinopati / Mata:
                </label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.45rem' }}>
                  {COMMON_SERVICES.map((srv) => {
                    const checked = formData.services.includes(srv.key);
                    return (
                      <label
                        key={srv.key}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.45rem',
                          padding: '0.45rem 0.65rem',
                          borderRadius: '6px',
                          border: checked ? '1.5px solid #0D47A1' : '1px solid #E2E8F0',
                          backgroundColor: checked ? '#EFF6FF' : '#FFFFFF',
                          cursor: 'pointer',
                          fontSize: '0.78rem',
                          fontWeight: checked ? 700 : 500,
                          color: checked ? '#0D47A1' : '#334155',
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() => toggleService(srv.key)}
                          style={{ cursor: 'pointer' }}
                        />
                        <span>{srv.label}</span>
                      </label>
                    );
                  })}
                </div>
              </div>

              {/* Asuransi Selector */}
              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: '0.45rem' }}>
                  Asuransi Rekanan:
                </label>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                  {COMMON_INSURANCES.map((ins) => {
                    const checked = formData.insurances.includes(ins);
                    return (
                      <label
                        key={ins}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.4rem',
                          padding: '0.4rem 0.75rem',
                          borderRadius: '6px',
                          border: checked ? '1.5px solid #059669' : '1px solid #E2E8F0',
                          backgroundColor: checked ? '#ECFDF5' : '#FFFFFF',
                          cursor: 'pointer',
                          fontSize: '0.78rem',
                          fontWeight: checked ? 700 : 500,
                          color: checked ? '#059669' : '#334155',
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() => toggleInsurance(ins)}
                          style={{ cursor: 'pointer' }}
                        />
                        <span>{ins.replace(/_/g, ' ')}</span>
                      </label>
                    );
                  })}
                </div>
              </div>

              {/* Modal Footer Actions */}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'flex-end',
                  gap: '0.65rem',
                  borderTop: '1px solid #E2E8F0',
                  paddingTop: '1rem',
                }}
              >
                <button
                  type="button"
                  onClick={() => {
                    setIsAddModalOpen(false);
                    setEditingFacility(null);
                  }}
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '8px',
                    border: '1px solid #CBD5E1',
                    backgroundColor: '#FFFFFF',
                    color: '#64748B',
                    fontWeight: 600,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                  }}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  style={{
                    padding: '0.5rem 1.25rem',
                    borderRadius: '8px',
                    border: 'none',
                    backgroundColor: '#0D47A1',
                    color: '#FFFFFF',
                    fontWeight: 700,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.4rem',
                  }}
                >
                  {isSubmitting && <RotateCwIcon size={14} className="animate-spin" />}
                  <span>{editingFacility ? 'Simpan Perubahan' : 'Tambahkan Faskes'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL KONFIRMASI HAPUS */}
      {deletingFacility && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.6)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1rem',
            backdropFilter: 'blur(3px)',
          }}
        >
          <div
            style={{
              backgroundColor: '#FFFFFF',
              borderRadius: '16px',
              maxWidth: '440px',
              width: '100%',
              padding: '1.5rem',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            }}
          >
            <div
              style={{
                width: '44px',
                height: '44px',
                borderRadius: '12px',
                backgroundColor: '#FEE2E2',
                color: '#DC2626',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '1rem',
              }}
            >
              <AlertTriangleIcon size={24} />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#0F172A', margin: '0 0 0.5rem' }}>
              Hapus Fasilitas Kesehatan?
            </h3>
            <p style={{ fontSize: '0.85rem', color: '#64748B', lineHeight: '1.45', margin: '0 0 1.25rem' }}>
              Apakah Anda yakin ingin menghapus data <strong>&quot;{deletingFacility.name}&quot;</strong> dari master data? Fasilitas ini tidak akan lagi muncul dalam rekomendasi rujukan.
            </p>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem' }}>
              <button
                type="button"
                onClick={() => setDeletingFacility(null)}
                style={{
                  padding: '0.5rem 1rem',
                  borderRadius: '8px',
                  border: '1px solid #CBD5E1',
                  backgroundColor: '#FFFFFF',
                  color: '#64748B',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  cursor: 'pointer',
                }}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleDeleteFacility}
                disabled={isSubmitting}
                style={{
                  padding: '0.5rem 1.15rem',
                  borderRadius: '8px',
                  border: 'none',
                  backgroundColor: '#DC2626',
                  color: '#FFFFFF',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  cursor: 'pointer',
                }}
              >
                {isSubmitting ? 'Menghapus...' : 'Ya, Hapus Faskes'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
