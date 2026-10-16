'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { CharacterSelectView, CharacterRole } from '../components/CharacterSelectView';
import { ClinicalDashboardShell } from '../components/ClinicalDashboardShell';

function HomeContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const roleParam = searchParams.get('role') as CharacterRole | null;
  const isAuth = searchParams.get('auth') === '1';

  const [lastRole, setLastRole] = useState<CharacterRole>(() => {
    if (roleParam && ['admin', 'dokter'].includes(roleParam)) {
      return roleParam;
    }
    return 'admin';
  });

  const [currentRole, setCurrentRole] = useState<CharacterRole | null>(() => {
    if (roleParam && isAuth) return roleParam;
    return null;
  });

  useEffect(() => {
    if (roleParam && ['admin', 'dokter'].includes(roleParam)) {
      setLastRole(roleParam);
    } else {
      setLastRole('admin');
    }
  }, [roleParam]);

  useEffect(() => {
    if (roleParam && isAuth) {
      router.replace(`/dashboard/${roleParam}`);
    } else {
      setCurrentRole(null);
    }
  }, [roleParam, isAuth, router]);

  const handleRoleSelectedForLogin = (role: CharacterRole) => {
    setLastRole(role);
    try {
      localStorage.setItem('retiva_last_role', role);
    } catch {}
    router.push(`/login/${role}`);
  };

  // 1. DEFAULT ROUTE: Retro Game Character Select Screen
  if (currentRole === null) {
    return (
      <CharacterSelectView
        onSelectRole={handleRoleSelectedForLogin}
        initialRole={lastRole}
      />
    );
  }

  // Fallback if currentRole is directly rendered without redirect
  return <ClinicalDashboardShell role={currentRole} />;
}

export default function HomePage() {
  return (
    <Suspense fallback={<div className="modern-character-stage" />}>
      <HomeContent />
    </Suspense>
  );
}
