import { AIClient, AIScreeningResponse, QualityCheckResult } from "@/domain/screening/ai-client.interface";

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
    return {
      modelName: data.model_name,
      modelVersion: data.model_version,
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
            predictedClass: data.prediction.predicted_class,
            classIndex: data.prediction.class_index,
            confidence: data.prediction.confidence,
            rawProbabilities: data.prediction.raw_probabilities,
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
