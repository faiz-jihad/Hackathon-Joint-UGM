class DailyCheckInSubmission {
  final String patientId;
  final String physicalCondition;
  final String visualSymptoms;
  final Map<String, bool> visualFlags;
  final double? bloodGlucose;
  final String glucoseContext;
  final bool medicationsCompleted;
  final bool activityCompleted;
  final String? patientNotes;

  DailyCheckInSubmission({
    required this.patientId,
    required this.physicalCondition,
    required this.visualSymptoms,
    required this.visualFlags,
    this.bloodGlucose,
    required this.glucoseContext,
    required this.medicationsCompleted,
    required this.activityCompleted,
    this.patientNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'physicalCondition': physicalCondition,
      'visualSymptoms': visualSymptoms,
      'visualFlags': visualFlags,
      'bloodGlucose': bloodGlucose,
      'glucoseContext': glucoseContext,
      'medicationsCompleted': medicationsCompleted,
      'activityCompleted': activityCompleted,
      'patientNotes': patientNotes,
    };
  }
}

class DailyCheckInResult {
  final bool isEmergency;
  final String severity;
  final String summary;
  final String explanation;
  final String nextStep;
  final List<String> matchedTriggers;
  final List<String> actionableGuidance;
  final String clinicalSafetyNotice;

  DailyCheckInResult({
    required this.isEmergency,
    required this.severity,
    required this.summary,
    required this.explanation,
    required this.nextStep,
    required this.matchedTriggers,
    required this.actionableGuidance,
    required this.clinicalSafetyNotice,
  });

  factory DailyCheckInResult.fromJson(Map<String, dynamic> json) {
    final triggers = json['matched_triggers'] ?? json['matchedTriggers'];
    final guidance = json['actionable_guidance'] ?? json['actionableGuidance'];

    return DailyCheckInResult(
      isEmergency: json['is_emergency'] == true || json['isEmergency'] == true,
      severity: json['severity']?.toString() ?? 'ROUTINE',
      summary: json['summary']?.toString() ?? 'Evaluasi Harian Selesai',
      explanation: json['explanation']?.toString() ?? 'Kondisi kesehatan harian tercatat.',
      nextStep: json['next_step']?.toString() ?? json['nextStep']?.toString() ?? 'Lanjutkan jadwal harian.',
      matchedTriggers: triggers is List ? triggers.map((e) => e.toString()).toList() : [],
      actionableGuidance: guidance is List ? guidance.map((e) => e.toString()).toList() : [],
      clinicalSafetyNotice: json['clinical_safety_notice']?.toString() ??
          json['clinicalSafetyNotice']?.toString() ??
          'Catatan: Evaluasi ini tidak menggantikan konsultasi langsung dengan dokter spesialis mata (Sp.M).',
    );
  }
}
