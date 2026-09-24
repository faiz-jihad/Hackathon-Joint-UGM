import React from 'react';
import { InfoIcon } from './Icons';

export function DisclaimerBanner() {
  return (
    <div className="disclaimer-banner">
      <div className="disclaimer-inner">
        <InfoIcon size={15} style={{ color: 'var(--brand-700)', flexShrink: 0 }} />
        <span>
          <strong>Pemberitahuan Klinis:</strong> Hasil skrining RETIVA berfungsi sebagai instrumen pendukung keputusan klinis (CDSS) dan <u>bukan merupakan diagnosis medis final</u>. Keputusan penegakan diagnosis, rujukan FKRTL, dan tatalaksana medis merupakan kewenangan penuh dokter atau spesialis mata yang berwenang.
        </span>
      </div>
    </div>
  );
}
