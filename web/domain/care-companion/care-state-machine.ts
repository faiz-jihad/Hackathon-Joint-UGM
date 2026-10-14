/**
 * Care State Machine for RETIVA Care Companion
 * Governs the patient's journey across Screening -> Pre-consultation -> Consultation Entry -> Post-consultation Care Planning
 */

export type CareState =
  | "SCREENING_COMPLETED"
  | "AWAITING_CONSULTATION"
  | "CONSULTATION_RECORDED"
  | "CARE_PLAN_READY"
  | "CARE_PLAN_ACTIVE"
  | "FOLLOW_UP_DUE"
  | "CARE_PLAN_UPDATED";

export interface CareStateContext {
  hasCompletedScreening: boolean;
  hasRecordedConsultation: boolean;
  isConsultationConfirmed: boolean;
  hasActiveCarePlan: boolean;
  followUpDate?: Date | null;
}

export class CareStateMachine {
  /**
   * Evaluates the current state given patient context.
   */
  public static resolveState(context: CareStateContext, currentState?: CareState): CareState {
    if (!context.hasCompletedScreening) {
      return "SCREENING_COMPLETED";
    }

    // Follow-up due check (if consultation confirmed and follow-up date has passed or within 3 days)
    if (context.isConsultationConfirmed && context.followUpDate) {
      const now = new Date();
      const dueDate = new Date(context.followUpDate);
      const diffDays = Math.ceil((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      if (diffDays <= 3) {
        return "FOLLOW_UP_DUE";
      }
    }

    if (context.hasActiveCarePlan) {
      return currentState === "CARE_PLAN_UPDATED" ? "CARE_PLAN_UPDATED" : "CARE_PLAN_ACTIVE";
    }

    if (context.isConsultationConfirmed) {
      return "CARE_PLAN_READY";
    }

    if (context.hasRecordedConsultation) {
      return "CONSULTATION_RECORDED";
    }

    return "AWAITING_CONSULTATION";
  }

  /**
   * Validates if a transition from current state to target state is permissible.
   */
  public static canTransition(from: CareState, to: CareState, context: CareStateContext): { allowed: boolean; reason?: string } {
    // Cannot start personalized post-consultation care planning without confirmed consultation
    if ((to === "CARE_PLAN_READY" || to === "CARE_PLAN_ACTIVE") && !context.isConsultationConfirmed) {
      return {
        allowed: false,
        reason: "Rencana perawatan pasca-konsultasi membutuhkan konfirmasi ringkasan konsultasi dokter terlebih dahulu.",
      };
    }

    switch (from) {
      case "SCREENING_COMPLETED":
        if (to === "AWAITING_CONSULTATION" || to === "CONSULTATION_RECORDED") return { allowed: true };
        break;
      case "AWAITING_CONSULTATION":
        if (to === "CONSULTATION_RECORDED") return { allowed: true };
        break;
      case "CONSULTATION_RECORDED":
        if (to === "CARE_PLAN_READY" || to === "AWAITING_CONSULTATION") return { allowed: true };
        break;
      case "CARE_PLAN_READY":
        if (to === "CARE_PLAN_ACTIVE" || to === "CARE_PLAN_UPDATED") return { allowed: true };
        break;
      case "CARE_PLAN_ACTIVE":
        if (to === "FOLLOW_UP_DUE" || to === "CARE_PLAN_UPDATED") return { allowed: true };
        break;
      case "FOLLOW_UP_DUE":
        if (to === "CONSULTATION_RECORDED" || to === "CARE_PLAN_UPDATED") return { allowed: true };
        break;
      case "CARE_PLAN_UPDATED":
        if (to === "CARE_PLAN_ACTIVE" || to === "FOLLOW_UP_DUE") return { allowed: true };
        break;
    }

    return { allowed: false, reason: `Transisi status tidak valid dari ${from} ke ${to}.` };
  }

  /**
   * User-friendly Indonesian labels and descriptions for each state.
   */
  public static getStateMetadata(state: CareState): { title: string; subtitle: string; phase: "PHASE_A" | "PHASE_B" | "PHASE_C" | "PHASE_D" } {
    switch (state) {
      case "SCREENING_COMPLETED":
        return {
          title: "Skrining Retina Selesai",
          subtitle: "Hasil analisis AI tersedia. Pahami hasil dan rencanakan konsultasi medis.",
          phase: "PHASE_A",
        };
      case "AWAITING_CONSULTATION":
        return {
          title: "Menunggu Jadwal Konsultasi",
          subtitle: "Cari faskes mata terdekat, siapkan pertanyaan dokter, dan pelajari edukasi gizi umum.",
          phase: "PHASE_B",
        };
      case "CONSULTATION_RECORDED":
        return {
          title: "Hasil Konsultasi Dicatat",
          subtitle: "Periksa kembali catatan instruksi dokter sebelum mengaktifkan rencana perawatan.",
          phase: "PHASE_C",
        };
      case "CARE_PLAN_READY":
        return {
          title: "Rencana Perawatan Siap",
          subtitle: "AI telah menyusun rekomendasi nutrisi terjangkau dan jadwal pengingat sesuai anjuran dokter.",
          phase: "PHASE_D",
        };
      case "CARE_PLAN_ACTIVE":
        return {
          title: "Rencana Perawatan Aktif",
          subtitle: "Ikuti panduan menu harian, kepatuhan obat, dan pantau progres kesehatan Anda.",
          phase: "PHASE_D",
        };
      case "FOLLOW_UP_DUE":
        return {
          title: "Waktunya Kontrol Ulang Dokter",
          subtitle: "Jadwal kontrol mata Anda telah tiba. Segera jadwalkan kunjungan ke faskes rujukan.",
          phase: "PHASE_D",
        };
      case "CARE_PLAN_UPDATED":
        return {
          title: "Rencana Perawatan Diperbarui",
          subtitle: "Penyesuaian menu atau pengingat berhasil disimpan.",
          phase: "PHASE_D",
        };
    }
  }
}
