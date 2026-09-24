'use client';

import React, { useState, useEffect } from 'react';
import { AppHeader } from '../components/AppHeader';
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

  const refreshCounts = () => {
    setPendingReviewCount(clinicalStore.getPendingReviews().length);
  };

  useEffect(() => {
    refreshCounts();
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
    <div className="app-container">
      <AppHeader
        activeTab={activeTab}
        onTabChange={(tab) => {
          setActiveTab(tab);
          refreshCounts();
        }}
        reviewCount={pendingReviewCount}
      />
      <DisclaimerBanner />

      <main className="main-content">
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
      </main>

      <footer style={{ borderTop: '1px solid var(--border-subtle)', backgroundColor: '#ffffff', padding: '1.25rem 1.5rem', marginTop: 'auto' }}>
        <div style={{ maxWidth: '1440px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem', fontSize: '0.75rem', color: 'var(--slate-500)' }}>
          <div>
            <strong>RETIVA v1.0.0</strong> — Platform Skrining Retinopati Diabetik Nasional. Dikembangkan sesuai Standar Pelayanan Kedokteran Perdami & Konsensus ADA 2024.
          </div>
          <div>
            Kepatuhan Keamanan Data: Permenkes No. 24 Tahun 2022 &amp; UU Perlindungan Data Pribadi No. 27 Tahun 2022.
          </div>
        </div>
      </footer>
    </div>
  );
}
