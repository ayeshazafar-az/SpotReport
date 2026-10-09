class ProfileModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? cnic;
  final String role; // 'citizen', 'officer', 'admin'
  final String? badgeNumber;
  final String? department;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.cnic,
    required this.role,
    this.badgeNumber,
    this.department,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      cnic: json['cnic'] as String?,
      role: json['role'] as String? ?? 'citizen',
      badgeNumber: json['badge_number'] as String?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'cnic': cnic,
      'role': role,
      'badge_number': badgeNumber,
      'department': department,
    };
  }
}
