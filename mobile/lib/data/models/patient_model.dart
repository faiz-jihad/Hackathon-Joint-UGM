class PatientModel {
  final String id;
  final String nik;
  final String fullName;
  final String birthDate;
  final String gender;
  final int age;
  final String? phone;
  final String? address;
  final DiabetesProfileModel? diabetesProfile;

  PatientModel({
    required this.id,
    required this.nik,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.age,
    this.phone,
    this.address,
    this.diabetesProfile,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      nik: json['nik'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      birthDate: json['birthDate'] ?? json['birth_date'] ?? '',
      gender: json['gender'] ?? 'MALE',
      age: json['age'] is int
          ? json['age']
          : int.tryParse('${json['age']}') ?? 52,
      phone: json['phone'],
      address: json['address'],
      diabetesProfile: json['diabetesProfile'] != null
          ? DiabetesProfileModel.fromJson(json['diabetesProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nik': nik,
        'fullName': fullName,
        'birthDate': birthDate,
        'gender': gender,
        'age': age,
        'phone': phone,
        'address': address,
        'diabetesProfile': diabetesProfile?.toJson(),
      };
}

class DiabetesProfileModel {
  final String diabetesType;
  final int? yearOfDiagnosis;
  final String currentTreatment;
  final double? lastHbA1c;
  final String? glycaemicControlStatus;
  final int? systolicBp;
  final int? diastolicBp;

  DiabetesProfileModel({
    required this.diabetesType,
    this.yearOfDiagnosis,
    required this.currentTreatment,
    this.lastHbA1c,
    this.glycaemicControlStatus,
    this.systolicBp,
    this.diastolicBp,
  });

  int get diagnosisYear => yearOfDiagnosis ?? 2020;

  String get bloodPressure => (systolicBp != null && diastolicBp != null)
      ? '$systolicBp/$diastolicBp mmHg'
      : '130/85 mmHg';

  bool get hasInsulinTherapy =>
      currentTreatment == 'INSULIN' || currentTreatment == 'COMBINATION';

  factory DiabetesProfileModel.fromJson(Map<String, dynamic> json) {
    return DiabetesProfileModel(
      diabetesType: json['diabetesType'] ?? json['diabetes_type'] ?? 'TYPE_2',
      yearOfDiagnosis: json['yearOfDiagnosis'] ?? json['year_of_diagnosis'],
      currentTreatment: json['currentTreatment'] ??
          json['current_treatment'] ??
          'ORAL_MEDICATION',
      lastHbA1c: (json['lastHbA1c'] ?? json['last_hba1c'])?.toDouble(),
      glycaemicControlStatus: json['glycaemicControlStatus'] ??
          json['glycaemic_control_status'] ??
          'OPTIMAL',
      systolicBp: json['systolicBp'] ?? json['systolic_bp'],
      diastolicBp: json['diastolicBp'] ?? json['diastolic_bp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'diabetesType': diabetesType,
        'yearOfDiagnosis': yearOfDiagnosis,
        'currentTreatment': currentTreatment,
        'lastHbA1c': lastHbA1c,
        'glycaemicControlStatus': glycaemicControlStatus,
        'systolicBp': systolicBp,
        'diastolicBp': diastolicBp,
      };
}
