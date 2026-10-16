class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? facilityId;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.facilityId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? 'Pengguna',
      role: json['role'] ?? 'PATIENT',
      facilityId: json['facilityId'] ?? json['facility_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'facilityId': facilityId,
      };
}
