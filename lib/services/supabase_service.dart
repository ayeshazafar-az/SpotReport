import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/incident_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // ====================================================================
  // AUTHENTICATION METHODS
  // ====================================================================

  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String cnic,
    required String role,
  }) async {
    final response = await client.auth.signUp(email: email, password: password);

    if (response.user != null) {
      // Create the profile in the public.profiles table
      await client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName,
        'phone_number': phone,
        'cnic': cnic,
        'role': role,
      });
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ====================================================================
  // EXISTING INCIDENT METHODS
  // ====================================================================

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

  static Future<IncidentModel> createIncident(Map<String, dynamic> data) async {
    final response = await client
        .from('incidents')
        .insert(data)
        .select()
        .single();
    return IncidentModel.fromJson(response);
  }

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

  static Future<IncidentModel?> getByIncidentCode(String code) async {
    final response = await client
        .from('incidents')
        .select()
        .eq('incident_code', code)
        .maybeSingle();
    if (response == null) return null;
    return IncidentModel.fromJson(response);
  }

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
