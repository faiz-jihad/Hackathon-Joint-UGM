import React, { useState } from 'react';
import {
  ShieldCheckIcon,
  CheckIcon,
  XIcon,
  ClockIcon,
  AlertTriangleIcon,
} from './Icons';

interface ForgotPasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultEmail?: string;
  onSuccess: (email: string) => void;
}

export function formatRoleLabel(role?: string): string {
  if (!role) return '';
  const r = role.toUpperCase();
  if (r === 'OPHTHALMOLOGIST' || r === 'DOKTER') return 'DOKTER';
  if (r === 'PATIENT' || r === 'PENGGUNA') return 'PENGGUNA';
  if (r === 'ADMIN') return 'ADMIN';
  return role;
}

export function ForgotPasswordModal({
  isOpen,
  onClose,
  defaultEmail = '',
  onSuccess,
}: ForgotPasswordModalProps) {
  const [step, setStep] = useState<'EMAIL' | 'OTP' | 'SUCCESS'>('EMAIL');
  const [email, setEmail] = useState<string>(defaultEmail);
  const [otp, setOtp] = useState<string>('');
  const [newPassword, setNewPassword] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string>('');
  const [userInfo, setUserInfo] = useState<{ fullName: string; role: string } | null>(null);

  if (!isOpen) return null;

  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail) {
      setErrorMessage('Silakan masukkan alamat email yang terdaftar.');
      return;
    }

    setIsLoading(true);
    setErrorMessage('');

    try {
      const res = await fetch('/api/v1/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'REQUEST_OTP',
          email: cleanEmail,
        }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        setErrorMessage(data?.error?.message || 'Email tidak ditemukan di sistem RETIVA.');
        setIsLoading(false);
        return;
      }

      setUserInfo({
        fullName: data.data?.fullName || 'Pengguna Terdaftar',
        role: formatRoleLabel(data.data?.role || 'PENGGUNA'),
      });
      setStep('OTP');
    } catch (err: any) {
      setErrorMessage(err?.message || 'Terjadi kesalahan koneksi.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    if (!otp.trim()) {
      setErrorMessage('Silakan masukkan 6 digit kode OTP.');
      return;
    }

    if (newPassword.length < 6) {
      setErrorMessage('Kata sandi baru minimal terdiri dari 6 karakter.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setErrorMessage('Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setIsLoading(true);

    try {
      const res = await fetch('/api/v1/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'RESET_PASSWORD',
          email: email.trim().toLowerCase(),
          otp: otp.trim(),
          newPassword,
        }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        setErrorMessage(data?.error?.message || 'Gagal mengatur ulang kata sandi.');
        setIsLoading(false);
        return;
      }

      setStep('SUCCESS');
    } catch (err: any) {
      setErrorMessage(err?.message || 'Terjadi kesalahan sistem.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleFinish = () => {
    onSuccess(email.trim().toLowerCase());
    onClose();
  };

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(10, 15, 29, 0.82)',
        backdropFilter: 'blur(8px)',
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
          width: '100%',
          maxWidth: '520px',
          background: 'linear-gradient(165deg, rgba(15, 23, 42, 0.98) 0%, rgba(10, 25, 47, 0.99) 100%)',
          border: '1px solid rgba(33, 150, 243, 0.35)',
          borderRadius: '20px',
          boxShadow: '0 25px 60px -15px rgba(0, 0, 0, 0.75), 0 0 35px rgba(33, 150, 243, 0.15)',
          overflow: 'hidden',
          color: '#F8FAFC',
          position: 'relative',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          style={{
            padding: '1.5rem 1.75rem',
            borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '10px',
                backgroundColor: 'rgba(33, 150, 243, 0.15)',
                border: '1px solid rgba(33, 150, 243, 0.3)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#60A5FA',
              }}
            >
              <ShieldCheckIcon size={22} />
            </div>
            <div>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: '#FFFFFF' }}>
                Pemulihan Kata Sandi
              </h2>
              <div style={{ fontSize: '0.75rem', color: '#94A3B8', marginTop: '2px' }}>
                Verifikasi identitas dan atur ulang kata sandi akun RETIVA
              </div>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              color: '#94A3B8',
              cursor: 'pointer',
              padding: '6px',
              borderRadius: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <XIcon size={20} />
          </button>
        </div>

        {/* Content Body */}
        <div style={{ padding: '1.75rem' }}>
          {errorMessage && (
            <div
              style={{
                padding: '0.75rem 1rem',
                backgroundColor: 'rgba(239, 68, 68, 0.12)',
                border: '1px solid rgba(239, 68, 68, 0.35)',
                borderRadius: '10px',
                marginBottom: '1.25rem',
                display: 'flex',
                alignItems: 'flex-start',
                gap: '0.65rem',
              }}
            >
              <AlertTriangleIcon size={18} style={{ color: '#F87171', flexShrink: 0, marginTop: '2px' }} />
              <div style={{ fontSize: '0.825rem', color: '#FCA5A5', lineHeight: 1.4 }}>
                {errorMessage}
              </div>
            </div>
          )}

          {/* STEP 1: EMAIL INPUT */}
          {step === 'EMAIL' && (
            <form onSubmit={handleRequestOtp}>
              <p style={{ fontSize: '0.85rem', color: '#CBD5E1', marginBottom: '1.25rem', lineHeight: 1.5 }}>
                Masukkan alamat email yang terdaftar pada akun Anda. Sistem akan memeriksa ketersediaan akun dan mengirimkan kode OTP verifikasi keamanan.
              </p>

              <div style={{ marginBottom: '1.25rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#94A3B8', marginBottom: '0.45rem' }}>
                  Alamat Email Terdaftar
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nama@domain.com"
                  required
                  autoFocus
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    borderRadius: '10px',
                    backgroundColor: 'rgba(15, 23, 42, 0.6)',
                    border: '1px solid rgba(255, 255, 255, 0.12)',
                    color: '#FFFFFF',
                    fontSize: '0.9rem',
                    outline: 'none',
                    transition: 'border-color 0.2s',
                  }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.75rem' }}>
                <button
                  type="button"
                  onClick={onClose}
                  style={{
                    padding: '0.65rem 1.25rem',
                    borderRadius: '8px',
                    backgroundColor: 'transparent',
                    border: '1px solid rgba(255, 255, 255, 0.15)',
                    color: '#94A3B8',
                    fontSize: '0.875rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isLoading}
                  style={{
                    padding: '0.65rem 1.4rem',
                    borderRadius: '8px',
                    backgroundColor: '#0284C7',
                    border: 'none',
                    color: '#FFFFFF',
                    fontSize: '0.875rem',
                    fontWeight: 600,
                    cursor: isLoading ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                  }}
                >
                  {isLoading ? 'Memeriksa Akun...' : 'Kirim Kode OTP'}
                </button>
              </div>
            </form>
          )}

          {/* STEP 2: OTP & NEW PASSWORD INPUT */}
          {step === 'OTP' && (
            <form onSubmit={handleResetPassword}>
              {/* Account Match Badge */}
              <div
                style={{
                  padding: '0.75rem 1rem',
                  backgroundColor: 'rgba(33, 150, 243, 0.08)',
                  border: '1px solid rgba(33, 150, 243, 0.25)',
                  borderRadius: '10px',
                  marginBottom: '1.25rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <div>
                  <div style={{ fontSize: '0.75rem', color: '#94A3B8' }}>Akun Ditemukan</div>
                  <div style={{ fontSize: '0.875rem', fontWeight: 600, color: '#38BDF8' }}>
                    {userInfo?.fullName} ({email})
                  </div>
                </div>
                <span
                  style={{
                    fontSize: '0.7rem',
                    padding: '3px 10px',
                    borderRadius: '999px',
                    backgroundColor: 'rgba(2, 132, 199, 0.2)',
                    color: '#38BDF8',
                    border: '1px solid rgba(56, 189, 248, 0.45)',
                    fontWeight: 700,
                    letterSpacing: '0.04em',
                  }}
                >
                  {formatRoleLabel(userInfo?.role)}
                </span>
              </div>

              {/* Real Email Sent Information Notice */}
              <div
                style={{
                  padding: '0.75rem 1rem',
                  backgroundColor: 'rgba(2, 132, 199, 0.1)',
                  border: '1px solid rgba(2, 132, 199, 0.25)',
                  borderRadius: '10px',
                  marginBottom: '1.25rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.65rem',
                }}
              >
                <ClockIcon size={18} style={{ color: '#38BDF8', flexShrink: 0 }} />
                <div style={{ fontSize: '0.8rem', color: '#BAE6FD', lineHeight: 1.45 }}>
                  Kode verifikasi 6 digit telah dikirimkan ke email <strong style={{ color: '#FFFFFF' }}>{email}</strong>. Silakan periksa kotak masuk (atau folder spam).
                </div>
              </div>

              {/* OTP Field */}
              <div style={{ marginBottom: '1.15rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#94A3B8', marginBottom: '0.45rem' }}>
                  6 Digit Kode OTP
                </label>
                <input
                  type="text"
                  maxLength={6}
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/[^0-9]/g, ''))}
                  placeholder="Contoh: 123456"
                  required
                  autoFocus
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    borderRadius: '10px',
                    backgroundColor: 'rgba(15, 23, 42, 0.6)',
                    border: '1px solid rgba(255, 255, 255, 0.12)',
                    color: '#FFFFFF',
                    fontSize: '1.1rem',
                    letterSpacing: '0.25em',
                    fontWeight: 700,
                    textAlign: 'center',
                    outline: 'none',
                  }}
                />
              </div>

              {/* New Password */}
              <div style={{ marginBottom: '1.15rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.45rem' }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#94A3B8' }}>
                    Kata Sandi Baru (Min. 6 Karakter)
                  </label>
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: '#60A5FA',
                      fontSize: '0.75rem',
                      cursor: 'pointer',
                    }}
                  >
                    {showPassword ? 'Sembunyikan' : 'Lihat'}
                  </button>
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Masukkan kata sandi baru"
                  required
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    borderRadius: '10px',
                    backgroundColor: 'rgba(15, 23, 42, 0.6)',
                    border: '1px solid rgba(255, 255, 255, 0.12)',
                    color: '#FFFFFF',
                    fontSize: '0.9rem',
                    outline: 'none',
                  }}
                />
              </div>

              {/* Confirm New Password */}
              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#94A3B8', marginBottom: '0.45rem' }}>
                  Konfirmasi Kata Sandi Baru
                </label>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Ulangi kata sandi baru"
                  required
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    borderRadius: '10px',
                    backgroundColor: 'rgba(15, 23, 42, 0.6)',
                    border: `1px solid ${
                      confirmPassword && confirmPassword !== newPassword
                        ? 'rgba(239, 68, 68, 0.6)'
                        : 'rgba(255, 255, 255, 0.12)'
                    }`,
                    color: '#FFFFFF',
                    fontSize: '0.9rem',
                    outline: 'none',
                  }}
                />
                {confirmPassword && confirmPassword !== newPassword && (
                  <div style={{ fontSize: '0.725rem', color: '#F87171', marginTop: '4px' }}>
                    Konfirmasi kata sandi tidak cocok.
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1.75rem' }}>
                <button
                  type="button"
                  onClick={() => setStep('EMAIL')}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.45rem',
                    padding: '0.65rem 1.15rem',
                    borderRadius: '8px',
                    backgroundColor: 'rgba(255, 255, 255, 0.05)',
                    border: '1px solid rgba(255, 255, 255, 0.12)',
                    color: '#CBD5E1',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.1)';
                    e.currentTarget.style.borderColor = 'rgba(255, 255, 255, 0.25)';
                    e.currentTarget.style.color = '#FFFFFF';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
                    e.currentTarget.style.borderColor = 'rgba(255, 255, 255, 0.12)';
                    e.currentTarget.style.color = '#CBD5E1';
                  }}
                >
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12" />
                    <polyline points="12 19 5 12 12 5" />
                  </svg>
                  <span>Ganti Email</span>
                </button>
                <button
                  type="submit"
                  disabled={isLoading}
                  style={{
                    padding: '0.65rem 1.4rem',
                    borderRadius: '8px',
                    backgroundColor: '#0284C7',
                    border: 'none',
                    color: '#FFFFFF',
                    fontSize: '0.875rem',
                    fontWeight: 600,
                    cursor: isLoading ? 'not-allowed' : 'pointer',
                  }}
                >
                  {isLoading ? 'Memperbarui...' : 'Simpan Kata Sandi Baru'}
                </button>
              </div>
            </form>
          )}

          {/* STEP 3: SUCCESS STATE */}
          {step === 'SUCCESS' && (
            <div style={{ textAlign: 'center', padding: '1rem 0' }}>
              <div
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(2, 132, 199, 0.15)',
                  border: '2px solid rgba(56, 189, 248, 0.45)',
                  boxShadow: '0 0 25px rgba(56, 189, 248, 0.25)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#38BDF8',
                  margin: '0 auto 1.25rem',
                }}
              >
                <CheckIcon size={32} />
              </div>

              <h3 style={{ fontSize: '1.15rem', fontWeight: 700, margin: '0 0 0.5rem', color: '#FFFFFF' }}>
                Kata Sandi Berhasil Diperbarui!
              </h3>
              <p style={{ fontSize: '0.85rem', color: '#94A3B8', marginBottom: '1.75rem', lineHeight: 1.6 }}>
                Kata sandi baru <strong style={{ color: '#E2E8F0' }}>{email}</strong> telah disimpan.
                <br />
                Anda dapat langsung masuk dengan kredensial baru.
              </p>

              <button
                type="button"
                onClick={handleFinish}
                style={{
                  width: '100%',
                  padding: '0.75rem',
                  borderRadius: '10px',
                  backgroundColor: '#0284C7',
                  border: 'none',
                  color: '#FFFFFF',
                  fontSize: '0.9rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  boxShadow: '0 4px 14px rgba(2, 132, 199, 0.4)',
                }}
              >
                Masuk Sekarang
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
