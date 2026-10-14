/**
 * Urgent Symptom Checker (Safety Mechanism for Red-Flag Eye Symptoms)
 * Evaluates patient-reported symptoms for critical conditions like retinal detachment,
 * vitreous hemorrhage, acute angle-closure glaucoma, or severe ocular emergencies.
 */

export interface SymptomEvaluationResult {
  isEmergency: boolean;
  severity: "NORMAL" | "WARNING" | "CRITICAL_EMERGENCY";
  matchedTriggers: string[];
  warningTitle: string;
  warningMessage: string;
  recommendedAction: string;
  canProceedWithRoutineCare: boolean;
}

export class UrgentSymptomChecker {
  // Indonesian clinical red-flag triggers based on PERDAMI / Ophthalmology emergency guidelines
  private static readonly CRITICAL_TRIGGERS: { pattern: RegExp; description: string }[] = [
    {
      pattern: /(buram|gelap|kabur|hilang penglihatan|buta)\s*(mendadak|tiba-tiba|seketika|cepat)/i,
      description: "Penurunan penglihatan drastis atau mendadak",
    },
    {
      pattern: /(kilatan|kilat|seperti petir|kelap[- ]kelip|flashes)\s*(cahaya|mata)?/i,
      description: "Sensasi kilatan cahaya (fotopsia) yang dapat menandakan traksi retina",
    },
    {
      pattern: /(bintik|titik|jaring laba[- ]laba|floaters|bercak).*?(mendadak|banyak|bertambah banyak|tiba-tiba)/i,
      description: "Kemunculan mendadak atau penambahan signifikan bintik melayang (floaters)",
    },
    {
      pattern: /(tirai|bayangan tirai|gelap separuh|seperti tertutup tirai|curtain)/i,
      description: "Penglihatan seperti tertutup tirai atau bayangan gelap meluas (tanda ablasio retina)",
    },
    {
      pattern: /(nyeri|sakit)\s*(mata)?\s*(hebat|sangat sakit|disertai mual|muntah|pusing kepala hebat)/i,
      description: "Nyeri mata akut berat disertai gejala sistemik",
    },
  ];

  /**
   * Evaluates symptoms text or structured symptom options.
   */
  public static evaluate(symptomText?: string, specificFlags?: {
    suddenVisionDrop?: boolean;
    flashesOfLight?: boolean;
    suddenFloaters?: boolean;
    curtainShadow?: boolean;
    severeEyePain?: boolean;
  }): SymptomEvaluationResult {
    const matchedTriggers: string[] = [];

    if (specificFlags) {
      if (specificFlags.suddenVisionDrop) matchedTriggers.push("Penurunan tajam penglihatan mendadak");
      if (specificFlags.flashesOfLight) matchedTriggers.push("Melihat kilatan cahaya (fotopsia)");
      if (specificFlags.suddenFloaters) matchedTriggers.push("Bintik hitam/floaters muncul mendadak");
      if (specificFlags.curtainShadow) matchedTriggers.push("Penglihatan tertutup tirai/bayangan");
      if (specificFlags.severeEyePain) matchedTriggers.push("Nyeri mata hebat");
    }

    if (symptomText && symptomText.trim().length > 0) {
      for (const trigger of this.CRITICAL_TRIGGERS) {
        if (trigger.pattern.test(symptomText)) {
          if (!matchedTriggers.includes(trigger.description)) {
            matchedTriggers.push(trigger.description);
          }
        }
      }
    }

    if (matchedTriggers.length > 0) {
      return {
        isEmergency: true,
        severity: "CRITICAL_EMERGENCY",
        matchedTriggers,
        warningTitle: "PERINGATAN MEDIS DARURAT: SEGERA PERIKSA KE DOKTER SPESIALIS MATA",
        warningMessage:
          "Gejala yang Anda laporkan berpotensi menandakan kegawatdaruratan mata (seperti robekan/ablasio retina atau perdarahan vitreus). Bimbingan gizi dan rutinitas harian ditunda sementara. Segera datangi Instalasi Gawat Darurat (IGD) rumah sakit atau RS Mata terdekat dalam 24 jam untuk mencegah kehilangan penglihatan permanen.",
        recommendedAction: "SEGERA_KE_IGD_RS_MATA",
        canProceedWithRoutineCare: false,
      };
    }

    return {
      isEmergency: false,
      severity: "NORMAL",
      matchedTriggers: [],
      warningTitle: "Tidak Terdeteksi Gejala Darurat",
      warningMessage: "Tidak terdeteksi gejala gawat darurat mata. Tetap ikuti anjuran dokter dan kontrol berkala.",
      recommendedAction: "LANJUTKAN_PERAWATAN_RUTIN",
      canProceedWithRoutineCare: true,
    };
  }
}
