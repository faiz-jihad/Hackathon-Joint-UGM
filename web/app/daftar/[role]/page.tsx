'use client';

import React from 'react';
import { useParams } from 'next/navigation';
import { RoleRegisterView } from '@/components/RoleRegisterView';
import { CharacterRole } from '@/components/CharacterSelectView';

export default function DaftarRolePage() {
  const params = useParams();
  const roleParam = (params?.role as string)?.toLowerCase();

  const validRoles: CharacterRole[] = ['pengguna', 'admin', 'dokter'];
  const role: CharacterRole = validRoles.includes(roleParam as CharacterRole)
    ? (roleParam as CharacterRole)
    : 'pengguna';

  return <RoleRegisterView role={role} />;
}
