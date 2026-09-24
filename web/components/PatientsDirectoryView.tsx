import React, { useState, useEffect } from 'react';
import {
  UserIcon,
  SearchIcon,
  EyeIcon,
  ClockIcon,
  CheckIcon,
  CalendarIcon,
  HospitalIcon,
  ArrowRightIcon,
  FileTextIcon,
  AlertTriangleIcon,
} from './Icons';
import { clinicalStore, PatientData, ScreeningData } from '../lib/clinical-store';

interface PatientsDirectoryViewProps {
  onStartScreeningForPatient: (patientNik: string) => void;
}

export function PatientsDirectoryView({ onStartScreeningForPatient }: PatientsDirectoryViewProps) {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [patients, setPatients] = useState<PatientData[]>([]);
  const [selectedPatientId, setSelectedPatientId] = useState<string>('');
  const [screenings, setScreenings] = useState<ScreeningData[]>([]);
  const [showAddModal, setShowAddModal] = useState<boolean>(false);

  // New Patient Form State
  const [newNik, setNewNik] = useState<string>('');
  const [newName, setNewName] = useState<string>('');
  const [newAge, setNewAge] = useState<number>(50);
  const [newGender, setNewGender] = useState<'L' | 'P'>('L');
  const [newDmType, setNewDmType] = useState<'TYPE_1' | 'TYPE_2' | 'GESTATIONAL'>('TYPE_2');
  const [newDuration, setNewDuration] = useState<number>(5);
  const [newHba1c, setNewHba1c] = useState<string>('7.5');
  const [newTreatment, setNewTreatment] = useState<'LIFESTYLE' | 'ORAL' | 'INSULIN' | 'COMBINATION'>('ORAL');

  const loadData = () => {
    const list = clinicalStore.getPatients(searchTerm);
    setPatients(list);
    if (list.length > 0 && (!selectedPatientId || !list.find((p) => p.id === selectedPatientId))) {
      setSelectedPatientId(list[0].id);
    }
    setScreenings(clinicalStore.getScreenings());
  };

  useEffect(() => {
    loadData();
  }, [searchTerm]);

  const selectedPatient = patients.find((p) => p.id === selectedPatientId) || patients[0];

  // Dynamic longitudinal screening history for this patient
  const patientHistory = screenings.filter(
    (s) => (selectedPatient && s.patientId === selectedPatient.id) || (selectedPatient && s.patientNik === selectedPatient.nik)
  );

  const handleCreatePatient = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNik || !newName) return;

    const created = clinicalStore.addPatient({
      nik: newNik,
      name: newName,
      age: Number(newAge),
      gender: newGender,
      diabetesProfile: {
        type: newDmType,
        durationYears: Number(newDuration),
        hba1c: parseFloat(newHba1c) || 7.0,
        treatment: newTreatment,
      },
    });

    setShowAddModal(false);
    setNewNik('');
    setNewName('');
    loadData();
    setSelectedPatientId(created.id);
  };

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Direktori Pasien & Riwayat Longitudinal</h1>
          <p className="section-desc">
            Pencarian rekam medis skrining diabetes melitus, pelacakan progresivitas lesi retina tahunan, dan kepatuhan tindak lanjut.
          </p>
        </div>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => setShowAddModal(true)}
        >
          <UserIcon size={16} />
          <span>Tambah Pasien Baru</span>
        </button>
      </div>

      {/* Add Patient Modal */}
      {showAddModal && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(2px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '1rem' }}>
          <div className="card" style={{ maxWidth: '540px', width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
            <div className="card-header">
              <div className="card-title">Registrasi Pasien Diabetes Baru</div>
              <button type="button" className="btn btn-outline btn-sm" onClick={() => setShowAddModal(false)}>
                Tutup
              </button>
            </div>
            <form onSubmit={handleCreatePatient} className="card-body">
              <div className="form-group">
                <label className="form-label" htmlFor="new-patient-nik">NIK (16 Digit)</label>
                <input
                  id="new-patient-nik"
                  type="text"
                  className="form-control"
                  value={newNik}
                  onChange={(e) => setNewNik(e.target.value)}
                  maxLength={16}
                  required
                  placeholder="34040..."
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="new-patient-name">Nama Lengkap Pasien</label>
                <input
                  id="new-patient-name"
                  type="text"
                  className="form-control"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  required
                />
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-age">Usia (Tahun)</label>
                  <input
                    id="new-patient-age"
                    type="number"
                    className="form-control"
                    value={newAge}
                    onChange={(e) => setNewAge(Number(e.target.value))}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-gender">Jenis Kelamin</label>
                  <select
                    id="new-patient-gender"
                    className="form-control"
                    value={newGender}
                    onChange={(e) => setNewGender(e.target.value as any)}
                  >
                    <option value="L">Laki-laki</option>
                    <option value="P">Perempuan</option>
                  </select>
                </div>
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-dm-type">Tipe Diabetes</label>
                  <select
                    id="new-patient-dm-type"
                    className="form-control"
                    value={newDmType}
                    onChange={(e) => setNewDmType(e.target.value as any)}
                  >
                    <option value="TYPE_2">DM Tipe 2</option>
                    <option value="TYPE_1">DM Tipe 1</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-duration">Durasi Sakit (Th)</label>
                  <input
                    id="new-patient-duration"
                    type="number"
                    className="form-control"
                    value={newDuration}
                    onChange={(e) => setNewDuration(Number(e.target.value))}
                  />
                </div>
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-hba1c">HbA1c (%)</label>
                  <input
                    id="new-patient-hba1c"
                    type="text"
                    className="form-control"
                    value={newHba1c}
                    onChange={(e) => setNewHba1c(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label" htmlFor="new-patient-treatment">Regimen Terapi</label>
                  <select
                    id="new-patient-treatment"
                    className="form-control"
                    value={newTreatment}
                    onChange={(e) => setNewTreatment(e.target.value as any)}
                  >
                    <option value="ORAL">Obat Oral (OHO)</option>
                    <option value="INSULIN">Insulin</option>
                    <option value="COMBINATION">Kombinasi</option>
                    <option value="LIFESTYLE">Gaya Hidup</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
                <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>
                  <span>Simpan Data Pasien</span>
                </button>
                <button type="button" className="btn btn-outline" onClick={() => setShowAddModal(false)}>
                  Batal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="grid-3" style={{ gridTemplateColumns: '1.2fr 2fr' }}>
        {/* Left: Patient List & Live Search */}
        <div className="card">
          <div className="card-header">
            <div className="card-title">Daftar Pasien Terdaftar</div>
            <span className="badge badge-neutral">{patients.length} Pasien</span>
          </div>
          <div style={{ padding: '0.75rem 1rem', borderBottom: '1px solid var(--border-subtle)' }}>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                className="form-control"
                placeholder="Cari nama atau NIK pasien..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                style={{ paddingLeft: '2rem' }}
              />
              <div style={{ position: 'absolute', left: '0.65rem', top: '0.65rem', color: 'var(--slate-400)' }}>
                <SearchIcon size={15} />
              </div>
            </div>
          </div>
          <div style={{ maxHeight: '600px', overflowY: 'auto' }}>
            {patients.length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--slate-500)', fontSize: '0.8125rem' }}>
                Tidak ada pasien ditemukan.
              </div>
            ) : (
              patients.map((patient) => (
                <div
                  key={patient.id}
                  onClick={() => setSelectedPatientId(patient.id)}
                  style={{
                    padding: '1rem',
                    borderBottom: '1px solid var(--border-subtle)',
                    cursor: 'pointer',
                    backgroundColor: selectedPatient && patient.id === selectedPatient.id ? 'var(--brand-50)' : '#ffffff',
                    borderLeft: selectedPatient && patient.id === selectedPatient.id ? '4px solid var(--brand-700)' : '4px solid transparent',
                    transition: 'background-color 0.15s ease',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div style={{ fontWeight: 600, color: 'var(--slate-900)' }}>{patient.name}</div>
                    <span className="code-inline" style={{ fontSize: '0.7rem' }}>{patient.age} Th</span>
                  </div>
                  <div style={{ fontSize: '0.725rem', color: 'var(--slate-500)', marginTop: '0.15rem' }}>
                    NIK: {patient.nik}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--slate-700)', marginTop: '0.35rem', fontWeight: 500 }}>
                    {patient.diabetesProfile.type === 'TYPE_2' ? 'DM Tipe 2' : 'DM Tipe 1'} • HbA1c: {patient.diabetesProfile.hba1c}%
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right: Selected Patient Profile & Dynamic Longitudinal Timeline */}
        {selectedPatient ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            {/* Patient Profile Card */}
            <div className="card">
              <div className="card-header">
                <div className="card-title">Profil Pasien & Status Diabetes</div>
                <button
                  type="button"
                  className="btn btn-primary btn-sm"
                  onClick={() => onStartScreeningForPatient(selectedPatient.nik)}
                >
                  <EyeIcon size={14} />
                  <span>Skrining Pasien Ini</span>
                </button>
              </div>
              <div className="card-body">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.25rem' }}>
                  <div style={{ width: '48px', height: '48px', borderRadius: '50%', backgroundColor: 'var(--brand-100)', color: 'var(--brand-800)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <UserIcon size={24} />
                  </div>
                  <div>
                    <div style={{ fontSize: '1.125rem', fontWeight: 700, color: 'var(--slate-900)' }}>
                      {selectedPatient.name}
                    </div>
                    <div style={{ fontSize: '0.775rem', color: 'var(--slate-500)' }}>
                      NIK: {selectedPatient.nik} • {selectedPatient.gender === 'L' ? 'Laki-laki' : 'Perempuan'} • {selectedPatient.age} Tahun
                    </div>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '0.75rem' }}>
                  <div style={{ padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Klasifikasi DM</div>
                    <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-800)' }}>
                      {selectedPatient.diabetesProfile.type === 'TYPE_2' ? 'DM Tipe 2' : 'DM Tipe 1'}
                    </div>
                  </div>
                  <div style={{ padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Durasi Sakit</div>
                    <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-800)' }}>
                      {selectedPatient.diabetesProfile.durationYears} Tahun
                    </div>
                  </div>
                  <div style={{ padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>HbA1c Terakhir</div>
                    <div style={{ fontSize: '0.8125rem', fontWeight: 700, color: selectedPatient.diabetesProfile.hba1c > 8.0 ? 'var(--status-review-text)' : 'var(--status-pass-text)' }}>
                      {selectedPatient.diabetesProfile.hba1c}%
                    </div>
                  </div>
                  <div style={{ padding: '0.625rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Regimen Terapi</div>
                    <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-800)' }}>
                      {selectedPatient.diabetesProfile.treatment}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Dynamic Longitudinal Timeline per Section 4.9 */}
            <div className="card">
              <div className="card-header">
                <div className="card-title">Riwayat Longitudinal Skrining Retina</div>
                <span className="badge badge-neutral">{patientHistory.length} Pemeriksaan Terdata</span>
              </div>
              <div className="card-body">
                {patientHistory.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2rem 1rem', color: 'var(--slate-500)' }}>
                    <div style={{ marginBottom: '0.5rem', fontWeight: 600, color: 'var(--slate-800)' }}>
                      Belum Ada Riwayat Skrining
                    </div>
                    <p style={{ fontSize: '0.8125rem', marginBottom: '1rem' }}>
                      Mulai skrining retina untuk pasien ini untuk membuat catatan pertama.
                    </p>
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      onClick={() => onStartScreeningForPatient(selectedPatient.nik)}
                    >
                      <EyeIcon size={14} />
                      <span>Mulai Skrining Sekarang</span>
                    </button>
                  </div>
                ) : (
                  <div style={{ position: 'relative', paddingLeft: '1.5rem', borderLeft: '2px solid var(--slate-200)', marginLeft: '0.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    {patientHistory.map((record, idx) => (
                      <div key={record.id} style={{ position: 'relative' }}>
                        <div
                          style={{
                            position: 'absolute',
                            left: '-1.95rem',
                            top: '0.15rem',
                            width: '12px',
                            height: '12px',
                            borderRadius: '50%',
                            backgroundColor: idx === 0 ? 'var(--brand-700)' : 'var(--slate-400)',
                            border: '2px solid #ffffff',
                            boxShadow: '0 0 0 2px var(--slate-200)',
                          }}
                        />

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                          <span className="code-inline" style={{ fontWeight: 600 }}>
                            {new Date(record.capturedAt).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })}
                          </span>
                          <span className="badge badge-neutral" style={{ fontSize: '0.7rem' }}>
                            {record.humanReview?.status === 'CONFIRMED_AI' ? 'Telah Ditelaah Dokter' : record.reliabilityLabel}
                          </span>
                        </div>

                        <div style={{ fontWeight: 700, color: 'var(--slate-900)', fontSize: '0.875rem' }}>
                          Pemeriksaan Funduskopi Digital {record.eye === 'OD' ? 'Oculus Dexter (Mata Kanan)' : 'Oculus Sinister (Mata Kiri)'}
                        </div>

                        <div style={{ fontSize: '0.8125rem', color: 'var(--slate-700)', marginTop: '0.35rem' }}>
                          <strong>Temuan:</strong> {record.aiResult?.drLabel || record.qualityCheck.reason || 'Selesai'}
                        </div>

                        {record.recommendation && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', marginTop: '0.2rem' }}>
                            <strong>Tindak Lanjut:</strong> {record.recommendation.action}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        ) : (
          <div className="card" style={{ padding: '3rem', textAlign: 'center', color: 'var(--slate-500)' }}>
            Pilih pasien dari daftar untuk melihat profil dan riwayat longitudinal.
          </div>
        )}
      </div>
    </div>
  );
}
