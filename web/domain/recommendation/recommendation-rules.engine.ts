import { DRClassification } from "../screening/ai-result.entity";
import { Recommendation, RecommendedAction, UrgencyLevel } from "./recommendation.entity";
import { DiabetesProfile } from "../patient/diabetes-profile.entity";

export interface EvaluationInput {
  screeningId: string;
  confirmedClass: DRClassification;
  diabetesProfile?: DiabetesProfile | null;
}

export class RecommendationRulesEngine {
  /**
   * Deterministic clinical decision rule engine based on PERDAMI & ADA Guidelines.
   * STRICT RULE: Recommendation engine is separate from AI model; no LLM black-box clinical decision.
   */
  public static evaluate(input: EvaluationInput): Recommendation {
    const { screeningId, confirmedClass, diabetesProfile } = input;
    const isPoorGlycaemicControl =
      diabetesProfile && diabetesProfile.getGlycaemicControlStatus() === "POOR";

    let summary: string;
    let action: RecommendedAction;
    let urgency: UrgencyLevel;
    let referralIndicated: boolean;

    switch (confirmedClass) {
      case "NO_DR":
        if (isPoorGlycaemicControl) {
          summary =
            "Tidak ditemukan tanda retinopati diabetik pada citra fundus saat ini. Namun, kendali glikemik pasien berada pada tingkat suboptimal/buruk. Dianjurkan kontrol metabolik ketat dan skrining ulang dalam 6-12 bulan.";
          action = "FOLLOW_UP_6_MONTHS";
          urgency = "LOW";
          referralIndicated = false;
        } else {
          summary =
            "Tidak ditemukan tanda retinopati diabetik yang bermakna pada kedua mata. Pasien disarankan melanjutkan kontrol gula darah rutin dan menjalani skrining retina berkala tahunan.";
          action = "ROUTINE_ANNUAL_SCREENING";
          urgency = "LOW";
          referralIndicated = false;
        }
        break;

      case "MILD_DR":
        summary =
          "Ditemukan tanda awal retinopati diabetik non-proliferatif derajat ringan (mikroaneurisma minimal). Diperlukan optimalisasi kendali glikemik dan tekanan darah, serta pemeriksaan retina berkala dalam 6 bulan untuk memantau progresi.";
        action = "FOLLOW_UP_6_MONTHS";
        urgency = "MEDIUM";
        referralIndicated = false;
        break;

      case "MODERATE_DR":
        summary =
          "Ditemukan tanda retinopati diabetik non-proliferatif derajat sedang (mikroaneurisma multipel, perdarahan bercak/dot-blot, eksudat keras). Disarankan rujukan terencana ke dokter spesialis mata untuk pemeriksaan biomikroskopi fundus dan evaluasi makulopati diabetik.";
        action = "SPECIALIST_OPHTHALMOLOGY_REFERRAL";
        urgency = "MEDIUM";
        referralIndicated = true;
        break;

      case "SEVERE_DR":
        summary =
          "Ditemukan tanda retinopati diabetik non-proliferatif derajat berat (perdarahan intraretina luas, beading vena, atau IRMA). Risiko tinggi progresi ke tahap proliferatif. Direkomendasikan rujukan segera ke dokter spesialis mata untuk evaluasi terapi fotokoagulasi laser atau anti-VEGF.";
        action = "SPECIALIST_OPHTHALMOLOGY_REFERRAL";
        urgency = "HIGH";
        referralIndicated = true;
        break;

      case "PROLIFERATIVE_DR":
        summary =
          "Ditemukan tanda retinopati diabetik proliferatif (neovaskularisasi diskus/retina atau perdarahan preretina/vitreus). Memerlukan konsultasi dan tindakan subspesialis vitreoretina segera untuk mencegah penurunan penglihatan permanen atau ablasio retina.";
        action = "URGENT_SURGICAL_CONSULTATION";
        urgency = "CRITICAL";
        referralIndicated = true;
        break;

      default:
        summary = "Pemeriksaan mata berkala sesuai anjuran tenaga kesehatan fasilitas primer.";
        action = "ROUTINE_ANNUAL_SCREENING";
        urgency = "LOW";
        referralIndicated = false;
    }

    return Recommendation.create({
      screeningId,
      summary,
      recommendedAction: action,
      urgencyLevel: urgency,
      referralIndicated,
      clinicalGuideline: "Pedoman Pengelolaan Retinopati Diabetika Perdami 2024 / ADA 2024 Standards of Care",
    });
  }
}
