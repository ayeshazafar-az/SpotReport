class IncidentModel {
  final String id;
  final String incidentCode;
  final String officerId;
  final String vehicleNumber;
  final String driverCnic;
  final String driverPhone;
  final String causeCategory;
  final String? description;
  final List<String> damagePhotos;
  final String highwayName;
  final double latitude;
  final double longitude;
  final String? aiDamageSummary;
  final String aiSeverity;
  final String repairStatus;
  final DateTime createdAt;

  IncidentModel({
    required this.id,
    required this.incidentCode,
    required this.officerId,
    required this.vehicleNumber,
    required this.driverCnic,
    required this.driverPhone,
    required this.causeCategory,
    this.description,
    required this.damagePhotos,
    required this.highwayName,
    required this.latitude,
    required this.longitude,
    this.aiDamageSummary,
    required this.aiSeverity,
    required this.repairStatus,
    required this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      incidentCode: json['incident_code'] as String,
      officerId: json['officer_id'] as String,
      vehicleNumber: json['vehicle_number'] as String,
      driverCnic: json['driver_cnic'] as String,
      driverPhone: json['driver_phone'] as String,
      causeCategory: json['cause_category'] as String,
      description: json['description'] as String?,
      damagePhotos: List<String>.from(json['damage_photos'] ?? []),
      highwayName: json['highway_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      aiDamageSummary: json['ai_damage_summary'] as String?,
      aiSeverity: json['ai_severity'] as String? ?? 'Minor',
      repairStatus: json['repair_status'] as String? ?? 'Unrepaired',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incident_code': incidentCode,
      'officer_id': officerId,
      'vehicle_number': vehicleNumber,
      'driver_cnic': driverCnic,
      'driver_phone': driverPhone,
      'cause_category': causeCategory,
      'description': description,
      'damage_photos': damagePhotos,
      'highway_name': highwayName,
      'latitude': latitude,
      'longitude': longitude,
      'ai_damage_summary': aiDamageSummary,
      'ai_severity': aiSeverity,
      'repair_status': repairStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
