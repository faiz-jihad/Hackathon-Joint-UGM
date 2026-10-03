import React from 'react';

interface DashboardViewProps {
  onStartScreening?: () => void;
  onOpenReview?: (screeningId: string) => void;
}

export function DashboardView({ onStartScreening, onOpenReview }: DashboardViewProps) {
  return (
    <div className="dashboard-content-clean" style={{ minHeight: '100%', padding: '1.5rem' }}>
      {/* Konten dashboard bersih */}
    </div>
  );
}
