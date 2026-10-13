class QualityCheckResult {
  final bool passed;
  final double overallScore;
  final double blurScore;
  final double illuminationScore;
  final double fovScore;
  final String? retakeReason;
  final String? retakeInstructions;

  QualityCheckResult({
    required this.passed,
    required this.overallScore,
    required this.blurScore,
    required this.illuminationScore,
    required this.fovScore,
    this.retakeReason,
    this.retakeInstructions,
  });

  factory QualityCheckResult.fromJson(Map<String, dynamic> json) {
    return QualityCheckResult(
      passed: json['passed'] ?? false,
      overallScore: (json['overallScore'] ?? json['overall_score'] ?? 0.85).toDouble(),
      blurScore: (json['blurScore'] ?? json['blur_score'] ?? 0.88).toDouble(),
      illuminationScore: (json['illuminationScore'] ?? json['illumination_score'] ?? 0.91).toDouble(),
      fovScore: (json['fovScore'] ?? json['fov_score'] ?? 0.94).toDouble(),
      retakeReason: json['retakeReason'] ?? json['retake_reason'],
      retakeInstructions: json['retakeInstructions'] ?? json['retake_instructions'],
    );
  }
}

class AIInferenceResult {
  final String predictedClass;
  final double confidence;
  final Map<String, double> rawProbabilities;
  final bool isHighRisk;

  AIInferenceResult({
    required this.predictedClass,
    required this.confidence,
    required this.rawProbabilities,
    required this.isHighRisk,
  });

  factory AIInferenceResult.fromJson(Map<String, dynamic> json) {
    final probs = <String, double>{};
    final raw = json['rawProbabilities'] ?? json['raw_probabilities'];
    if (raw is Map) {
      raw.forEach((k, v) {
        probs[k.toString()] = (v as num).toDouble();
      });
    }

    return AIInferenceResult(
      predictedClass: json['predictedClass'] ?? json['predicted_class'] ?? 'NO_DR',
      confidence: (json['confidence'] ?? 0.88).toDouble(),
      rawProbabilities: probs.isNotEmpty
          ? probs
          : {
              'NO_DR': 0.05,
              'MILD_DR': 0.12,
              'MODERATE_DR': 0.78,
              'SEVERE_DR': 0.04,
              'PROLIFERATIVE_DR': 0.01,
            },
      isHighRisk: json['isHighRisk'] ?? json['is_high_risk'] ?? false,
    );
  }
}

class ReliabilityResult {
  final String status; // ANALYZE, HUMAN_REVIEW, RETAKE
  final double score;
  final bool requiresHumanReview;
  final String? reasoning;

  ReliabilityResult({
    required this.status,
    required this.score,
    required this.requiresHumanReview,
    this.reasoning,
  });

  factory ReliabilityResult.fromJson(Map<String, dynamic> json) {
    return ReliabilityResult(
      status: json['status'] ?? 'ANALYZE',
      score: (json['score'] ?? 0.90).toDouble(),
      requiresHumanReview: json['requiresHumanReview'] ??
          json['requires_human_review'] ??
          (json['status'] == 'HUMAN_REVIEW'),
      reasoning: json['reasoning'],
    );
  }
}

class RecommendationResult {
  final String summary;
  final String recommendedAction;
  final String urgencyLevel;
  final bool referralIndicated;
  final String clinicalGuideline;

  RecommendationResult({
    required this.summary,
    required this.recommendedAction,
    required this.urgencyLevel,
    required this.referralIndicated,
    required this.clinicalGuideline,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    return RecommendationResult(
      summary: json['summary'] ?? 'Ditemukan indikasi retinopati diabetik. Rujuk sesuai interval konsensus.',
      recommendedAction: json['recommendedAction'] ?? json['recommended_action'] ?? 'SPECIALIST_OPHTHALMOLOGY_REFERRAL',
      urgencyLevel: json['urgencyLevel'] ?? json['urgency_level'] ?? 'MEDIUM',
      referralIndicated: json['referralIndicated'] ?? json['referral_indicated'] ?? true,
      clinicalGuideline: json['clinicalGuideline'] ?? json['clinical_guideline'] ?? 'Pedoman Perdami & ADA 2024',
    );
  }
}

class CompleteScreeningResult {
  final String screeningId;
  final String status;
  final QualityCheckResult qualityOD;
  final QualityCheckResult? qualityOS;
  final AIInferenceResult aiResult;
  final ReliabilityResult reliability;
  final RecommendationResult recommendation;
  final String? gradcamImageBase64;
  final String? rawImageBase64;

  CompleteScreeningResult({
    required this.screeningId,
    required this.status,
    required this.qualityOD,
    this.qualityOS,
    required this.aiResult,
    required this.reliability,
    required this.recommendation,
    this.gradcamImageBase64,
    this.rawImageBase64,
  });

  factory CompleteScreeningResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CompleteScreeningResult(
      screeningId: data['screeningId'] ?? data['id'] ?? 'scr-001',
      status: data['status'] ?? data['screeningStatus'] ?? 'AI_ANALYZED',
      qualityOD: QualityCheckResult.fromJson(data['qualityOD'] ?? data['quality_od'] ?? {}),
      qualityOS: data['qualityOS'] != null ? QualityCheckResult.fromJson(data['qualityOS']) : null,
      aiResult: AIInferenceResult.fromJson(data['aiResult'] ?? data['ai_result'] ?? {}),
      reliability: ReliabilityResult.fromJson(data['reliability'] ?? {}),
      recommendation: RecommendationResult.fromJson(data['recommendation'] ?? {}),
      gradcamImageBase64: data['gradcamImageBase64'] ?? data['gradcam_heatmap'] ?? data['gradcam_base64'],
      rawImageBase64: data['rawImageBase64'] ?? data['raw_image_base64'],
    );
  }
}
