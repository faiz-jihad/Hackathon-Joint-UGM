'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function DashboardIndexPage() {
  const router = useRouter();

  useEffect(() => {
    let targetRole = 'admin';
    try {
      const savedUserStr = localStorage.getItem('retiva_current_user');
      if (savedUserStr) {
        const parsed = JSON.parse(savedUserStr);
        if (parsed?.role === 'PATIENT') targetRole = 'pengguna';
        else if (parsed?.role === 'OPHTHALMOLOGIST') targetRole = 'dokter';
        else if (parsed?.role === 'ADMIN' || parsed?.role === 'HEALTHCARE_WORKER') targetRole = 'admin';
      } else {
        const last = localStorage.getItem('retiva_last_role');
        if (last && ['pengguna', 'admin', 'dokter'].includes(last)) {
          targetRole = last;
        }
      }
    } catch {}

    router.replace(`/dashboard/${targetRole}`);
  }, [router]);

  return null;
}
