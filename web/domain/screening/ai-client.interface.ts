export interface QualityCheckResult {
  passed: boolean;
  overallScore: number;
  blurScore?: number;
  illuminationScore?: number;
  fovScore?: number;
  retakeReason?: string;
  retakeInstructions?: string;
}

export interface PredictionResult {
  predictedClass: "NO_DR" | "MILD_DR" | "MODERATE_DR" | "SEVERE_DR" | "PROLIFERATIVE_DR";
  classIndex: number;
  confidence: number;
  rawProbabilities: Record<string, number>;
}

export interface ReliabilityResult {
  status: "analyze" | "human_review" | "retake";
  score: number;
  confidenceThreshold: number;
  qualityThreshold: number;
  reason?: string;
}

export interface AIScreeningResponse {
  modelName: string;
  modelVersion: string;
  pipelineVersion: string;
  quality: QualityCheckResult;
  prediction?: PredictionResult;
  reliability?: ReliabilityResult;
}

export interface AIClient {
  checkQuality(imageUrlOrKey: string, eye?: "OD" | "OS"): Promise<QualityCheckResult>;
  screen(imageUrlOrKey: string, eye?: "OD" | "OS", bypassQualityCheck?: boolean): Promise<AIScreeningResponse>;
  getExplainability(screeningId: string): Promise<any>;
}
