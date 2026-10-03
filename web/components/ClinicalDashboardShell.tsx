'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { signOut, useSession } from 'next-auth/react';
import dynamic from 'next/dynamic';
import { CharacterRole } from './CharacterSelectView';
import { PatientPortalView } from './PatientPortalView';
import { AdminSidebar } from './AdminSidebar';
import { AdminTopBar } from './AdminTopBar';
import { DashboardView } from './DashboardView';
import { ScreeningWorkflowView } from './ScreeningWorkflowView';
import { OphthalmologistReviewView } from './OphthalmologistReviewView';
import { PatientsDirectoryView } from './PatientsDirectoryView';
import { ReferralsFacilityView } from './ReferralsFacilityView';
import { AuditRegistryView } from './AuditRegistryView';
import { UsersMasterView } from './UsersMasterView';
import { clinicalStore } from '../lib/clinical-store';

const DoctorVerificationView = dynamic(
  () => import('./DoctorVerificationView').then((mod) => mod.DoctorVerificationView),
  { ssr: false }
);

interface ClinicalDashboardShellProps {
  role: CharacterRole;
  initialTab?: string;
}

export function ClinicalDashboardShell({
  role,
  initialTab,
}: ClinicalDashboardShellProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');

  const defaultTab = initialTab || tabParam || (role === 'dokter' ? 'review' : 'dashboard');
  const [activeTab, setActiveTab] = useState<string>(defaultTab);

  useEffect(() => {
    try {
      if (!tabParam) {
        const savedTab = sessionStorage.getItem('retiva_admin_tab');
        if (savedTab) {
          setActiveTab(savedTab);
        }
      }
    } catch {}
  }, []);

  useEffect(() => {
    if (tabParam && tabParam !== activeTab) {
      setActiveTab(tabParam);
    }
  }, [tabParam]);

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    if (typeof window !== 'undefined') {
      try {
        sessionStorage.setItem('retiva_admin_tab', tab);
        const url = new URL(window.location.href);
        url.searchParams.set('tab', tab);
        window.history.replaceState({}, '', url.toString());
      } catch {}
    }
    refreshCounts();
  };

  const [selectedScreeningId, setSelectedScreeningId] = useState<string>('SCR-2026-0891');
  const [referralPatient, setReferralPatient] = useState<string>('Bambang Sudarmono');
  const [screeningNik, setScreeningNik] = useState<string>('3404071203720001');
  const [pendingReviewCount, setPendingReviewCount] = useState<number>(0);
  const [patientCount, setPatientCount] = useState<number>(0);

  // NextAuth active session hook
  const { data: session, status: sessionStatus } = useSession();

  const getDefaultUser = (r: CharacterRole) => ({
    fullName: r === 'dokter' ? 'dr. Harianto, Sp.M(K)' : r === 'admin' ? 'Administrator RETIVA' : 'Ny. Siti Aminah',
    email: r === 'dokter' ? 'dr.harianto@spesialis.retiva.id' : r === 'admin' ? 'admin@gmail.com' : 'siti.aminah@pasien.retiva.id',
    role: r.toUpperCase(),
  });

  // Dynamic Logged-in User State initialized identically on server and client to prevent hydration mismatch
  const [currentUser, setCurrentUser] = useState<{
    fullName?: string;
    email?: string;
    role?: string;
  }>(getDefaultUser(role));

  const isLoggingOutRef = useRef(false);

  useEffect(() => {
    if (isLoggingOutRef.current) return;

    // 1. If NextAuth session is active, prioritize logged-in Google / OAuth profile
    if (sessionStatus === 'authenticated' && session?.user?.email) {
      const authUser = {
        fullName: session.user.name || session.user.email.split('@')[0],
        email: session.user.email,
        role: ((session.user as any).role || role).toUpperCase(),
      };
      setCurrentUser(authUser);
      try {
        localStorage.setItem('retiva_current_user', JSON.stringify(authUser));
        if ((session.user as any).accessToken) {
          localStorage.setItem('retiva_auth_token', (session.user as any).accessToken);
        }
        localStorage.setItem('retiva_last_role', role);
      } catch {}
      return;
    }

    // 2. If unauthenticated via NextAuth, check manual credentials from localStorage
    if (sessionStatus === 'unauthenticated') {
      try {
        const savedUserStr = localStorage.getItem('retiva_current_user');
        if (savedUserStr) {
          const parsed = JSON.parse(savedUserStr);
          if (parsed && typeof parsed === 'object' && parsed.fullName) {
            setCurrentUser(parsed);
            return;
          }
        }
      } catch {}

      // 3. Fallback default role user profiles
      setCurrentUser(getDefaultUser(role));
    }
  }, [role, session, sessionStatus]);

  const refreshCounts = () => {
    setPendingReviewCount(clinicalStore.getPendingReviews().length);
    setPatientCount(clinicalStore.getPatients().length);
  };

  useEffect(() => {
    refreshCounts();
    const unsubscribe = clinicalStore.subscribe(() => {
      refreshCounts();
    });
    return () => unsubscribe();
  }, [activeTab]);

  const handleLogout = async () => {
    isLoggingOutRef.current = true;
    try {
      localStorage.removeItem('retiva_auth_token');
      localStorage.removeItem('retiva_current_user');
      localStorage.setItem('retiva_last_role', role);
      sessionStorage.clear();
    } catch {}

    try {
      await signOut({ redirect: false });
    } catch {}

    window.location.href = `/login/${role}?logout=1`;
  };

  const handleSwitchCharacter = () => {
    try {
      localStorage.setItem('retiva_last_role', role);
    } catch {}
    router.push(`/?role=${role}`);
  };

  const handleOpenReview = (screeningId: string) => {
    setSelectedScreeningId(screeningId);
    setActiveTab('review');
  };

  const handleStartScreeningForPatient = (nik: string) => {
    setScreeningNik(nik);
    setActiveTab('screening');
  };

  const handleGoToReferrals = (patientName: string) => {
    setReferralPatient(patientName);
    setActiveTab('referrals');
  };

  // 1. ROLE PENGGUNA (Patient Portal View)
  if (role === 'pengguna') {
    return (
      <PatientPortalView
        onSwitchCharacter={handleSwitchCharacter}
        onLogout={handleLogout}
        onOpenDoctorView={() => router.push('/dashboard/dokter')}
        onOpenAdminView={() => router.push('/dashboard/admin')}
        currentUser={currentUser}
      />
    );
  }

  // 2. ROLE ADMIN & ROLE DOKTER (Clinical Management Shell)
  return (
    <div className="admin-shell">
      {/* Left Fixed Admin Sidebar */}
      <AdminSidebar
        activeTab={activeTab}
        onTabChange={handleTabChange}
        reviewCount={pendingReviewCount}
        patientCount={patientCount}
        currentUser={currentUser}
        currentRole={role}
        onLogout={handleLogout}
      />

      {/* Right Admin Viewport */}
      <div className="admin-viewport">
        <AdminTopBar
          activeTab={activeTab}
          onNavigateTab={handleTabChange}
          onStartScreening={() => setActiveTab('screening')}
          onSwitchCharacter={handleSwitchCharacter}
          onLogout={handleLogout}
          currentRole={role}
          currentUser={currentUser}
        />

        <main className="admin-scrollable-content">
          {activeTab === 'dashboard' && (
            <DashboardView
              onStartScreening={() => setActiveTab('screening')}
              onOpenReview={handleOpenReview}
            />
          )}

          {activeTab === 'users' && <UsersMasterView initialTab="users" />}

          {activeTab === 'roles' && <UsersMasterView initialTab="roles" />}

          {activeTab === 'doctor-verification' && <DoctorVerificationView />}

          {activeTab === 'screening' && (
            <ScreeningWorkflowView
              prefilledNik={screeningNik}
              onGoToReview={handleOpenReview}
              onGoToReferrals={handleGoToReferrals}
            />
          )}

          {activeTab === 'review' && (
            <OphthalmologistReviewView
              screeningId={selectedScreeningId}
              onAdjudicationSaved={() => {
                refreshCounts();
                setActiveTab('dashboard');
              }}
            />
          )}

          {activeTab === 'patients' && (
            <PatientsDirectoryView
              onStartScreeningForPatient={handleStartScreeningForPatient}
            />
          )}

          {activeTab === 'referrals' && (
            <ReferralsFacilityView
              initialPatientName={referralPatient}
            />
          )}

          {activeTab === 'audit' && <AuditRegistryView />}
        </main>
      </div>
    </div>
  );
}
