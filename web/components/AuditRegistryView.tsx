import React, { useState, useEffect } from 'react';
import { ShieldCheckIcon, LockIcon, CheckIcon, ActivityIcon, ClockIcon } from './Icons';
import { clinicalStore, AuditLogData } from '../lib/clinical-store';

export function AuditRegistryView() {
  const [auditLogs, setAuditLogs] = useState<AuditLogData[]>([]);

  useEffect(() => {
    setAuditLogs(clinicalStore.getAuditLogs());
  }, []);

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
            <div className="card-title">Model Skrining AI Aktif (Production Registry)</div>
          </div>
          <span className="badge badge-pass">
            <CheckIcon size={12} />
            <span>Status: ACTIVE (Production)</span>
          </span>
        </div>
        <div className="card-body">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '1.25rem' }}>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Arsitektur Backbone</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>EfficientNet-B3</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Target Klasifikasi</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>ICDR 5-Class (0-4)</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>Dimensi Masukan</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--slate-900)' }}>300 x 300 x 3 RGB</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-50)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--slate-500)' }}>AUC-ROC Validasi Klinis</div>
              <div style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--status-pass-text)' }}>0.941 (Sens: 92%, Spec: 95%)</div>
            </div>
          </div>

          <div style={{ padding: '0.75rem', backgroundColor: 'var(--slate-100)', borderRadius: 'var(--radius-sm)', fontSize: '0.75rem', color: 'var(--slate-700)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
            <div>
              <strong>Checksum Bobot Model (SHA-256):</strong>{' '}
              <span className="code-inline">b4f2c99a81284d72e61908ab91c8120349812903840192834019283401928340</span>
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
          <span className="badge badge-neutral">Data Dinamis: {auditLogs.length} Catatan Terverifikasi</span>
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
              {auditLogs.map((log) => (
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
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
