'use client';

import React, { useState, useEffect } from 'react';
import { AdminSidebar } from '../components/AdminSidebar';
import { AdminTopBar } from '../components/AdminTopBar';
import { DisclaimerBanner } from '../components/DisclaimerBanner';
import { DashboardView } from '../components/DashboardView';
import { ScreeningWorkflowView } from '../components/ScreeningWorkflowView';
import { OphthalmologistReviewView } from '../components/OphthalmologistReviewView';
import { PatientsDirectoryView } from '../components/PatientsDirectoryView';
import { ReferralsFacilityView } from '../components/ReferralsFacilityView';
import { AuditRegistryView } from '../components/AuditRegistryView';
import { clinicalStore } from '../lib/clinical-store';

export default function HomePage() {
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [selectedScreeningId, setSelectedScreeningId] = useState<string>('SCR-2026-0891');
  const [referralPatient, setReferralPatient] = useState<string>('Bambang Sudarmono');
  const [screeningNik, setScreeningNik] = useState<string>('3404071203720001');
  const [pendingReviewCount, setPendingReviewCount] = useState<number>(0);
  const [patientCount, setPatientCount] = useState<number>(0);

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

  return (
    <div className="admin-shell">
      {/* Left Fixed Admin Sidebar */}
      <AdminSidebar
        activeTab={activeTab}
        onTabChange={(tab) => {
          setActiveTab(tab);
          refreshCounts();
        }}
        reviewCount={pendingReviewCount}
        patientCount={patientCount}
      />

      {/* Right Admin Viewport */}
      <div className="admin-viewport">
        <AdminTopBar
          activeTab={activeTab}
          onStartScreening={() => setActiveTab('screening')}
        />

        <DisclaimerBanner />

        <main className="admin-scrollable-content">
          {activeTab === 'dashboard' && (
            <DashboardView
              onStartScreening={() => setActiveTab('screening')}
              onOpenReview={handleOpenReview}
            />
          )}

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

          {activeTab === 'audit' && (
            <AuditRegistryView />
          )}

          <footer style={{ marginTop: '2.5rem', paddingTop: '1rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem', fontSize: '0.725rem', color: 'var(--slate-500)' }}>
            <div>
              <strong>RETIVA Clinical Admin v1.0.0</strong> — Sistem Pendukung Keputusan Klinis Skrining Retinopati Diabetik.
            </div>
            <div>
              Standar Regulasi: Permenkes No. 24/2022 &amp; UU PDP No. 27/2022 • Interoperabilitas SatuSehat.
            </div>
          </footer>
        </main>
      </div>
    </div>
  );
}
