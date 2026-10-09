import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/incident_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Initialize Supabase connection
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Upload photo bytes to 'damage_photos' bucket and return public URL
  static Future<String> uploadDamagePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'incidents/$fileName';
    await client.storage
        .from('damage_photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return client.storage.from('damage_photos').getPublicUrl(path);
  }

  /// Save an official incident report created by an officer
  static Future<IncidentModel> createIncident(Map<String, dynamic> data) async {
    final response = await client
        .from('incidents')
        .insert(data)
        .select()
        .single();
    return IncidentModel.fromJson(response);
  }

  /// Instant Checkpoint Search by Vehicle Registration Number
  static Future<List<IncidentModel>> searchByVehicleNumber(
    String vehicleNumber,
  ) async {
    final cleanPlate = vehicleNumber.replaceAll(' ', '').toUpperCase();
    final response = await client
        .from('incidents')
        .select()
        .ilike('vehicle_number', '%$cleanPlate%')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => IncidentModel.fromJson(json))
        .toList();
  }

  /// Retrieve incident details by unique incident code
  static Future<IncidentModel?> getByIncidentCode(String code) async {
    final response = await client
        .from('incidents')
        .select()
        .eq('incident_code', code)
        .maybeSingle();

    if (response == null) return null;
    return IncidentModel.fromJson(response);
  }

  /// Get active clearance slips for a citizen's phone number
  static Future<List<IncidentModel>> getIncidentsByDriverPhone(
    String phone,
  ) async {
    final response = await client
        .from('incidents')
        .select()
        .eq('driver_phone', phone)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => IncidentModel.fromJson(json))
        .toList();
  }

  /// Update repair status ('Unrepaired' -> 'In Repair' -> 'Repaired')
  static Future<void> updateRepairStatus(
    String incidentId,
    String status,
  ) async {
    await client
        .from('incidents')
        .update({
          'repair_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', incidentId);
  }
}
