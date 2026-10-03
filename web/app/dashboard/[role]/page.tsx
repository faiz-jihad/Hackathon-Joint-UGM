'use client';

import React, { Suspense } from 'react';
import { useParams } from 'next/navigation';
import { ClinicalDashboardShell } from '@/components/ClinicalDashboardShell';
import { CharacterRole } from '@/components/CharacterSelectView';

function DashboardContent() {
  const params = useParams();
  const roleParam = (params?.role as string)?.toLowerCase();

  const validRoles: CharacterRole[] = ['pengguna', 'admin', 'dokter'];
  const role: CharacterRole = validRoles.includes(roleParam as CharacterRole)
    ? (roleParam as CharacterRole)
    : 'admin';

  return <ClinicalDashboardShell role={role} />;
}

export default function RoleDashboardPage() {
  return (
    <Suspense fallback={<div className="loading-stage"><span>Memuat Dashboard...</span></div>}>
      <DashboardContent />
    </Suspense>
  );
}
