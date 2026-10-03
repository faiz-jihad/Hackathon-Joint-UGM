import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { SearchIcon, ClockIcon, CheckIcon, XIcon } from './Icons';

interface DoctorStatusCheckModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialEmail?: string;
}

export function DoctorStatusCheckModal({
  isOpen,
  onClose,
  initialEmail = '',
}: DoctorStatusCheckModalProps) {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState<string>(initialEmail);
  const [searchResult, setSearchResult] = useState<any | null>(null);
  const [hasSearched, setHasSearched] = useState<boolean>(false);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  if (!isOpen) return null;

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const query = searchQuery.trim().toLowerCase();
    if (!query) return;

    setIsSearching(true);
    setHasSearched(false);

    setTimeout(() => {
      try {
        const stored = localStorage.getItem('retiva_doctor_verifications');
        if (stored) {
          const apps = JSON.parse(stored);
          if (Array.isArray(apps)) {
            const found = apps.find(
              (a: any) =>
                (a.email && a.email.toLowerCase() === query) ||
                (a.sipNumber && a.sipNumber.toLowerCase().includes(query)) ||
                (a.fullName && a.fullName.toLowerCase().includes(query))
            );
            setSearchResult(found || null);
          } else {
            setSearchResult(null);
          }
        } else {
          setSearchResult(null);
        }
      } catch {
        setSearchResult(null);
      } finally {
        setIsSearching(false);
        setHasSearched(true);
      }
    }, 400);
  };

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(10, 15, 29, 0.75)',
        backdropFilter: 'blur(6px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 999999,
        padding: '1.25rem',
        animation: 'fadeIn 0.2s ease',
      }}
      onClick={onClose}
    >
      <div
        style={{
          backgroundColor: '#0F172A',
          border: '1px solid rgba(33, 150, 243, 0.3)',
          boxShadow: '0 25px 60px -15px rgba(0, 0, 0, 0.7), 0 0 30px rgba(33, 150, 243, 0.15)',
          borderRadius: '18px',
          maxWidth: '560px',
          width: '100%',
          maxHeight: '92vh',
          overflowY: 'auto',
          padding: '2rem',
          color: '#FFFFFF',
          position: 'relative',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          type="button"
          onClick={onClose}
          style={{
            position: 'absolute',
            top: '1.25rem',
            right: '1.25rem',
            background: 'none',
            border: 'none',
            color: '#94A3B8',
            fontSize: '1.25rem',
            cursor: 'pointer',
            padding: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
          title="Tutup Modal"
        >
          ✕
        </button>

        {/* Modal Header */}
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <div
            style={{
              width: '52px',
              height: '52px',
              borderRadius: '50%',
              backgroundColor: 'rgba(33, 150, 243, 0.15)',
              color: '#2196F3',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 0.85rem auto',
              border: '1.5px solid rgba(33, 150, 243, 0.35)',
            }}
          >
            <SearchIcon size={24} style={{ color: '#2196F3' }} />
          </div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#FFFFFF' }}>
            Cek Status Pendaftaran Dokter
          </h2>
          <p style={{ fontSize: '0.8125rem', color: '#94A3B8', marginTop: '0.35rem', lineHeight: 1.5 }}>
            Ketahui apakah akun dokter Anda sedang ditinjau, telah disetujui, atau perlu perbaikan berkas.
          </p>
        </div>

        {/* Search Input Form */}
        <form onSubmit={handleSearch} style={{ marginBottom: '1.5rem' }}>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Masukkan Email pendaftaran atau No. SIP..."
              required
              style={{
                flex: 1,
                padding: '0.75rem 1rem',
                backgroundColor: 'rgba(255, 255, 255, 0.06)',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                borderRadius: '10px',
                color: '#FFFFFF',
                fontSize: '0.85rem',
                outline: 'none',
              }}
            />
            <button
              type="submit"
              disabled={isSearching}
              style={{
                backgroundColor: '#2196F3',
                color: '#FFFFFF',
                border: 'none',
                borderRadius: '10px',
                padding: '0.75rem 1.25rem',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                whiteSpace: 'nowrap',
              }}
            >
              {isSearching ? 'Memeriksa...' : 'Cari Status'}
            </button>
          </div>
        </form>

        {/* Search Result Display */}
        {hasSearched && (
          <div>
            {searchResult ? (
              <div
                style={{
                  backgroundColor: 'rgba(255, 255, 255, 0.04)',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  borderRadius: '14px',
                  padding: '1.25rem',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '1rem',
                }}
              >
                {/* Result Status Badge */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>STATUS VERIFIKASI</div>
                    <div style={{ fontSize: '1.05rem', fontWeight: 800, color: '#FFFFFF', marginTop: '0.15rem' }}>
                      {searchResult.fullName}
                    </div>
                  </div>

                  {searchResult.status === 'PENDING' && (
                    <div
                      style={{
                        backgroundColor: 'rgba(245, 158, 11, 0.12)',
                        color: '#FCD34D',
                        border: '1px solid rgba(245, 158, 11, 0.3)',
                        padding: '0.45rem 0.85rem',
                        borderRadius: '8px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.45rem',
                      }}
                    >
                      <ClockIcon size={14} style={{ color: '#FBBF24' }} />
                      <span>Menunggu Verifikasi (PENDING)</span>
                    </div>
                  )}

                  {searchResult.status === 'VERIFIED' && (
                    <div
                      style={{
                        backgroundColor: 'rgba(16, 185, 129, 0.12)',
                        color: '#6EE7B7',
                        border: '1px solid rgba(16, 185, 129, 0.3)',
                        padding: '0.45rem 0.85rem',
                        borderRadius: '8px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.45rem',
                      }}
                    >
                      <CheckIcon size={14} style={{ color: '#34D399' }} />
                      <span>Disetujui (VALID)</span>
                    </div>
                  )}

                  {searchResult.status === 'REJECTED' && (
                    <div
                      style={{
                        backgroundColor: 'rgba(239, 68, 68, 0.12)',
                        color: '#FCA5A5',
                        border: '1px solid rgba(239, 68, 68, 0.3)',
                        padding: '0.45rem 0.85rem',
                        borderRadius: '8px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.45rem',
                      }}
                    >
                      <XIcon size={14} style={{ color: '#F87171' }} />
                      <span>Ditolak (Tidak Valid)</span>
                    </div>
                  )}
                </div>

                {/* Credentials Details */}
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: '0.75rem',
                    fontSize: '0.8rem',
                    backgroundColor: 'rgba(0, 0, 0, 0.25)',
                    padding: '0.85rem',
                    borderRadius: '10px',
                    border: '1px solid rgba(255, 255, 255, 0.06)',
                  }}
                >
                  <div>
                    <div style={{ color: '#94A3B8', fontSize: '0.7rem' }}>Email:</div>
                    <div style={{ color: '#E2E8F0', fontWeight: 600 }}>{searchResult.email}</div>
                  </div>
                  <div>
                    <div style={{ color: '#94A3B8', fontSize: '0.7rem' }}>No. SIP:</div>
                    <div style={{ color: '#2196F3', fontWeight: 600 }}><code>{searchResult.sipNumber}</code></div>
                  </div>
                  <div>
                    <div style={{ color: '#94A3B8', fontSize: '0.7rem' }}>Fasilitas Kesehatan:</div>
                    <div style={{ color: '#E2E8F0' }}>{searchResult.primaryFacility}</div>
                  </div>
                  <div>
                    <div style={{ color: '#94A3B8', fontSize: '0.7rem' }}>Spesialisasi Medis:</div>
                    <div style={{ color: '#E2E8F0', fontWeight: 600 }}>{searchResult.subSpecialty || 'Dokter Umum'}</div>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <div style={{ color: '#94A3B8', fontSize: '0.7rem' }}>Tanggal Pengajuan:</div>
                    <div style={{ color: '#E2E8F0' }}>
                      {new Date(searchResult.submittedAt).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </div>
                  </div>
                </div>

                {/* Detailed Status Guidance Message */}
                {searchResult.status === 'PENDING' && (
                  <div
                    style={{
                      padding: '0.85rem',
                      backgroundColor: 'rgba(245, 158, 11, 0.08)',
                      border: '1px solid rgba(245, 158, 11, 0.25)',
                      borderRadius: '10px',
                      color: '#FDE68A',
                      fontSize: '0.8rem',
                      lineHeight: 1.5,
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: '0.55rem',
                    }}
                  >
                    <ClockIcon size={16} style={{ color: '#FBBF24', flexShrink: 0, marginTop: '2px' }} />
                    <div>
                      <strong>Sedang Ditinjau Admin:</strong> Berkas SIP &amp; STR Anda saat ini berada dalam antrean pemeriksaan oleh Administrator RETIVA. Anda dapat masuk ke dashboard klinis setelah akun disetujui.
                    </div>
                  </div>
                )}

                {searchResult.status === 'VERIFIED' && (
                  <div
                    style={{
                      padding: '0.85rem',
                      backgroundColor: 'rgba(16, 185, 129, 0.08)',
                      border: '1px solid rgba(16, 185, 129, 0.25)',
                      borderRadius: '10px',
                      color: '#A7F3D0',
                      fontSize: '0.8rem',
                      lineHeight: 1.5,
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: '0.55rem',
                    }}
                  >
                    <CheckIcon size={16} style={{ color: '#34D399', flexShrink: 0, marginTop: '2px' }} />
                    <div>
                      <strong>Selamat, Akun Telah Aktif!</strong> Kredensial medis Anda telah disetujui. Silakan masuk menggunakan email dan kata sandi yang Anda daftarkan.
                    </div>
                  </div>
                )}

                {searchResult.status === 'REJECTED' && (
                  <div
                    style={{
                      padding: '0.85rem',
                      backgroundColor: 'rgba(239, 68, 68, 0.08)',
                      border: '1px solid rgba(239, 68, 68, 0.25)',
                      borderRadius: '10px',
                      color: '#FECACA',
                      fontSize: '0.8rem',
                      lineHeight: 1.5,
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: '0.55rem',
                    }}
                  >
                    <XIcon size={16} style={{ color: '#F87171', flexShrink: 0, marginTop: '2px' }} />
                    <div>
                      <strong>Pendaftaran Ditolak:</strong> {searchResult.verificationNotes || 'Dokumen kredensial SIP/STR tidak memenuhi persyaratan verifikasi.'}
                    </div>
                  </div>
                )}

                {/* Action button inside result */}
                {searchResult.status === 'VERIFIED' && (
                  <button
                    type="button"
                    onClick={() => {
                      onClose();
                      router.push('/login/dokter');
                    }}
                    style={{
                      backgroundColor: '#2196F3',
                      color: '#FFFFFF',
                      border: 'none',
                      borderRadius: '8px',
                      padding: '0.65rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      fontSize: '0.825rem',
                    }}
                  >
                    Masuk ke Akun Dokter Sekarang
                  </button>
                )}

                {searchResult.status === 'REJECTED' && (
                  <button
                    type="button"
                    onClick={() => {
                      onClose();
                      router.push('/daftar/dokter');
                    }}
                    style={{
                      backgroundColor: 'transparent',
                      color: '#2196F3',
                      border: '1px solid rgba(33, 150, 243, 0.4)',
                      borderRadius: '8px',
                      padding: '0.65rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      fontSize: '0.825rem',
                    }}
                  >
                    Ajukan Pendaftaran Ulang dengan Dokumen Valid
                  </button>
                )}
              </div>
            ) : (
              <div
                style={{
                  padding: '1.75rem',
                  textAlign: 'center',
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid rgba(255, 255, 255, 0.08)',
                  borderRadius: '14px',
                }}
              >
                <div style={{ fontSize: '1.75rem', marginBottom: '0.5rem' }}>⚠️</div>
                <div style={{ fontWeight: 700, fontSize: '0.95rem', color: '#FFFFFF' }}>
                  Data Pendaftaran Tidak Ditemukan
                </div>
                <p style={{ fontSize: '0.8rem', color: '#94A3B8', marginTop: '0.35rem', lineHeight: 1.5 }}>
                  Tidak ditemukan permohonan dengan kata kunci <strong>"{searchQuery}"</strong>. Pastikan email atau nomor SIP yang Anda ketikkan sesuai dengan yang didaftarkan.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    router.push('/daftar/dokter');
                  }}
                  style={{
                    marginTop: '1rem',
                    backgroundColor: 'transparent',
                    color: '#2196F3',
                    border: '1px solid rgba(33, 150, 243, 0.3)',
                    borderRadius: '8px',
                    padding: '0.5rem 1rem',
                    fontSize: '0.78rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  Daftarkan Akun Dokter Baru
                </button>
              </div>
            )}
          </div>
        )}

        {/* Footer Guidance */}
        <div style={{ marginTop: '1.5rem', textAlign: 'center' }}>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              color: '#94A3B8',
              fontSize: '0.8rem',
              cursor: 'pointer',
              textDecoration: 'underline',
            }}
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}
