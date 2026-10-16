import React, { useState, useEffect, useRef } from "react";
import {
  EmergencyIncidentDto,
  EmergencyIncidentStatus,
  EmergencyUrgencyLevel,
} from "@/infrastructure/database/emergency-store";
import {
  AlertTriangleIcon,
  CheckIcon,
  ClockIcon,
  HospitalIcon,
} from "./Icons";

export function EmergencyMonitoringView() {
  const [incidents, setIncidents] = useState<EmergencyIncidentDto[]>([]);
  const [selectedIncident, setSelectedIncident] = useState<EmergencyIncidentDto | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [urgencyFilter, setUrgencyFilter] = useState<string>("ALL");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(true);
  const [sseConnected, setSseConnected] = useState<boolean>(false);
  const [stats, setStats] = useState({
    active: 0,
    acknowledged: 0,
    resolved: 0,
    critical: 0,
    total: 0,
  });

  // Action modal states
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [noteModalOpen, setNoteModalOpen] = useState<boolean>(false);
  const [noteText, setNoteText] = useState<string>("");
  const [actionTakenText, setActionTakenText] = useState<string>("");
  const [resolveModalOpen, setResolveModalOpen] = useState<boolean>(false);
  const [resolutionNotes, setResolutionNotes] = useState<string>("");

  const eventSourceRef = useRef<EventSource | null>(null);

  // Fetch incidents from API
  const fetchIncidents = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (statusFilter !== "ALL") params.append("status", statusFilter);
      if (urgencyFilter !== "ALL") params.append("urgency", urgencyFilter);
      if (searchQuery.trim()) params.append("search", searchQuery.trim());

      const res = await fetch(`/api/v1/sos/incidents?${params.toString()}`);
      if (res.ok) {
        const json = await res.json();
        setIncidents(json.data || []);
        if (json.stats) setStats(json.stats);

        // Keep selected incident updated
        if (selectedIncident) {
          const fresh = (json.data || []).find((i: EmergencyIncidentDto) => i.id === selectedIncident.id);
          if (fresh) setSelectedIncident(fresh);
        } else if (json.data && json.data.length > 0) {
          setSelectedIncident(json.data[0]);
        }
      }
    } catch (err) {
      console.error("Gagal memuat insiden darurat:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIncidents();
  }, [statusFilter, urgencyFilter]);

  // Connect to SSE stream for real-time live synchronization
  useEffect(() => {
    try {
      const sse = new EventSource("/api/v1/sos/stream");
      eventSourceRef.current = sse;

      sse.onopen = () => {
        setSseConnected(true);
      };

      sse.onmessage = (e) => {
        try {
          const payload = JSON.parse(e.data);
          if (payload.type === "INCIDENT_UPDATE" && payload.incident) {
            setIncidents((prev) => {
              const idx = prev.findIndex((i) => i.id === payload.incident.id);
              if (idx >= 0) {
                const updated = [...prev];
                updated[idx] = payload.incident;
                return updated;
              } else {
                return [payload.incident, ...prev];
              }
            });

            setSelectedIncident((current) => {
              if (current && current.id === payload.incident.id) {
                return payload.incident;
              }
              return current;
            });

            // Update stats
            fetchIncidents();
          }
        } catch (err) {
          console.error("SSE parse error:", err);
        }
      };

      sse.onerror = () => {
        setSseConnected(false);
      };

      return () => {
        sse.close();
      };
    } catch {
      setSseConnected(false);
    }
  }, []);

  // Responder Actions
  const handleAcknowledge = async () => {
    if (!selectedIncident) return;
    try {
      setActionLoading(true);
      const res = await fetch(`/api/v1/sos/incidents/${selectedIncident.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: "ACKNOWLEDGED",
          responderId: "usr-doctor-pkm",
          responderName: "dr. Nurul Aini (Dokter Puskesmas)",
          notes: "Insiden kedaruratan telah diterima dan sedang dikoordinasikan penanganannya.",
        }),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          setSelectedIncident(json.data);
          fetchIncidents();
        }
      }
    } catch (err) {
      console.error("Gagal menanggapi insiden:", err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleSaveNote = async () => {
    if (!selectedIncident || !noteText.trim()) return;
    try {
      setActionLoading(true);
      const res = await fetch(`/api/v1/sos/incidents/${selectedIncident.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          responderId: "usr-doctor-pkm",
          responderName: "dr. Nurul Aini (Dokter Puskesmas)",
          followUpNote: noteText.trim(),
          actionTaken: actionTakenText.trim() || "Instruksi Pemantauan",
        }),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          setSelectedIncident(json.data);
          fetchIncidents();
        }
        setNoteModalOpen(false);
        setNoteText("");
        setActionTakenText("");
      }
    } catch (err) {
      console.error("Gagal menambahkan catatan:", err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleResolve = async () => {
    if (!selectedIncident) return;
    try {
      setActionLoading(true);
      const res = await fetch(`/api/v1/sos/incidents/${selectedIncident.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: "RESOLVED",
          responderId: "usr-doctor-pkm",
          responderName: "dr. Nurul Aini (Dokter Puskesmas)",
          notes: resolutionNotes.trim() || "Kondisi pasien telah stabil, telah diedukasi atau dirujuk dengan aman.",
        }),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          setSelectedIncident(json.data);
          fetchIncidents();
        }
        setResolveModalOpen(false);
        setResolutionNotes("");
      }
    } catch (err) {
      console.error("Gagal menyelesaikan insiden:", err);
    } finally {
      setActionLoading(false);
    }
  };

  const filteredIncidents = incidents.filter((inc) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      inc.patientName.toLowerCase().includes(q) ||
      inc.patientNik.toLowerCase().includes(q) ||
      inc.symptoms.some((s) => s.toLowerCase().includes(q))
    );
  });

  const getUrgencyBadge = (level: EmergencyUrgencyLevel) => {
    switch (level) {
      case "CRITICAL":
        return {
          bg: "#FEF2F2",
          border: "#FCA5A5",
          text: "#B91C1C",
          label: "KRITIS (CRITICAL)",
        };
      case "HIGH":
        return {
          bg: "#FFFBEB",
          border: "#FCD34D",
          text: "#B45309",
          label: "TINGGI (HIGH)",
        };
      case "MEDIUM":
        return {
          bg: "#EFF6FF",
          border: "#93C5FD",
          text: "#1D4ED8",
          label: "SEDANG (MEDIUM)",
        };
      default:
        return {
          bg: "#F1F5F9",
          border: "#CBD5E1",
          text: "#475569",
          label: "RENDAH",
        };
    }
  };

  const getStatusBadge = (status: EmergencyIncidentStatus) => {
    switch (status) {
      case "ACTIVE":
        return {
          bg: "#FEF2F2",
          border: "#EF4444",
          text: "#DC2626",
          label: "AKTIF (MENUNGGU RESPON)",
        };
      case "ACKNOWLEDGED":
        return {
          bg: "#FFFBEB",
          border: "#F59E0B",
          text: "#D97706",
          label: "SEDANG DITANGANI",
        };
      case "RESOLVED":
        return {
          bg: "#ECFDF5",
          border: "#10B981",
          text: "#059669",
          label: "SELESAI (RESOLVED)",
        };
      case "CANCELLED":
        return {
          bg: "#F1F5F9",
          border: "#94A3B8",
          text: "#64748B",
          label: "DIBATALKAN PASIEN",
        };
    }
  };

  const formatTimeAgo = (dateStr: string) => {
    try {
      const diffSec = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
      if (diffSec < 60) return `${diffSec} detik lalu`;
      const diffMin = Math.floor(diffSec / 60);
      if (diffMin < 60) return `${diffMin} menit lalu`;
      const diffHour = Math.floor(diffMin / 60);
      return `${diffHour} jam lalu`;
    } catch {
      return dateStr;
    }
  };

  return (
    <div style={{ padding: "1.75rem", maxWidth: "1600px", margin: "0 auto" }}>
      {/* 1. Header & Live Telemetry Bar */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          marginBottom: "1.5rem",
          flexWrap: "wrap",
          gap: "1rem",
        }}
      >
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", marginBottom: "0.25rem" }}>
            <span
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                width: "32px",
                height: "32px",
                borderRadius: "8px",
                background: "#DC2626",
                color: "#FFFFFF",
                fontWeight: 800,
                fontSize: "14px",
              }}
            >
              SOS
            </span>
            <h1 style={{ fontSize: "1.65rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
              Retiva SOS — Pusat Monitoring Kedaruratan
            </h1>
          </div>
        </div>
      </div>

      {/* 2. KPI Summary Cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: "1rem",
          marginBottom: "1.5rem",
        }}
      >
        {/* Card 1 */}
        <div
          style={{
            background: "#FFFFFF",
            borderRadius: "14px",
            border: "1px solid #E2E8F0",
            padding: "1.25rem",
            boxShadow: "0 2px 6px rgba(15,23,42,0.04)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748B", textTransform: "uppercase", letterSpacing: "0.03em" }}>
              Insiden Aktif (Butuh Respon)
            </span>
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "10px",
                backgroundColor: stats.active > 0 ? "#FEE2E2" : "#EFF6FF",
                color: stats.active > 0 ? "#DC2626" : "#0F5FC2",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <AlertTriangleIcon size={18} />
            </div>
          </div>
          <div>
            <div style={{ fontSize: "1.85rem", fontWeight: 800, color: stats.active > 0 ? "#DC2626" : "#0F172A", marginTop: "0.4rem" }}>
              {stats.active}
            </div>
            <div style={{ fontSize: "0.75rem", color: stats.active > 0 ? "#DC2626" : "#64748B", marginTop: "0.3rem", fontWeight: 600 }}>
              {stats.critical} insiden berkategori KRITIS
            </div>
          </div>
        </div>

        {/* Card 2 */}
        <div
          style={{
            background: "#FFFFFF",
            borderRadius: "14px",
            border: "1px solid #E2E8F0",
            padding: "1.25rem",
            boxShadow: "0 2px 6px rgba(15,23,42,0.04)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748B", textTransform: "uppercase", letterSpacing: "0.03em" }}>
              Sedang Ditangani (In Progress)
            </span>
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "10px",
                backgroundColor: "#EFF6FF",
                color: "#0F5FC2",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <ClockIcon size={18} />
            </div>
          </div>
          <div>
            <div style={{ fontSize: "1.85rem", fontWeight: 800, color: "#0F172A", marginTop: "0.4rem" }}>
              {stats.acknowledged}
            </div>
            <div style={{ fontSize: "0.75rem", color: "#64748B", marginTop: "0.3rem", fontWeight: 600 }}>
              Dalam koordinasi dokter / perawat
            </div>
          </div>
        </div>

        {/* Card 3 */}
        <div
          style={{
            background: "#FFFFFF",
            borderRadius: "14px",
            border: "1px solid #E2E8F0",
            padding: "1.25rem",
            boxShadow: "0 2px 6px rgba(15,23,42,0.04)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748B", textTransform: "uppercase", letterSpacing: "0.03em" }}>
              Tertangani Aman (Resolved)
            </span>
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "10px",
                backgroundColor: "#EFF6FF",
                color: "#0F5FC2",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <CheckIcon size={18} />
            </div>
          </div>
          <div>
            <div style={{ fontSize: "1.85rem", fontWeight: 800, color: "#0F172A", marginTop: "0.4rem" }}>
              {stats.resolved}
            </div>
            <div style={{ fontSize: "0.75rem", color: "#059669", marginTop: "0.3rem", fontWeight: 600 }}>
              Pasien stabil &amp; dokumentasi tuntas
            </div>
          </div>
        </div>

        {/* Card 4 */}
        <div
          style={{
            background: "#FFFFFF",
            borderRadius: "14px",
            border: "1px solid #E2E8F0",
            padding: "1.25rem",
            boxShadow: "0 2px 6px rgba(15,23,42,0.04)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <span style={{ fontSize: "0.8rem", fontWeight: 700, color: "#64748B", textTransform: "uppercase", letterSpacing: "0.03em" }}>
              Layanan Rujukan Terhubung
            </span>
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "10px",
                backgroundColor: "#EFF6FF",
                color: "#0F5FC2",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <HospitalIcon size={18} />
            </div>
          </div>
          <div>
            <div style={{ fontSize: "1.15rem", fontWeight: 800, color: "#0F172A", marginTop: "0.4rem" }}>
              SPGDT 119 &amp; RS Mata YAP
            </div>
            <div style={{ fontSize: "0.75rem", color: "#64748B", marginTop: "0.3rem", fontWeight: 600 }}>
              Protokol kedaruratan aktif 24 jam
            </div>
          </div>
        </div>
      </div>

      {/* 3. Search & Filter Bar */}
      <div
        style={{
          background: "#FFFFFF",
          borderRadius: "12px",
          border: "1px solid #E2E8F0",
          padding: "1rem 1.25rem",
          marginBottom: "1.5rem",
          display: "flex",
          gap: "1rem",
          flexWrap: "wrap",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap", alignItems: "center", flex: "1 1 350px" }}>
          {/* Search Input */}
          <div style={{ position: "relative", flex: "1 1 240px", minWidth: "220px" }}>
            <input
              type="text"
              placeholder="Cari pasien, NIK, atau gejala..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: "100%",
                padding: "0.55rem 0.85rem 0.55rem 2.2rem",
                borderRadius: "8px",
                border: "1px solid #CBD5E1",
                fontSize: "0.875rem",
                outline: "none",
              }}
            />
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#94A3B8"
              strokeWidth="2"
              style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }}
            >
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
          </div>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            style={{
              padding: "0.55rem 0.85rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              fontSize: "0.85rem",
              background: "#FFFFFF",
              color: "#334155",
            }}
          >
            <option value="ALL">Semua Status</option>
            <option value="ACTIVE">Status: Aktif</option>
            <option value="ACKNOWLEDGED">Status: Sedang Ditangani</option>
            <option value="RESOLVED">Status: Selesai</option>
            <option value="CANCELLED">Status: Dibatalkan</option>
          </select>

          {/* Urgency Filter */}
          <select
            value={urgencyFilter}
            onChange={(e) => setUrgencyFilter(e.target.value)}
            style={{
              padding: "0.55rem 0.85rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              fontSize: "0.85rem",
              background: "#FFFFFF",
              color: "#334155",
            }}
          >
            <option value="ALL">Semua Urgensi</option>
            <option value="CRITICAL">Urgensi: KRITIS</option>
            <option value="HIGH">Urgensi: TINGGI</option>
            <option value="MEDIUM">Urgensi: SEDANG</option>
          </select>
        </div>

        <div style={{ fontSize: "0.85rem", color: "#64748B" }}>
          Menampilkan <strong>{filteredIncidents.length}</strong> insiden
        </div>
      </div>

      {/* 4. Split Screen: Incident List (Left) & Detailed Inspector (Right) */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "minmax(320px, 420px) 1fr",
          gap: "1.5rem",
          alignItems: "start",
        }}
      >
        {/* Left: Incident Feed */}
        <div
          style={{
            background: "#FFFFFF",
            borderRadius: "12px",
            border: "1px solid #E2E8F0",
            overflow: "hidden",
            boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
          }}
        >
          <div
            style={{
              padding: "1rem 1.25rem",
              borderBottom: "1px solid #E2E8F0",
              fontWeight: 700,
              color: "#0F172A",
              fontSize: "0.95rem",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <span>Daftar Panggilan Darurat</span>
            {loading && <span style={{ fontSize: "0.75rem", color: "#64748B" }}>Memuat...</span>}
          </div>

          <div style={{ maxHeight: "calc(100vh - 350px)", overflowY: "auto" }}>
            {filteredIncidents.length === 0 ? (
              <div style={{ padding: "3rem 1.5rem", textAlign: "center", color: "#94A3B8" }}>
                <svg
                  width="44"
                  height="44"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#CBD5E1"
                  strokeWidth="1.5"
                  style={{ margin: "0 auto 0.75rem auto" }}
                >
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                </svg>
                <div style={{ fontWeight: 600, fontSize: "0.95rem", color: "#64748B" }}>
                  Tidak ada panggilan darurat
                </div>
                <div style={{ fontSize: "0.825rem", marginTop: "0.25rem" }}>
                  Sistem siaga memantau seluruh pasien Retiva.
                </div>
              </div>
            ) : (
              filteredIncidents.map((inc) => {
                const isSelected = selectedIncident?.id === inc.id;
                const urgencyStyle = getUrgencyBadge(inc.urgencyLevel);
                const statusStyle = getStatusBadge(inc.status);

                return (
                  <div
                    key={inc.id}
                    onClick={() => setSelectedIncident(inc)}
                    style={{
                      padding: "1rem 1.25rem",
                      borderBottom: "1px solid #F1F5F9",
                      cursor: "pointer",
                      background: isSelected ? "#F0F9FF" : inc.status === "ACTIVE" ? "#FFFDFD" : "#FFFFFF",
                      borderLeft: isSelected
                        ? "4px solid #2196F3"
                        : inc.status === "ACTIVE"
                        ? "4px solid #EF4444"
                        : "4px solid transparent",
                      transition: "all 0.15s ease",
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.35rem" }}>
                      <span
                        style={{
                          fontSize: "0.72rem",
                          fontWeight: 700,
                          padding: "0.2rem 0.5rem",
                          borderRadius: "4px",
                          background: urgencyStyle.bg,
                          color: urgencyStyle.text,
                          border: `1px solid ${urgencyStyle.border}`,
                        }}
                      >
                        {urgencyStyle.label}
                      </span>
                      <span style={{ fontSize: "0.75rem", color: "#94A3B8", fontWeight: 500 }}>
                        {formatTimeAgo(inc.createdAt)}
                      </span>
                    </div>

                    <div style={{ fontWeight: 700, color: "#0F172A", fontSize: "0.95rem", marginBottom: "0.15rem" }}>
                      {inc.patientName}
                    </div>
                    <div style={{ fontSize: "0.78rem", color: "#64748B", marginBottom: "0.5rem" }}>
                      NIK: {inc.patientNik} • {inc.patientPhone || "No HP -"}
                    </div>

                    {/* Symptoms preview */}
                    <div style={{ display: "flex", gap: "0.35rem", flexWrap: "wrap", marginBottom: "0.6rem" }}>
                      {inc.symptoms.slice(0, 3).map((s, idx) => (
                        <span
                          key={idx}
                          style={{
                            fontSize: "0.72rem",
                            background: "#F1F5F9",
                            color: "#475569",
                            padding: "0.15rem 0.45rem",
                            borderRadius: "4px",
                          }}
                        >
                          {s}
                        </span>
                      ))}
                      {inc.symptoms.length > 3 && (
                        <span style={{ fontSize: "0.72rem", color: "#94A3B8" }}>
                          +{inc.symptoms.length - 3} lainnya
                        </span>
                      )}
                    </div>

                    {/* Bottom Status & Location badge */}
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: "0.75rem" }}>
                      <span
                        style={{
                          padding: "0.15rem 0.5rem",
                          borderRadius: "9999px",
                          fontWeight: 600,
                          background: statusStyle.bg,
                          color: statusStyle.text,
                          border: `1px solid ${statusStyle.border}`,
                        }}
                      >
                        {statusStyle.label}
                      </span>

                      <span style={{ color: inc.latitude ? "#059669" : "#D97706", fontWeight: 600, display: "flex", alignItems: "center", gap: "0.25rem" }}>
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                          <circle cx="12" cy="10" r="3" />
                        </svg>
                        <span>{inc.latitude ? "GPS Aktif" : "Menunggu GPS"}</span>
                      </span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Right: Detailed Inspection & Action Panel */}
        {selectedIncident ? (
          <div style={{ display: "flex", flexDirection: "column", gap: "1.25rem" }}>
            {/* Top Card: Patient Identity & Primary Action Buttons */}
            <div
              style={{
                background: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #E2E8F0",
                padding: "1.5rem",
                boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                  flexWrap: "wrap",
                  gap: "1rem",
                  marginBottom: "1.25rem",
                }}
              >
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", marginBottom: "0.3rem" }}>
                    <h2 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
                      {selectedIncident.patientName}
                    </h2>
                    <span
                      style={{
                        fontSize: "0.75rem",
                        fontWeight: 700,
                        padding: "0.25rem 0.6rem",
                        borderRadius: "6px",
                        ...getUrgencyBadge(selectedIncident.urgencyLevel),
                      }}
                    >
                      {getUrgencyBadge(selectedIncident.urgencyLevel).label}
                    </span>
                  </div>

                  <div style={{ fontSize: "0.85rem", color: "#64748B", display: "flex", gap: "1rem", flexWrap: "wrap" }}>
                    <span>NIK: <strong>{selectedIncident.patientNik}</strong></span>
                    <span>No HP: <strong>{selectedIncident.patientPhone || "-"}</strong></span>
                    <span>Waktu Aktivasi: <strong>{new Date(selectedIncident.createdAt).toLocaleTimeString("id-ID")} WIB</strong></span>
                    <span>ID: <code style={{ background: "#F1F5F9", padding: "0.1rem 0.35rem", borderRadius: "4px" }}>{selectedIncident.id}</code></span>
                  </div>
                </div>

                {/* Status Switcher & Responder Buttons */}
                <div style={{ display: "flex", gap: "0.6rem", flexWrap: "wrap" }}>
                  {selectedIncident.status === "ACTIVE" && (
                    <button
                      type="button"
                      onClick={handleAcknowledge}
                      disabled={actionLoading}
                      style={{
                        padding: "0.6rem 1.1rem",
                        borderRadius: "8px",
                        background: "#0D47A1",
                        color: "#FFFFFF",
                        border: "none",
                        fontWeight: 700,
                        fontSize: "0.875rem",
                        cursor: "pointer",
                        boxShadow: "0 2px 6px rgba(13,71,161,0.25)",
                        display: "flex",
                        alignItems: "center",
                        gap: "0.45rem",
                      }}
                    >
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                        <polyline points="22 4 12 14.01 9 11.01" />
                      </svg>
                      <span>Tangani Insiden (Acknowledge)</span>
                    </button>
                  )}

                  <button
                    type="button"
                    onClick={() => setNoteModalOpen(true)}
                    style={{
                      padding: "0.6rem 1rem",
                      borderRadius: "8px",
                      background: "#FFFFFF",
                      color: "#334155",
                      border: "1px solid #CBD5E1",
                      fontWeight: 600,
                      fontSize: "0.85rem",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      gap: "0.4rem",
                    }}
                  >
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                    </svg>
                    <span>Tambah Catatan</span>
                  </button>

                  {selectedIncident.status !== "RESOLVED" && (
                    <button
                      type="button"
                      onClick={() => setResolveModalOpen(true)}
                      style={{
                        padding: "0.6rem 1rem",
                        borderRadius: "8px",
                        background: "#ECFDF5",
                        color: "#065F46",
                        border: "1px solid #A7F3D0",
                        fontWeight: 700,
                        fontSize: "0.85rem",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        gap: "0.4rem",
                      }}
                    >
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                      <span>Tandai Selesai</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Responder Info Bar */}
              {selectedIncident.responderName && (
                <div
                  style={{
                    background: "#F8FAFC",
                    border: "1px solid #E2E8F0",
                    borderRadius: "8px",
                    padding: "0.65rem 0.9rem",
                    fontSize: "0.85rem",
                    color: "#334155",
                    display: "flex",
                    alignItems: "center",
                    gap: "0.5rem",
                  }}
                >
                  <span style={{ fontWeight: 700, color: "#0D47A1" }}>Petugas Medis Penanggung Jawab:</span>
                  <span>{selectedIncident.responderName}</span>
                  {selectedIncident.acknowledgedAt && (
                    <span style={{ color: "#94A3B8", marginLeft: "auto", fontSize: "0.78rem" }}>
                      Direspon pada {new Date(selectedIncident.acknowledgedAt).toLocaleTimeString("id-ID")} WIB
                    </span>
                  )}
                </div>
              )}
            </div>

            {/* AI Agent Triage & Strict Clinical Safety Rules Card */}
            <div
              style={{
                background: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #E2E8F0",
                padding: "1.5rem",
                boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "1rem" }}>
                <span
                  style={{
                    background: "#E3F2FD",
                    color: "#0D47A1",
                    padding: "0.3rem 0.6rem",
                    borderRadius: "6px",
                    fontSize: "0.8rem",
                    fontWeight: 800,
                  }}
                >
                  AGENTIC AI TRIAGE
                </span>
                <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                  Evaluasi Keselamatan Klinis &amp; Panduan Tindakan
                </h3>
              </div>

              {/* Critical Alert Warning Box (e.g. Aspiration Risk or Retinal Emergency) */}
              {selectedIncident.triageAssessment?.oralFoodAllowed === false && (
                <div
                  style={{
                    background: "#FEF2F2",
                    border: "2px solid #EF4444",
                    borderRadius: "10px",
                    padding: "1rem 1.25rem",
                    marginBottom: "1rem",
                    display: "flex",
                    alignItems: "flex-start",
                    gap: "0.85rem",
                  }}
                >
                  <div
                    style={{
                      background: "#EF4444",
                      color: "#FFFFFF",
                      borderRadius: "50%",
                      width: "30px",
                      height: "30px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontWeight: 800,
                      flexShrink: 0,
                    }}
                  >
                    !
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, color: "#991B1B", fontSize: "0.95rem", marginBottom: "0.2rem" }}>
                      PERINGATAN KRITIS: LARANGAN MUTLAK ASUPAN MAKAN / MINUM ORAL!
                    </div>
                    <div style={{ fontSize: "0.85rem", color: "#B91C1C", lineHeight: 1.5 }}>
                      Pasien mengalami penurunan kesadaran / gangguan menelan / kejang. Memberikan cairan atau makanan ke dalam mulut dapat menyebabkan <strong>aspirasi paru fatal</strong>. Segera panggil Ambulans 119 SPGDT dan posisikan miring mantap (Recovery Position).
                    </div>
                  </div>
                </div>
              )}

              {/* Triage Summary */}
              <div
                style={{
                  background: "#F8FAFC",
                  border: "1px solid #E2E8F0",
                  borderRadius: "8px",
                  padding: "1rem",
                  marginBottom: "1rem",
                }}
              >
                <div style={{ fontSize: "0.85rem", fontWeight: 700, color: "#334155", marginBottom: "0.25rem" }}>
                  Ringkasan Klinis:
                </div>
                <div style={{ fontSize: "0.9rem", color: "#0F172A", fontWeight: 600 }}>
                  {selectedIncident.triageAssessment?.clinicalRisk || selectedIncident.triageSummary}
                </div>
                <div style={{ fontSize: "0.85rem", color: "#475569", marginTop: "0.4rem" }}>
                  <strong>Instruksi Utama:</strong> {selectedIncident.recommendedAction}
                </div>
              </div>

              {/* Step by Step Safe Protocol */}
              {selectedIncident.triageAssessment?.safeProtocol && (
                <div>
                  <div style={{ fontSize: "0.85rem", fontWeight: 700, color: "#334155", marginBottom: "0.5rem" }}>
                    Protokol Keselamatan Terverifikasi:
                  </div>
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.4rem" }}>
                    {selectedIncident.triageAssessment.safeProtocol.map((step, idx) => (
                      <div
                        key={idx}
                        style={{
                          fontSize: "0.825rem",
                          color: "#334155",
                          background: "#F1F5F9",
                          padding: "0.5rem 0.75rem",
                          borderRadius: "6px",
                          lineHeight: 1.4,
                        }}
                      >
                        {step}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* GPS Telemetry & Interactive Map Card */}
            <div
              style={{
                background: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #E2E8F0",
                padding: "1.5rem",
                boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
                <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "0.45rem" }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0D47A1" strokeWidth="2.5">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                    <circle cx="12" cy="10" r="3" />
                  </svg>
                  <span>Telemetri Lokasi GPS Pasien</span>
                </h3>

                {selectedIncident.latitude && selectedIncident.longitude && (
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${selectedIncident.latitude},${selectedIncident.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      fontSize: "0.825rem",
                      fontWeight: 700,
                      color: "#0D47A1",
                      textDecoration: "none",
                      display: "flex",
                      alignItems: "center",
                      gap: "0.35rem",
                    }}
                  >
                    <span>Buka di Google Maps</span>
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                      <polyline points="15 3 21 3 21 9" />
                      <line x1="10" y1="14" x2="21" y2="3" />
                    </svg>
                  </a>
                )}
              </div>

              {selectedIncident.latitude && selectedIncident.longitude ? (
                <div>
                  {/* Interactive Visual Map Preview */}
                  <div
                    style={{
                      height: "240px",
                      borderRadius: "10px",
                      overflow: "hidden",
                      border: "1px solid #CBD5E1",
                      position: "relative",
                      background: "#E2E8F0",
                      marginBottom: "1rem",
                    }}
                  >
                    <iframe
                      width="100%"
                      height="100%"
                      style={{ border: 0 }}
                      src={`https://www.openstreetmap.org/export/embed.html?bbox=${selectedIncident.longitude - 0.008}%2C${selectedIncident.latitude - 0.008}%2C${selectedIncident.longitude + 0.008}%2C${selectedIncident.latitude + 0.008}&layer=mapnik&marker=${selectedIncident.latitude}%2C${selectedIncident.longitude}`}
                    />
                  </div>

                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "0.75rem", fontSize: "0.85rem" }}>
                    <div style={{ background: "#F8FAFC", padding: "0.6rem 0.85rem", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
                      <span style={{ color: "#64748B", display: "block", fontSize: "0.75rem" }}>Koordinat:</span>
                      <strong>{selectedIncident.latitude.toFixed(6)}, {selectedIncident.longitude.toFixed(6)}</strong>
                    </div>

                    <div style={{ background: "#F8FAFC", padding: "0.6rem 0.85rem", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
                      <span style={{ color: "#64748B", display: "block", fontSize: "0.75rem" }}>Radius Akurasi GPS:</span>
                      <strong style={{ color: "#059669" }}>±{selectedIncident.accuracyMeters || 10} meter</strong>
                    </div>

                    <div style={{ background: "#F8FAFC", padding: "0.6rem 0.85rem", borderRadius: "8px", border: "1px solid #E2E8F0", gridColumn: "1 / -1" }}>
                      <span style={{ color: "#64748B", display: "block", fontSize: "0.75rem" }}>Alamat Perkiraan:</span>
                      <strong>{selectedIncident.locationAddress || "Wilayah D.I. Yogyakarta"}</strong>
                    </div>
                  </div>
                </div>
              ) : (
                <div
                  style={{
                    padding: "2rem",
                    textAlign: "center",
                    background: "#FFFBEB",
                    borderRadius: "10px",
                    border: "1px solid #FDE68A",
                  }}
                >
                  <div style={{ fontWeight: 700, color: "#92400E", marginBottom: "0.3rem" }}>
                    Status Lokasi: Menunggu Koordinat GPS Pasien ({selectedIncident.locationStatus})
                  </div>
                  <div style={{ fontSize: "0.825rem", color: "#B45309" }}>
                    Gunakan nomor telepon pasien ({selectedIncident.patientPhone || "tersedia di rekam medis"}) untuk konfirmasi lokasi manual via telepon darurat.
                  </div>
                </div>
              )}
            </div>

            {/* Notification Dispatch Status & Emergency Contacts Card */}
            <div
              style={{
                background: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #E2E8F0",
                padding: "1.5rem",
                boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
              }}
            >
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: "0 0 1rem 0" }}>
                Status Notifikasi &amp; Kontak Darurat
              </h3>

              <div style={{ display: "flex", flexDirection: "column", gap: "0.65rem" }}>
                {selectedIncident.notifications && selectedIncident.notifications.length > 0 ? (
                  selectedIncident.notifications.map((notif) => (
                    <div
                      key={notif.id}
                      style={{
                        padding: "0.85rem 1rem",
                        borderRadius: "8px",
                        background: "#F8FAFC",
                        border: "1px solid #E2E8F0",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        flexWrap: "wrap",
                        gap: "0.5rem",
                      }}
                    >
                      <div>
                        <div style={{ fontWeight: 700, fontSize: "0.9rem", color: "#0F172A" }}>
                          {notif.recipientName}
                        </div>
                        <div style={{ fontSize: "0.78rem", color: "#64748B" }}>
                          Kanal: <strong>{notif.channel}</strong> ({notif.recipientPhone}) • {notif.recipientType}
                        </div>
                      </div>

                      <div style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
                        <span
                          style={{
                            fontSize: "0.75rem",
                            fontWeight: 700,
                            padding: "0.2rem 0.55rem",
                            borderRadius: "9999px",
                            background: notif.status === "DELIVERED" ? "#ECFDF5" : "#FFFBEB",
                            color: notif.status === "DELIVERED" ? "#065F46" : "#92400E",
                            border: `1px solid ${notif.status === "DELIVERED" ? "#A7F3D0" : "#FDE68A"}`,
                          }}
                        >
                          {notif.status === "DELIVERED" ? "Terkirim & Terkonfirmasi" : notif.status}
                        </span>

                        <a
                          href={`tel:${notif.recipientPhone}`}
                          style={{
                            padding: "0.35rem 0.65rem",
                            borderRadius: "6px",
                            background: "#0D47A1",
                            color: "#FFFFFF",
                            fontSize: "0.75rem",
                            fontWeight: 600,
                            textDecoration: "none",
                          }}
                        >
                          Panggil
                        </a>
                      </div>
                    </div>
                  ))
                ) : (
                  <div style={{ fontSize: "0.85rem", color: "#94A3B8" }}>Belum ada rekaman notifikasi.</div>
                )}
              </div>
            </div>

            {/* Event Timeline & Audit Log */}
            <div
              style={{
                background: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #E2E8F0",
                padding: "1.5rem",
                boxShadow: "0 2px 10px rgba(0,0,0,0.03)",
              }}
            >
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: "0 0 1rem 0" }}>
                Kronologi Kejadian (Audit Trail)
              </h3>

              <div style={{ position: "relative", paddingLeft: "1.5rem" }}>
                <div
                  style={{
                    position: "absolute",
                    left: "6px",
                    top: "8px",
                    bottom: "8px",
                    width: "2px",
                    background: "#E2E8F0",
                  }}
                />

                {selectedIncident.events && selectedIncident.events.length > 0 ? (
                  selectedIncident.events.map((evt, idx) => (
                    <div key={idx} style={{ position: "relative", marginBottom: "1rem" }}>
                      <span
                        style={{
                          position: "absolute",
                          left: "-1.5rem",
                          top: "4px",
                          width: "12px",
                          height: "12px",
                          borderRadius: "50%",
                          background: idx === 0 ? "#EF4444" : "#2196F3",
                          border: "2px solid #FFFFFF",
                          boxShadow: "0 0 4px rgba(0,0,0,0.2)",
                        }}
                      />
                      <div style={{ fontSize: "0.75rem", color: "#94A3B8", fontWeight: 600 }}>
                        {new Date(evt.createdAt).toLocaleTimeString("id-ID")} WIB • {evt.actorName || evt.actorType}
                      </div>
                      <div style={{ fontWeight: 700, fontSize: "0.875rem", color: "#0F172A" }}>
                        {evt.eventTitle}
                      </div>
                      {evt.eventDescription && (
                        <div style={{ fontSize: "0.8rem", color: "#475569", marginTop: "0.15rem" }}>
                          {evt.eventDescription}
                        </div>
                      )}
                    </div>
                  ))
                ) : (
                  <div style={{ fontSize: "0.85rem", color: "#94A3B8" }}>Tidak ada riwayat kejadian.</div>
                )}
              </div>
            </div>
          </div>
        ) : (
          <div
            style={{
              background: "#FFFFFF",
              borderRadius: "12px",
              border: "1px solid #E2E8F0",
              padding: "4rem 2rem",
              textAlign: "center",
              color: "#94A3B8",
            }}
          >
            <div style={{ fontWeight: 600, fontSize: "1.1rem", color: "#64748B" }}>
              Pilih panggilan darurat di sebelah kiri
            </div>
            <div style={{ fontSize: "0.85rem", marginTop: "0.3rem" }}>
              Detail klinis, panduan triase, dan peta koordinat akan ditampilkan di sini.
            </div>
          </div>
        )}
      </div>

      {/* Modal: Tambah Catatan Medis */}
      {noteModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(15,23,42,0.6)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
            padding: "1rem",
          }}
        >
          <div
            style={{
              background: "#FFFFFF",
              borderRadius: "14px",
              padding: "1.75rem",
              maxWidth: "520px",
              width: "100%",
              boxShadow: "0 20px 25px -5px rgba(0,0,0,0.1)",
            }}
          >
            <h3 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#0F172A", margin: "0 0 0.5rem 0" }}>
              Tambah Catatan Tindak Lanjut Medis
            </h3>
            <p style={{ fontSize: "0.85rem", color: "#64748B", margin: "0 0 1.25rem 0" }}>
              Catatan ini akan tersimpan permanen dalam audit trail pasien dan dapat diakses oleh tim medis FKTP / RS rujukan.
            </p>

            <div style={{ marginBottom: "1rem" }}>
              <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 700, color: "#334155", marginBottom: "0.35rem" }}>
                Tindakan yang Diambil:
              </label>
              <input
                type="text"
                placeholder="cth: Menghubungi keluarga / Koordinasi IGD RS Mata YAP"
                value={actionTakenText}
                onChange={(e) => setActionTakenText(e.target.value)}
                style={{
                  width: "100%",
                  padding: "0.6rem 0.85rem",
                  borderRadius: "8px",
                  border: "1px solid #CBD5E1",
                  fontSize: "0.875rem",
                }}
              />
            </div>

            <div style={{ marginBottom: "1.5rem" }}>
              <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 700, color: "#334155", marginBottom: "0.35rem" }}>
                Catatan Observasi / Instruksi:
              </label>
              <textarea
                rows={4}
                placeholder="Tuliskan perkembangan kondisi pasien, respon terhadap pertolongan pertama, atau instruksi lanjutan..."
                value={noteText}
                onChange={(e) => setNoteText(e.target.value)}
                style={{
                  width: "100%",
                  padding: "0.6rem 0.85rem",
                  borderRadius: "8px",
                  border: "1px solid #CBD5E1",
                  fontSize: "0.875rem",
                  fontFamily: "inherit",
                }}
              />
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
              <button
                type="button"
                onClick={() => setNoteModalOpen(false)}
                style={{
                  padding: "0.6rem 1rem",
                  borderRadius: "8px",
                  background: "#F1F5F9",
                  border: "none",
                  fontWeight: 600,
                  fontSize: "0.85rem",
                  color: "#475569",
                  cursor: "pointer",
                }}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleSaveNote}
                disabled={actionLoading || !noteText.trim()}
                style={{
                  padding: "0.6rem 1.25rem",
                  borderRadius: "8px",
                  background: "#0D47A1",
                  border: "none",
                  fontWeight: 700,
                  fontSize: "0.85rem",
                  color: "#FFFFFF",
                  cursor: "pointer",
                }}
              >
                Simpan Catatan
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Tandai Selesai (Resolve Incident) */}
      {resolveModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(15,23,42,0.6)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
            padding: "1rem",
          }}
        >
          <div
            style={{
              background: "#FFFFFF",
              borderRadius: "14px",
              padding: "1.75rem",
              maxWidth: "520px",
              width: "100%",
              boxShadow: "0 20px 25px -5px rgba(0,0,0,0.1)",
            }}
          >
            <h3 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#065F46", margin: "0 0 0.5rem 0" }}>
              Tandai Insiden Darurat Selesai (Resolve)
            </h3>
            <p style={{ fontSize: "0.85rem", color: "#64748B", margin: "0 0 1.25rem 0" }}>
              Pastikan pasien telah berada dalam kondisi aman, didampingi keluarga, atau telah diterima di instalasi gawat darurat.
            </p>

            <div style={{ marginBottom: "1.5rem" }}>
              <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 700, color: "#334155", marginBottom: "0.35rem" }}>
                Catatan Penyelesaian (Outcome Notes):
              </label>
              <textarea
                rows={4}
                placeholder="cth: Pasien telah sadar penuh setelah protokol Rule 15-15, gula darah naik ke 95 mg/dL. Didampingi istri di rumah."
                value={resolutionNotes}
                onChange={(e) => setResolutionNotes(e.target.value)}
                style={{
                  width: "100%",
                  padding: "0.6rem 0.85rem",
                  borderRadius: "8px",
                  border: "1px solid #CBD5E1",
                  fontSize: "0.875rem",
                  fontFamily: "inherit",
                }}
              />
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
              <button
                type="button"
                onClick={() => setResolveModalOpen(false)}
                style={{
                  padding: "0.6rem 1rem",
                  borderRadius: "8px",
                  background: "#F1F5F9",
                  border: "none",
                  fontWeight: 600,
                  fontSize: "0.85rem",
                  color: "#475569",
                  cursor: "pointer",
                }}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleResolve}
                disabled={actionLoading}
                style={{
                  padding: "0.6rem 1.25rem",
                  borderRadius: "8px",
                  background: "#10B981",
                  border: "none",
                  fontWeight: 700,
                  fontSize: "0.85rem",
                  color: "#FFFFFF",
                  cursor: "pointer",
                }}
              >
                Konfirmasi Selesai
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
