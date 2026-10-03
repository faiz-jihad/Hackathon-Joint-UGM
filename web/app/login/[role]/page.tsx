'use client';

import React, { Suspense } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { RoleLoginView } from '@/components/RoleLoginView';
import { CharacterRole } from '@/components/CharacterSelectView';

function RoleLoginContent() {
  const params = useParams();
  const router = useRouter();

  const roleParam = (params?.role as string)?.toLowerCase();

  const validRoles: CharacterRole[] = ['pengguna', 'admin', 'dokter'];
  const role: CharacterRole = validRoles.includes(roleParam as CharacterRole)
    ? (roleParam as CharacterRole)
    : 'admin';

  const handleLoginSuccess = (selectedRole: CharacterRole) => {
    router.push(`/dashboard/${selectedRole}`);
  };

  const handleBackToCharacterSelect = () => {
    try {
      localStorage.setItem('retiva_last_role', role);
    } catch {}
    router.push(`/?role=${role}`);
  };

  return (
    <RoleLoginView
      role={role}
      onLoginSuccess={handleLoginSuccess}
      onBackToCharacterSelect={handleBackToCharacterSelect}
    />
  );
}

export default function RoleLoginPage() {
  return (
    <Suspense fallback={<div className="modern-login-wrapper" />}>
      <RoleLoginContent />
    </Suspense>
  );
}

