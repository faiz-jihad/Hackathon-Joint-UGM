'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function RegisterIndexPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace('/register/pengguna');
  }, [router]);

  return null;
}
