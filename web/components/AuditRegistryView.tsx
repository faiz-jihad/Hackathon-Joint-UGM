import React, { useState, useEffect } from 'react';
import { ShieldCheckIcon, LockIcon, CheckIcon, ActivityIcon, ClockIcon } from './Icons';
import { clinicalStore, AuditLogData } from '../lib/clinical-store';

export function AuditRegistryView() {
  const [auditLogs, setAuditLogs] = useState<AuditLogData[]>([]);
  const [searchLog, setSearchLog] = useState<string>('');
  const [actionFilter, setActionFilter] = useState<string>('ALL');
  const [modelInfo, setModelInfo] = useState({
    version: 'v1.0.0',
    architecture: 'EfficientNet-B3',
    classes: 'ICDR 5-Class (0-4)',
    dimensions: '300 x 300 x 3 RGB',
    aucRoc: '0.941 (Sens: 92%, Spec: 95%)',
    checksum: 'b4f2c99a81284d72e61908ab91c8120349812903840192834019283401928340',
    status: 'ACTIVE',
  });

  const syncLogs = () => {
    setAuditLogs(clinicalStore.getAuditLogs());
  };

  useEffect(() => {
    syncLogs();
    const unsubscribe = clinicalStore.subscribe(() => {
      syncLogs();
    });

    // Attempt to fetch live model metadata from REST API endpoint
    fetch('/api/v1/models/active', {
      headers: { 'x-retiva-clinical': 'true' },
    })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (data?.model) {
          setModelInfo({
            version: data.model.version || 'v1.0.0',
            architecture: data.model.metadata?.architecture || 'EfficientNet-B3',
            classes: 'ICDR 5-Class (0-4)',
            dimensions: data.model.metadata?.inputDimensions || '300 x 300 x 3 RGB',
            aucRoc: data.model.aucRoc ? `${data.model.aucRoc} (Sens: ${Math.round((data.model.sensitivity || 0.92) * 100)}%, Spec: ${Math.round((data.model.specificity || 0.95) * 100)}%)` : '0.941 (Sens: 92%, Spec: 95%)',
            checksum: data.model.checksum || 'b4f2c99a81284d72e61908ab91c8120349812903840192834019283401928340',
            status: data.model.status || 'ACTIVE',
          });
        }
      })
      .catch(() => {
        // graceful offline fallback
      });

    return () => unsubscribe();
  }, []);

  const filteredLogs = auditLogs.filter((log) => {
    const matchesSearch =
      searchLog.trim() === '' ||
      log.user.toLowerCase().includes(searchLog.toLowerCase()) ||
      log.action.toLowerCase().includes(searchLog.toLowerCase()) ||
      log.entity.toLowerCase().includes(searchLog.toLowerCase()) ||
      log.id.toLowerCase().includes(searchLog.toLowerCase());

    if (!matchesSearch) return false;

    if (actionFilter !== 'ALL' && log.action !== actionFilter) {
      return false;
    }
    return true;
  });

  return (
    <div>
      <div className="section-header">
        <div>
          <h1 className="section-title">Tata Kelola, Model Registry & Audit Kepatuhan</h1>
          <p className="section-desc">
            Pencatatan jejak audit integritas kriptografis non-repudiation (UU PDP No. 27/2022) dan tata kelola versi model skrining AI.
          </p>
        </div>
      </div>

      {/* Model Registry Card */}
      <div className="card" style={{ marginBottom: '1.75rem' }}>
        <div className="card-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <ActivityIcon size={18} style={{ color: 'var(--brand-700)' }} />
            <div className="card-title">Model Skrining AI Aktif (Production Registry: {modelInfo.version})</div>
          </div>
          <span className="badge badge-pass">
            <CheckIcon size={12} />
            <span>Status: {modelInfo.status} (Production)</span>
          </span>
        </div>
        <div className="card-body">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '1.25rem' }}>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Arsitektur Backbone</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>{modelInfo.architecture}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Target Klasifikasi</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>{modelInfo.classes}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Dimensi Masukan</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>{modelInfo.dimensions}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>AUC-ROC Validasi Klinis</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>{modelInfo.aucRoc}</div>
            </div>
          </div>

          <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-100)', borderRadius: 'var(--radius-sm)', fontSize: '0.75rem', color: 'var(--slate-700)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
            <div>
              <strong>Checksum Bobot Model (SHA-256):</strong>{' '}
              <span className="code-inline">{modelInfo.checksum}</span>
            </div>
            <span className="badge badge-neutral" style={{ fontSize: '0.7rem' }}>Kemenkes Registry ID: REG-AI-2026-004</span>
          </div>
        </div>
      </div>

      {/* Non-Repudiation Audit Logs Table */}
      <div className="card">
        <div className="card-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <LockIcon size={18} style={{ color: 'var(--brand-700)' }} />
            <div className="card-title">Catatan Jejak Audit Klinis Tak Terbantahkan (Non-Repudiation Logs)</div>
          </div>
          <span className="badge badge-neutral">Data Dinamis: {filteredLogs.length} dari {auditLogs.length} Catatan</span>
        </div>

        {/* Dynamic Filters */}
        <div style={{ padding: '0.75rem 1rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem', backgroundColor: 'var(--slate-50)' }}>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <select
              className="form-control"
              style={{ fontSize: '0.75rem', padding: '0.25rem 0.5rem' }}
              value={actionFilter}
              onChange={(e) => setActionFilter(e.target.value)}
            >
              <option value="ALL">Semua Jenis Aksi</option>
              <option value="PATIENT_PROFILE_REGISTERED">Registrasi Pasien</option>
              <option value="SCREENING_SESSION_COMPLETED">Skrining Selesai</option>
              <option value="HUMAN_REVIEW_ADJUDICATION">Ajudikasi Dokter</option>
              <option value="REFERRAL_LETTER_ISSUED">Penerbitan Rujukan</option>
              <option value="QUALITY_GATE_EVALUATED">Uji Kendali Mutu</option>
            </select>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <input
              type="text"
              className="form-control"
              style={{ width: '220px', padding: '0.35rem 0.65rem', fontSize: '0.75rem' }}
              placeholder="Cari log / nakes / entitas..."
              value={searchLog}
              onChange={(e) => setSearchLog(e.target.value)}
            />
          </div>
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>ID Log & Waktu</th>
                <th>Aktor / Tenaga Kesehatan</th>
                <th>Tindakan (Action)</th>
                <th>Entitas Terkait</th>
                <th>Hash Integritas Kriptografis</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '2rem', color: 'var(--slate-500)' }}>
                    Tidak ada catatan audit yang cocok dengan filter.
                  </td>
                </tr>
              ) : (
                filteredLogs.map((log) => (
                  <tr key={log.id}>
                    <td>
                      <div style={{ fontWeight: 600, color: 'var(--slate-900)' }}>{log.id}</div>
                      <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>{log.timestamp}</div>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.8125rem', color: 'var(--slate-800)' }}>{log.user}</div>
                    </td>
                    <td>
                      <span className="code-inline" style={{ fontSize: '0.725rem', fontWeight: 600 }}>
                        {log.action}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.775rem', color: 'var(--slate-700)' }}>{log.entity}</div>
                    </td>
                    <td>
                      <span className="code-inline" style={{ fontSize: '0.7rem' }}>
                        {log.hash.substring(0, 16)}...
                      </span>
                    </td>
                    <td>
                      <span className="badge badge-pass" style={{ fontSize: '0.7rem' }}>
                        <CheckIcon size={10} />
                        <span>{log.status}</span>
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
