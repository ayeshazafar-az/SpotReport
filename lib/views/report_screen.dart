import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';

class OfficerReportScreen extends StatefulWidget {
  const OfficerReportScreen({super.key});

  @override
  State<OfficerReportScreen> createState() => _OfficerReportScreenState();
}

class _OfficerReportScreenState extends State<OfficerReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _vehicleController = TextEditingController();
  final _driverCnicController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _highwayController = TextEditingController(
    text: 'M-2 Motorway (Km 184)',
  );
  final _descriptionController = TextEditingController();

  // State Variables
  String _selectedCategory = 'Animal Collision';
  Uint8List? _imageBytes;
  String? _imageFileName;

  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  final List<String> _causeCategories = [
    'Animal Collision',
    'Tire Burst',
    'Falling Debris',
    'Road Obstacle',
    'Minor Fender Bender',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _driverCnicController.dispose();
    _driverPhoneController.dispose();
    _highwayController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Image Picker (Works for Web & Mobile)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        });
      }
    } catch (e) {
      _showSnackBar('Failed to select photo: $e', isError: true);
    }
  }

  /// GPS Location Fetcher
  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _latitude = 33.6844;
          _longitude = 73.0479; // Default fallback (Islamabad)
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _latitude = 33.6844;
            _longitude = 73.0479;
            _isFetchingLocation = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isFetchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _latitude = 33.6844;
        _longitude = 73.0479;
        _isFetchingLocation = false;
      });
    }
  }

  /// Generate Incident Code (e.g. INC-2026-9812)
  String _generateIncidentCode() {
    final randomNum = Random().nextInt(8999) + 1000;
    return 'INC-2026-$randomNum';
  }

  /// Submit Form Process
  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      _showSnackBar(
        'Please capture or select a damage photo as evidence.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Damage Photo to Supabase Storage
      final photoUrl = await SupabaseService.uploadDamagePhoto(
        bytes: _imageBytes!,
        fileName:
            _imageFileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // 2. Gemini AI Damage Analysis
      final aiResult = await GeminiService.analyzeDamageImage(
        imageBytes: _imageBytes!,
        contextDescription: _descriptionController.text,
      );

      // 3. Generate Code
      final incidentCode = _generateIncidentCode();

      // 4. Fallback/Mock Officer ID for testing if auth is uninitialized
      final currentUserId =
          SupabaseService.client.auth.currentUser?.id ??
          '00000000-0000-0000-0000-000000000000';

      // 5. Construct Payload
      final incidentData = {
        'incident_code': incidentCode,
        'officer_id': currentUserId,
        'vehicle_number': _vehicleController.text.trim().toUpperCase(),
        'driver_cnic': _driverCnicController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim(),
        'cause_category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'damage_photos': [photoUrl],
        'highway_name': _highwayController.text.trim(),
        'latitude': _latitude ?? 33.6844,
        'longitude': _longitude ?? 73.0479,
        'ai_damage_summary': aiResult.damageSummary,
        'ai_severity': aiResult.severity,
        'repair_status': 'Unrepaired',
      };

      // 6. Save to Supabase DB
      await SupabaseService.createIncident(incidentData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show Success Dialog
      _showSuccessDialog(incidentCode, photoUrl, aiResult);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Error logging incident: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showSuccessDialog(
    String code,
    String photoUrl,
    GeminiAnalysisResult ai,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Slip Registered'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official Incident Slip generated successfully.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E88E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INCIDENT CODE',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  Text(
                    'Vehicle: ${_vehicleController.text.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Severity: ${ai.severity}',
                    style: const TextStyle(color: Colors.amber),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Notes: ${ai.damageSummary}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text(
              'Done / New Report',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _vehicleController.clear();
    _driverCnicController.clear();
    _driverPhoneController.clear();
    _descriptionController.clear();
    setState(() {
      _imageBytes = null;
      _imageFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OFFICER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            const Text('On-Spot Incident Log'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo Capture Section
              const Text(
                '1. Vehicle Damage Evidence *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showImageSourceBottomSheet(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes == null
                          ? const Color(0xFF333333)
                          : const Color(0xFF1E88E5),
                      width: 2,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Color(0xFF1E88E5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Capture / Select Damage Photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Location & Highway Data
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFB300)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Coordinates',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _isFetchingLocation
                                  ? 'Fetching GPS...'
                                  : '${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF1E88E5),
                        ),
                        onPressed: _fetchCurrentLocation,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Incident Details Form
              const Text(
                '2. Incident Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _vehicleController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Registration Number *',
                  hintText: 'e.g. ICT-1234 or LEB-984',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Enter vehicle plate number'
                    : null,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _driverCnicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Driver CNIC *',
                        hintText: '3520212345671',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _driverPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Driver Mobile *',
                        hintText: '03001234567',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Accident Cause Category *',
                  border: OutlineInputBorder(),
                ),
                items: _causeCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _highwayController,
                decoration: const InputDecoration(
                  labelText: 'Highway / Sector Location *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter location' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Officer Context Notes (Optional)',
                  hintText:
                      'e.g. Cow crossed barrier, broken driver headlight and windshield.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitIncident,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.verified),
                  label: Text(
                    _isSubmitting
                        ? 'Processing & Analyzing...'
                        : 'Generate Official Clearance Slip',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5)),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFFFB300),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
