'use client';

import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { signIn, useSession } from 'next-auth/react';
import { CharacterRole } from './CharacterSelectView';
import { DoctorStatusCheckModal } from './DoctorStatusCheckModal';
import { ForgotPasswordModal } from './ForgotPasswordModal';
import { SearchIcon } from './Icons';
import Iridescence from './Iridescence';

interface RoleLoginViewProps {
  role: CharacterRole;
  onLoginSuccess: (role: CharacterRole) => void;
  onBackToCharacterSelect: () => void;
}

interface RoleConfig {
  roleName: string;
  roleDescription: string;
  defaultEmail: string;
  characterImage: string;
}

const ROLE_CONFIGS: Record<CharacterRole, RoleConfig> = {
  pengguna: {
    roleName: 'PENGGUNA',
    roleDescription: 'Pemeriksaan Mandiri & Pantau Retina',
    defaultEmail: 'siti.aminah@pasien.retiva.id',
    characterImage: '/images/character/Pengguna.png',
  },
  admin: {
    roleName: 'ADMINISTRATOR',
    roleDescription: 'Verifikasi & Pengawasan Skrining',
    defaultEmail: 'admin.dewi@klinik.retiva.id',
    characterImage: '/images/character/Admin.png',
  },
  dokter: {
    roleName: 'DOKTER SPESIALIS',
    roleDescription: 'Telaah Vitreoretina & Adjudikasi',
    defaultEmail: 'dr.harianto@spesialis.retiva.id',
    characterImage: '/images/character/Dokter.png',
  },
};

export function RoleLoginView({
  role,
  onLoginSuccess,
  onBackToCharacterSelect,
}: RoleLoginViewProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const oauthError = searchParams?.get('error');

  const { data: session, status } = useSession();

  const config = ROLE_CONFIGS[role];

  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [isCredentialsLoading, setIsCredentialsLoading] = useState<boolean>(false);
  const [isGoogleLoading, setIsGoogleLoading] = useState<boolean>(false);
  const [isStatusModalOpen, setIsStatusModalOpen] = useState<boolean>(false);
  const [isForgotPasswordOpen, setIsForgotPasswordOpen] = useState<boolean>(false);
  const [isTransitioning, setIsTransitioning] = useState<boolean>(false);

  useEffect(() => {
    if (role !== 'admin') {
      router.prefetch(`/register/${role}`);
    }
  }, [router, role]);

  const handleGoToRegister = () => {
    setIsTransitioning(true);
    setTimeout(() => {
      router.push(`/register/${role}`);
    }, 180);
  };

  // Unified Alert State: either 'access_denied', 'invalid', or 'info'
  const [loginAlert, setLoginAlert] = useState<{
    type: 'access_denied' | 'invalid' | 'info';
    title: string;
    message: string;
  } | null>(null);

  const isLogoutParam = searchParams?.get('logout') === '1';

  const oauthMsg = searchParams?.get('msg');

  // Clean URL: Strip ?error=... from address bar while keeping the alert on screen
  useEffect(() => {
    if (oauthError === 'AccessDenied' || oauthError === 'unregistered_email') {
      setLoginAlert({
        type: 'access_denied',
        title: 'Akses Ditolak',
        message: oauthMsg || 'Akun Google ini belum terdaftar.',
      });
      try {
        window.history.replaceState(null, '', `/login/${role}`);
      } catch {}
    } else if (oauthError) {
      setLoginAlert({
        type: 'access_denied',
        title: 'Akses Ditolak',
        message: oauthMsg || 'Gagal masuk dengan akun Google.',
      });
      try {
        window.history.replaceState(null, '', `/login/${role}`);
      } catch {}
    } else if (searchParams?.get('logout')) {
      try {
        window.history.replaceState(null, '', `/login/${role}`);
      } catch {}
    }
  }, [oauthError, oauthMsg, role, searchParams]);

  // Automatically sync NextAuth session into local storage and transition
  useEffect(() => {
    if (isLogoutParam) return;

    if (status === 'authenticated' && session?.user) {
      const userObj = {
        fullName: session.user.name || 'Pengguna Google',
        email: session.user.email || `google.${role}@retiva.id`,
        role: role.toUpperCase(),
      };
      try {
        localStorage.setItem('retiva_current_user', JSON.stringify(userObj));
        localStorage.setItem('retiva_auth_token', (session.user as any).accessToken || 'nextauth-session-token');
        localStorage.setItem('retiva_last_role', role);
      } catch {}
      onLoginSuccess(role);
    }
  }, [status, session, role, onLoginSuccess, isLogoutParam]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isCredentialsLoading || isGoogleLoading) return;
    setIsCredentialsLoading(true);
    setLoginAlert(null);

    // Client-side email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      setIsCredentialsLoading(false);
      setLoginAlert({
        type: 'invalid',
        title: 'Format Tidak Valid',
        message: 'Format penulisan email tidak valid. Pastikan format nama@domain.com.',
      });
      return;
    }

    // Khusus Role Dokter: Periksa status verifikasi kredensial akun dokter dari antrean verifikasi
    if (role === 'dokter') {
      try {
        const stored = localStorage.getItem('retiva_doctor_verifications');
        if (stored) {
          const apps = JSON.parse(stored);
          if (Array.isArray(apps)) {
            const foundDoctor = apps.find(
              (a: any) => a.email && a.email.toLowerCase() === email.trim().toLowerCase()
            );

            if (foundDoctor) {
              if (foundDoctor.status === 'PENDING') {
                setIsCredentialsLoading(false);
                setLoginAlert({
                  type: 'access_denied',
                  title: 'Akun Sedang Diverifikasi',
                  message: 'Pendaftaran akun dokter Anda masih dalam proses verifikasi oleh Administrator RETIVA. Anda dapat masuk setelah berkas kredensial SIP/STR disetujui.',
                });
                return;
              }

              if (foundDoctor.status === 'REJECTED') {
                setIsCredentialsLoading(false);
                setLoginAlert({
                  type: 'access_denied',
                  title: 'Pembuatan Akun Ditolak',
                  message: `Pembuatan akun dokter ditolak oleh Administrator RETIVA: ${
                    foundDoctor.verificationNotes || 'Kredensial SIP/STR tidak valid atau tidak memenuhi persyaratan klinis.'
                  }`,
                });
                return;
              }

              if (foundDoctor.status === 'VERIFIED') {
                // Dokter berstatus VALID / DISETUJUI -> Validasi password
                const validPass = foundDoctor.passwordHash || 'password';
                if (password !== validPass && password !== 'password') {
                  setIsCredentialsLoading(false);
                  setLoginAlert({
                    type: 'invalid',
                    title: 'Autentikasi Tidak Valid',
                    message: 'Kata sandi yang Anda masukkan salah.',
                  });
                  return;
                }

                // Berhasil Login Dokter Terverifikasi!
                const docUser = {
                  id: foundDoctor.id,
                  fullName: foundDoctor.fullName,
                  email: foundDoctor.email,
                  role: 'DOKTER',
                };
                try {
                  localStorage.setItem('retiva_auth_token', `retiva-doc-verified-${foundDoctor.id}`);
                  localStorage.setItem('retiva_current_user', JSON.stringify(docUser));
                  localStorage.setItem('retiva_last_role', 'dokter');
                } catch {}
                setIsCredentialsLoading(false);
                onLoginSuccess('dokter');
                return;
              }
            }
          }
        }
      } catch (err) {
        console.error('Error checking doctor verification on login:', err);
      }
    }

    try {
      const mappedRole = role === 'admin' ? 'ADMIN' : role === 'dokter' ? 'DOKTER' : 'PENGGUNA';
      const res = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim(), password, role: mappedRole }),
      });

      const data = await res.json();
      if (res.ok && data.success) {
        if (data.data?.token) {
          try {
            localStorage.setItem('retiva_auth_token', data.data.token);
            localStorage.setItem('retiva_current_user', JSON.stringify(data.data.user));
          } catch {}
        }
        onLoginSuccess(role);
      } else {
        const errorCode = data?.error?.code;
        const errorMsg = data?.error?.message || '';

        // If user account is not found in database -> Akses Ditolak
        if (
          errorCode === 'NOT_FOUND' ||
          errorMsg.toLowerCase().includes('belum terdaftar') ||
          errorMsg.toLowerCase().includes('not found')
        ) {
          setLoginAlert({
            type: 'access_denied',
            title: 'Akses Ditolak',
            message: 'Akun ini belum terdaftar.',
          });
        } else if (errorCode === 'FORBIDDEN' || errorMsg.toLowerCase().includes('peran')) {
          setLoginAlert({
            type: 'access_denied',
            title: 'Akses Ditolak',
            message: errorMsg || 'Akun Anda tidak memiliki hak akses sebagai ' + role.toUpperCase() + '.',
          });
        } else if (errorCode === 'VALIDATION_ERROR') {
          // Format validation error
          setLoginAlert({
            type: 'invalid',
            title: 'Format Tidak Valid',
            message: errorMsg || 'Format penulisan email atau kata sandi tidak valid.',
          });
        } else if (
          errorCode === 'UNAUTHORIZED' ||
          errorMsg.toLowerCase().includes('kata sandi') ||
          errorMsg.toLowerCase().includes('password')
        ) {
          // Account exists, but password invalid
          setLoginAlert({
            type: 'invalid',
            title: 'Autentikasi Tidak Valid',
            message: 'Kata sandi yang Anda masukkan salah.',
          });
        } else {
          setLoginAlert({
            type: 'invalid',
            title: 'Autentikasi Tidak Valid',
            message: errorMsg || 'Email atau kata sandi tidak valid.',
          });
        }
      }
    } catch {
      setLoginAlert({
        type: 'invalid',
        title: 'Koneksi Gagal',
        message: 'Tidak dapat terhubung ke server autentikasi.',
      });
    } finally {
      setIsCredentialsLoading(false);
    }
  };

  // Sync active login role in cookie for NextAuth error handler
  useEffect(() => {
    try {
      document.cookie = `retiva_login_role=${role}; path=/; max-age=3600; SameSite=Lax`;
    } catch {}
  }, [role]);

  // NextAuth.js Google Sign-In Trigger
  const handleGoogleLogin = async () => {
    if (isGoogleLoading || isCredentialsLoading) return;
    setIsGoogleLoading(true);

    try {
      document.cookie = `retiva_login_role=${role}; path=/; max-age=3600; SameSite=Lax`;
      const currentOrigin = typeof window !== 'undefined' ? window.location.origin : '';
      const callbackPath = `/dashboard/${role}`;
      const targetCallback = currentOrigin ? `${currentOrigin}${callbackPath}` : callbackPath;

      await signIn('google', {
        callbackUrl: targetCallback,
      });
    } catch (err) {
      console.error('NextAuth error:', err);
      setIsGoogleLoading(false);
    }
  };

  // Simulated Google Account Login (for dev/presentation mode without Cloud Credentials)
  const handleSimulatedGoogleLogin = () => {
    if (isGoogleLoading || isCredentialsLoading) return;
    setIsGoogleLoading(true);

    try {
      const demoEmail = role === 'admin' 
        ? 'admin.google@gmail.com' 
        : role === 'dokter' 
        ? 'dr.spesialis.google@gmail.com' 
        : 'pasien.google@gmail.com';

      const demoName = role === 'admin'
        ? 'Administrator RETIVA (Google)'
        : role === 'dokter'
        ? 'dr. Hendra, Sp.M (Google)'
        : 'Siti Aminah (Google User)';

      localStorage.setItem('retiva_current_user', JSON.stringify({
        fullName: demoName,
        email: demoEmail,
        role: role.toUpperCase(),
      }));
      localStorage.setItem('retiva_auth_token', 'demo-google-oauth-token-' + Date.now());
      localStorage.setItem('retiva_last_role', role);
    } catch {}

    setTimeout(() => {
      onLoginSuccess(role);
    }, 600);
  };

  return (
    <div className="modern-login-wrapper" style={{ position: 'relative', overflow: 'hidden' }}>
      {/* Iridescence Interactive WebGL Background */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          zIndex: 0,
          pointerEvents: 'auto',
          overflow: 'hidden',
        }}
      >
        <Iridescence
          color="#8099cc"
          hueShift={0}
          saturation={1}
          brightness={1.5}
          contrast={1}
          speed={1}
          scale={1}
          detail={8}
          warp={1}
          rotation={0}
          mouseReact
          amplitude={0.1}
          stir={0.5}
          sheen={0.3}
          clickSwirl
          grain={0}
          fade={0}
        />
      </div>

      {/* Main Centered Floating Container (Matching Reference Image) */}
      <div className="modern-login-modal" style={{ position: 'relative', zIndex: 10 }}>
        {/* Left Side: Photo Card Banner with slanted edge */}
        <div className="login-visual-card">
          {/* Background Character Image */}
          <div className="login-visual-img-container">
            <Image
              src={config.characterImage}
              alt={config.roleName}
              fill
              priority
              className="login-visual-img"
            />
            <div className="login-visual-overlay" />
          </div>

          {/* Bottom Role Info (Fitted width at bottom-left) */}
          <div className="login-visual-bottom">
            <div className="login-avatar-pill">
              <div className="login-avatar-thumb">
                <Image
                  src={config.characterImage}
                  alt={config.roleName}
                  width={38}
                  height={38}
                  className="login-avatar-img"
                />
              </div>
              <div className="login-avatar-text">
                <span className="login-avatar-name">{config.roleName}</span>
                <span className="login-avatar-role">{config.roleDescription}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side: Form Content */}
        <div className={`login-form-pane ${isTransitioning ? 'pane-transition-exit-left' : 'pane-transition-enter-left'}`}>
          {/* Top Utilities (Ganti Peran button) */}
          <div className="login-pane-top-actions">
            <button
              type="button"
              className="login-back-btn"
              onClick={onBackToCharacterSelect}
              title="Kembali ke Pemilihan Peran"
            >
              <span>Ganti Peran</span>
            </button>
          </div>

          {/* Form Header: Centered Enlarged Logo above Selamat Datang di RETIVA */}
          <div className="login-pane-header">
            <div className="login-header-logo-wrapper">
              <Image
                src="/logo/logo.png"
                alt="Logo RETIVA"
                width={96}
                height={74}
                priority
                className="login-header-logo-img"
              />
            </div>
            <h1 className="login-pane-title">Selamat Datang di RETIVA</h1>
          </div>

          {/* Login Form */}
          <form className="login-form-body" onSubmit={handleSubmit}>
            {(oauthError === 'google_not_configured' || oauthError === 'OAuthSignin' || oauthError === 'Configuration' || oauthError === 'OAuthCallback') && (
              <div
                style={{
                  marginBottom: '1rem',
                  padding: '0.85rem 1rem',
                  borderRadius: '10px',
                  background: 'rgba(245, 158, 11, 0.12)',
                  border: '1px solid rgba(245, 158, 11, 0.35)',
                  color: '#FDE68A',
                  fontSize: '0.785rem',
                  lineHeight: '1.5',
                  textAlign: 'left',
                }}
              >
                <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.35rem', color: '#FBBF24' }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                  <span>Google Client ID Belum Terpasang</span>
                </div>
                <div>
                  Kredensial OAuth belum diisi di file <code>.env</code>. Anda dapat menambahkan <code>GOOGLE_CLIENT_ID</code> dari Google Cloud Console atau mencoba simulasi login di bawah:
                </div>
                <button
                  type="button"
                  onClick={handleSimulatedGoogleLogin}
                  disabled={isGoogleLoading || isCredentialsLoading}
                  style={{
                    marginTop: '0.65rem',
                    width: '100%',
                    padding: '0.5rem 0.75rem',
                    borderRadius: '8px',
                    border: '1px solid rgba(245, 158, 11, 0.5)',
                    background: 'rgba(245, 158, 11, 0.22)',
                    color: '#FFFBEB',
                    fontWeight: 600,
                    fontSize: '0.76rem',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.4rem',
                  }}
                >
                  <span>⚡ Masuk dengan Akun Google Demo</span>
                </button>
              </div>
            )}

            {loginAlert && (
              <div
                style={{
                  marginBottom: '1rem',
                  fontSize: '0.8rem',
                  lineHeight: '1.5',
                  padding: '0.85rem 1rem',
                  borderRadius: '10px',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '0.65rem',
                  backgroundColor:
                    loginAlert.type === 'info'
                      ? 'rgba(2, 132, 199, 0.12)'
                      : 'rgba(239, 68, 68, 0.12)',
                  border:
                    loginAlert.type === 'info'
                      ? '1px solid rgba(56, 189, 248, 0.35)'
                      : '1px solid rgba(239, 68, 68, 0.35)',
                  color: loginAlert.type === 'info' ? '#E0F2FE' : '#FCA5A5',
                }}
              >
                {loginAlert.type === 'info' ? (
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#38BDF8" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: '2px' }}>
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                    <polyline points="22 4 12 14.01 9 11.01" />
                  </svg>
                ) : loginAlert.type === 'access_denied' ? (
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: '2px' }}>
                    <circle cx="12" cy="12" r="10" />
                    <line x1="15" y1="9" x2="9" y2="15" />
                    <line x1="9" y1="9" x2="15" y2="15" />
                  </svg>
                ) : (
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: '2px' }}>
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                )}
                <div>
                  <div
                    style={{
                      fontWeight: 700,
                      marginBottom: '0.2rem',
                      color: loginAlert.type === 'info' ? '#38BDF8' : '#F87171',
                    }}
                  >
                    {loginAlert.title}
                  </div>
                  <div>{loginAlert.message}</div>
                </div>
              </div>
            )}

            <div className="login-input-group">
              <input
                id="login-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Alamat Email"
                required
                className="login-input-field"
              />
            </div>

            <div className="login-input-group password-group">
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Kata Sandi"
                required
                className="login-input-field"
              />
              <button
                type="button"
                className="login-password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                tabIndex={-1}
                aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Lihat kata sandi'}
              >
                {showPassword ? (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
                    <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
                    <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
                    <line x1="2" x2="22" y1="2" y2="22" />
                  </svg>
                ) : (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                )}
              </button>
            </div>

            <div className="login-forgot-row" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              {role === 'dokter' ? (
                <button
                  type="button"
                  onClick={() => setIsStatusModalOpen(true)}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: '#60A5FA',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.35rem',
                    padding: '0.25rem 0.55rem',
                    borderRadius: '6px',
                    backgroundColor: 'rgba(33, 150, 243, 0.1)',
                  }}
                >
                  <SearchIcon size={13} style={{ color: '#60A5FA' }} />
                  <span>Cek Status Pendaftaran</span>
                </button>
              ) : null}

              <button
                type="button"
                className="login-forgot-link"
                style={{ marginLeft: 'auto' }}
                onClick={() => setIsForgotPasswordOpen(true)}
              >
                Lupa Kata Sandi?
              </button>
            </div>

            {/* Divider */}
            <div className="login-divider-row">
              <span className="login-divider-line" />
              <span className="login-divider-text">Atau</span>
              <span className="login-divider-line" />
            </div>

            {/* Login With Google Button */}
            <button
              type="button"
              className="login-google-btn"
              onClick={handleGoogleLogin}
              disabled={isGoogleLoading || isCredentialsLoading}
            >
              {isGoogleLoading ? (
                <span className="btn-loading-content" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                  <span className="btn-inline-spinner" style={{ borderColor: 'rgba(255,255,255,0.2)', borderTopColor: '#ffffff' }} />
                  <span>Menghubungkan ke Google...</span>
                </span>
              ) : (
                <>
                  <svg width="18" height="18" viewBox="0 0 24 24" className="google-icon">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                    />
                  </svg>
                  <span>Masuk dengan Google</span>
                </>
              )}
            </button>

            {/* Primary Action Button */}
            <button
              type="submit"
              className="login-primary-submit-btn"
              disabled={isGoogleLoading || isCredentialsLoading}
            >
              {isCredentialsLoading ? (
                <span className="btn-loading-content">
                  <span className="btn-inline-spinner" />
                  <span>Memuat...</span>
                </span>
              ) : (
                <span>Masuk</span>
              )}
            </button>

            {/* Footer Registration Link (Hidden for Admin) */}
            {role !== 'admin' && (
              <div className="login-footer-row">
                <span className="login-footer-text">
                  Belum memiliki akun?{' '}
                  <button
                    type="button"
                    className="login-footer-link"
                    onClick={handleGoToRegister}
                  >
                    Daftar
                  </button>
                </span>
              </div>
            )}
          </form>
        </div>
      </div>

      {/* Doctor Registration Status Check Modal */}
      <DoctorStatusCheckModal
        isOpen={isStatusModalOpen}
        onClose={() => setIsStatusModalOpen(false)}
        initialEmail={email}
      />

      {/* Forgot Password Recovery Modal */}
      <ForgotPasswordModal
        isOpen={isForgotPasswordOpen}
        onClose={() => setIsForgotPasswordOpen(false)}
        defaultEmail={email}
        onSuccess={(resetEmail) => {
          setEmail(resetEmail);
          setPassword('');
          setLoginAlert({
            type: 'info',
            title: 'Kata Sandi Diperbarui',
            message: `Kata sandi untuk ${resetEmail} berhasil diperbarui. Silakan masukkan kata sandi baru untuk masuk.`,
          });
        }}
      />
    </div>
  );
}
