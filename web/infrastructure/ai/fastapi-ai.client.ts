import { AIClient, AIScreeningResponse, QualityCheckResult } from "@/domain/screening/ai-client.interface";

function normalizeDRClass(raw?: string): any {
  if (!raw) return "NO_DR";
  const upper = raw.toUpperCase().trim().replace(/[\s-]+/g, "_");
  if (upper === "NO_DR" || upper === "NO" || upper === "NORMAL") return "NO_DR";
  if (upper === "MILD" || upper === "MILD_DR" || upper === "MILD_NPDR") return "MILD_DR";
  if (upper === "MODERATE" || upper === "MODERATE_DR" || upper === "MODERATE_NPDR") return "MODERATE_DR";
  if (upper === "SEVERE" || upper === "SEVERE_DR" || upper === "SEVERE_NPDR") return "SEVERE_DR";
  if (upper === "PROLIFERATIVE_DR" || upper === "PROLIFERATIVE" || upper === "PDR") return "PROLIFERATIVE_DR";
  return upper;
}

function normalizeProbabilities(raw?: Record<string, number>): Record<string, number> {
  if (!raw) {
    return {
      NO_DR: 0.05,
      MILD_DR: 0.1,
      MODERATE_DR: 0.8,
      SEVERE_DR: 0.04,
      PROLIFERATIVE_DR: 0.01,
    };
  }
  const normalized: Record<string, number> = {};
  for (const [key, val] of Object.entries(raw)) {
    normalized[normalizeDRClass(key)] = Number(val);
  }
  return normalized;
}

export class FastAPIAIClient implements AIClient {
  private readonly baseUrl: string;
  private readonly secretToken: string;

  constructor() {
    this.baseUrl = process.env.AI_SERVICE_URL || "http://localhost:8003";
    this.secretToken = process.env.AI_INTERNAL_SECRET || "retiva-internal-secret-token";
  }

  async checkQuality(imageUrlOrKey: string, eye: "OD" | "OS" = "OD"): Promise<QualityCheckResult> {
    const res = await fetch(`${this.baseUrl}/api/v1/quality-check`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Internal-Secret": this.secretToken,
      },
      body: JSON.stringify({
        image_url: imageUrlOrKey,
        eye,
      }),
    });

    if (!res.ok) {
      throw new Error(`AI Quality Check service error: ${res.statusText}`);
    }

    const data = await res.json();
    return {
      passed: data.passed,
      overallScore: data.overall_score,
      blurScore: data.blur_score,
      illuminationScore: data.illumination_score,
      fovScore: data.fov_score,
      retakeReason: data.retake_reason,
      retakeInstructions: data.retake_instructions,
    };
  }

  async screen(
    imageUrlOrKey: string,
    eye: "OD" | "OS" = "OD",
    bypassQualityCheck = false
  ): Promise<AIScreeningResponse> {
    const res = await fetch(`${this.baseUrl}/api/v1/screen`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Internal-Secret": this.secretToken,
      },
      body: JSON.stringify({
        image_url: imageUrlOrKey,
        eye,
        bypass_quality_check: bypassQualityCheck,
      }),
    });

    if (!res.ok) {
      throw new Error(`AI Screening service error: ${res.statusText}`);
    }

    const data = await res.json();
    const rawPredictedClass = data.prediction?.predicted_class || data.prediction?.class;
    const predictedClass = normalizeDRClass(rawPredictedClass);
    const rawProbabilities = normalizeProbabilities(
      data.prediction?.raw_probabilities || data.prediction?.probabilities
    );

    return {
      modelName: data.model_name || data.model?.name,
      modelVersion: data.model_version || data.model?.version,
      pipelineVersion: data.pipeline_version,
      quality: {
        passed: data.quality.passed,
        overallScore: data.quality.overall_score,
        blurScore: data.quality.blur_score,
        illuminationScore: data.quality.illumination_score,
        fovScore: data.quality.fov_score,
        retakeReason: data.quality.retake_reason,
        retakeInstructions: data.quality.retake_instructions,
      },
      prediction: data.prediction
        ? {
            predictedClass,
            classIndex: data.prediction.class_index,
            confidence: data.prediction.confidence,
            rawProbabilities,
          }
        : undefined,
      reliability: data.reliability
        ? {
            status: data.reliability.status,
            score: data.reliability.score,
            confidenceThreshold: data.reliability.confidence_threshold,
            qualityThreshold: data.reliability.quality_threshold,
            reason: data.reliability.reason,
          }
        : undefined,
    };
  }

  async getExplainability(screeningId: string): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/v1/explainability?screening_id=${screeningId}`, {
      method: "POST",
      headers: {
        "X-Internal-Secret": this.secretToken,
      },
    });

    if (!res.ok) {
      throw new Error(`AI Explainability service error: ${res.statusText}`);
    }

    return res.json();
  }
}
