import React, { useState, useEffect } from 'react';
import {
  HospitalIcon,
  MapPinIcon,
  PhoneIcon,
  CheckIcon,
  CalendarIcon,
  FileTextIcon,
  ArrowRightIcon,
  ShieldCheckIcon,
} from './Icons';
import { clinicalStore, FacilityData, ReferralData } from '../lib/clinical-store';

interface ReferralsFacilityViewProps {
  initialPatientName?: string;
}

export function ReferralsFacilityView({ initialPatientName = 'Bambang Sudarmono' }: ReferralsFacilityViewProps) {
  const [facilities, setFacilities] = useState<FacilityData[]>([]);
  const [selectedFacilityId, setSelectedFacilityId] = useState<string>('FAC-001');
  const [patientName, setPatientName] = useState<string>(initialPatientName);
  const [clinicalNotes, setClinicalNotes] = useState<string>(
    'Mohon evaluasi lanjutan vitreoretina dan pertimbangan Optical Coherence Tomography (OCT) untuk menyingkirkan Diabetic Macular Edema (DME). Pasien telah diskrining di FKTP Puskesmas Mlati II.'
  );
  const [issuedReferrals, setIssuedReferrals] = useState<ReferralData[]>([]);
  const [latestIssued, setLatestIssued] = useState<ReferralData | null>(null);

  useEffect(() => {
    setFacilities(clinicalStore.getFacilities());
    setIssuedReferrals(clinicalStore.getReferrals());
  }, []);

  const selectedFacility = facilities.find((f) => f.id === selectedFacilityId) || facilities[0];

  const handleIssueReferral = () => {
    if (!selectedFacility) return;

    const newRef = clinicalStore.createReferral({
      patientId: 'P-001',
      patientName,
      facilityId: selectedFacility.id,
      facilityName: selectedFacility.name,
      indication: 'E11.319 - Type 2 diabetes with nonproliferative diabetic retinopathy',
      urgencyDays: 30,
      notes: clinicalNotes,
    });

    setLatestIssued(newRef);
    setIssuedReferrals(clinicalStore.getReferrals());
  };

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Jaringan Fasilitas Rujukan Mata & Penjadwalan</h1>
          <p className="section-desc">
            Pencocokan fasilitas kesehatan sekunder/tersier (FKRTL) berdasarkan jarak geodesik Haversine dan verifikasi kepesertaan JKN/BPJS.
          </p>
        </div>
      </div>

      <div className="grid-3" style={{ gridTemplateColumns: '1.4fr 1.6fr' }}>
        {/* Left: Facility Cards List per Section 4.11 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-700)' }}>
            Fasilitas Rujukan Terdekat dari Puskesmas Mlati II (Jarak Geodesik):
          </div>

          {facilities.map((fac) => (
            <div
              key={fac.id}
              onClick={() => {
                setSelectedFacilityId(fac.id);
                setLatestIssued(null);
              }}
              className="card"
              style={{
                cursor: 'pointer',
                borderColor: fac.id === selectedFacilityId ? 'var(--brand-700)' : 'var(--border-card)',
                boxShadow: fac.id === selectedFacilityId ? '0 0 0 1px var(--brand-700)' : 'var(--shadow-sm)',
              }}
            >
              <div className="card-body">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <div style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--slate-900)' }}>
                      {fac.name}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.1rem' }}>
                      {fac.type}
                    </div>
                  </div>
                  <span className="badge badge-info" style={{ fontSize: '0.7rem' }}>
                    {fac.distanceKm} km
                  </span>
                </div>

                <div style={{ fontSize: '0.75rem', color: 'var(--slate-600)', marginTop: '0.5rem', lineHeight: 1.4 }}>
                  <strong>Layanan Khusus:</strong> {fac.service}
                </div>

                <div style={{ marginTop: '0.625rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                  {fac.bpjsVerified ? (
                    <span className="badge badge-pass" style={{ fontSize: '0.7rem' }}>
                      <CheckIcon size={12} />
                      <span>{fac.bpjsStatus}</span>
                    </span>
                  ) : (
                    <span className="badge badge-review" style={{ fontSize: '0.7rem' }}>
                      <span>{fac.bpjsStatus}</span>
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Right: Referral Dispatch & Scheduling Card */}
        <div className="card">
          <div className="card-header">
            <div className="card-title">Penerbitan Surat Pengantar Rujukan (SPK)</div>
            <span className="badge badge-neutral">Standar Integrasi BPJS / SatuSehat</span>
          </div>
          <div className="card-body">
            {latestIssued ? (
              <div style={{ padding: '2rem', textAlign: 'center', backgroundColor: 'var(--status-pass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--status-pass-border)' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: 'var(--brand-600)', color: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 0.75rem auto' }}>
                  <CheckIcon size={20} />
                </div>
                <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>
                  Surat Rujukan Elektronik Berhasil Diterbitkan
                </div>
                <div style={{ fontSize: '0.8125rem', color: 'var(--slate-700)', marginTop: '0.5rem', lineHeight: 1.5 }}>
                  Nomor Rujukan: <span className="code-inline">{latestIssued.id}</span>
                  <br />
                  Pasien: <strong>{latestIssued.patientName}</strong> dirujuk ke <strong>{latestIssued.facilityName}</strong>.
                  <br />
                  Batas waktu kedatangan: {latestIssued.urgencyDays} hari kalender.
                </div>
                <div style={{ marginTop: '1.25rem', display: 'flex', gap: '0.5rem', justifyContent: 'center' }}>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={() => setLatestIssued(null)}
                  >
                    <span>Terbitkan Rujukan Lain</span>
                  </button>
                </div>
              </div>
            ) : selectedFacility ? (
              <div>
                <div style={{ padding: '0.875rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', marginBottom: '1.25rem' }}>
                  <div style={{ fontSize: '0.725rem', fontWeight: 600, color: 'var(--slate-500)', textTransform: 'uppercase' }}>
                    Tujuan Rujukan Terpilih:
                  </div>
                  <div style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--slate-900)', marginTop: '0.2rem' }}>
                    {selectedFacility.name}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.25rem' }}>
                    <MapPinIcon size={14} />
                    <span>{selectedFacility.address}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.2rem' }}>
                    <PhoneIcon size={14} />
                    <span>Telepon Instalasi: {selectedFacility.phone}</span>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label" htmlFor="referral-patient-input">Nama Pasien Yang Dirujuk:</label>
                  <input
                    id="referral-patient-input"
                    type="text"
                    className="form-control"
                    value={patientName}
                    onChange={(e) => setPatientName(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label" htmlFor="referral-indication-input">Indikasi Klinis Rujukan (ICD-10):</label>
                  <input
                    id="referral-indication-input"
                    type="text"
                    className="form-control"
                    value="E11.319 - Type 2 diabetes with nonproliferative diabetic retinopathy"
                    readOnly
                    style={{ backgroundColor: 'var(--slate-100)' }}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label" htmlFor="referral-notes-input">Instruksi Khusus untuk FKRTL:</label>
                  <textarea
                    id="referral-notes-input"
                    className="form-control"
                    rows={3}
                    value={clinicalNotes}
                    onChange={(e) => setClinicalNotes(e.target.value)}
                  />
                </div>

                <div style={{ marginTop: '1.25rem' }}>
                  <button
                    type="button"
                    className="btn btn-primary"
                    style={{ width: '100%', padding: '0.65rem' }}
                    onClick={handleIssueReferral}
                  >
                    <FileTextIcon size={16} />
                    <span>Terbitkan Surat Rujukan Resmi</span>
                  </button>
                </div>
              </div>
            ) : null}

            {/* List of Issued Referrals */}
            {issuedReferrals.length > 0 && (
              <div style={{ marginTop: '1.75rem', borderTop: '1px solid var(--border-subtle)', paddingTop: '1rem' }}>
                <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-800)', marginBottom: '0.5rem' }}>
                  Daftar Rujukan Yang Telah Diterbitkan ({issuedReferrals.length}):
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                  {issuedReferrals.slice(0, 3).map((ref) => (
                    <div key={ref.id} style={{ padding: '0.5rem 0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', fontSize: '0.75rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 600 }}>
                        <span>{ref.patientName} &rarr; {ref.facilityName}</span>
                        <span className="code-inline">{ref.id}</span>
                      </div>
                      <div style={{ color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                        Batas waktu: {ref.urgencyDays} hari • {new Date(ref.createdAt).toLocaleDateString('id-ID')}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
