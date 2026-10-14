class SosNotificationModel {
  final String id;
  final String recipientName;
  final String recipientPhone;
  final String recipientType;
  final String channel;
  final String message;
  final String status;
  final String? deliveryConfirmedAt;

  SosNotificationModel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientType,
    required this.channel,
    required this.message,
    required this.status,
    this.deliveryConfirmedAt,
  });

  factory SosNotificationModel.fromJson(Map<String, dynamic> json) {
    return SosNotificationModel(
      id: json['id'] ?? '',
      recipientName: json['recipientName'] ?? 'Kontak Darurat',
      recipientPhone: json['recipientPhone'] ?? '',
      recipientType: json['recipientType'] ?? 'EMERGENCY_CONTACT',
      channel: json['channel'] ?? 'WHATSAPP',
      message: json['message'] ?? '',
      status: json['status'] ?? 'SENT',
      deliveryConfirmedAt: json['deliveryConfirmedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'recipientType': recipientType,
    'channel': channel,
    'message': message,
    'status': status,
    'deliveryConfirmedAt': deliveryConfirmedAt,
  };
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;
  final bool isVerified;
  final String preferredChannel;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = false,
    this.isVerified = true,
    this.preferredChannel = 'WHATSAPP',
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? 'Keluarga',
      phoneNumber: json['phoneNumber'] ?? '',
      isPrimary: json['isPrimary'] == true,
      isVerified: json['isVerified'] != false,
      preferredChannel: json['preferredChannel'] ?? 'WHATSAPP',
    );
  }
}

class SosIncidentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String status; // ACTIVE, ACKNOWLEDGED, RESOLVED, CANCELLED
  final String urgencyLevel; // CRITICAL, HIGH, MEDIUM, LOW
  final List<String> symptoms;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String locationStatus;
  final String? locationAddress;
  final String? secureTrackingToken;
  final String? triageSummary;
  final String? recommendedAction;
  final bool oralFoodAllowed;
  final bool requiresAmbulance;
  final bool requiresEyeSpecialist;
  final List<SosNotificationModel> notifications;
  final DateTime createdAt;

  SosIncidentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.status,
    required this.urgencyLevel,
    required this.symptoms,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    required this.locationStatus,
    this.locationAddress,
    this.secureTrackingToken,
    this.triageSummary,
    this.recommendedAction,
    this.oralFoodAllowed = true,
    this.requiresAmbulance = false,
    this.requiresEyeSpecialist = false,
    required this.notifications,
    required this.createdAt,
  });

  factory SosIncidentModel.fromJson(Map<String, dynamic> json) {
    final triage = json['triageAssessment'] as Map<String, dynamic>?;

    return SosIncidentModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Pasien Retiva',
      status: json['status'] ?? 'ACTIVE',
      urgencyLevel: json['urgencyLevel'] ?? 'HIGH',
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      locationStatus: json['locationStatus'] ?? 'PENDING',
      locationAddress: json['locationAddress'],
      secureTrackingToken: json['secureTrackingToken'],
      triageSummary: json['triageSummary'] ?? triage?['clinicalRisk'],
      recommendedAction: json['recommendedAction'] ?? triage?['immediateAction'],
      oralFoodAllowed: triage?['oralFoodAllowed'] != false,
      requiresAmbulance: triage?['requiresAmbulance'] == true,
      requiresEyeSpecialist: triage?['requiresEyeSpecialist'] == true,
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((n) => SosNotificationModel.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
