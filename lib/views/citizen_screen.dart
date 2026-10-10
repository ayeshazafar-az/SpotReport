import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../models/incident_model.dart';

class CitizenSlipsScreen extends StatefulWidget {
  const CitizenSlipsScreen({super.key});

  @override
  State<CitizenSlipsScreen> createState() => _CitizenSlipsScreenState();
}

class _CitizenSlipsScreenState extends State<CitizenSlipsScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  List<IncidentModel> _slips = [];

  Future<void> _fetchMySlips() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await SupabaseService.getIncidentsByDriverPhone(phone);
      if (mounted) {
        setState(() {
          _slips = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching slips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRepairProof(IncidentModel incident) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final bytes = await pickedFile.readAsBytes();

      // Upload proof photo to storage (reusing our existing upload method for simplicity)
      await SupabaseService.uploadDamagePhoto(
        bytes: bytes,
        fileName:
            'repair_${incident.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Update database status
      await SupabaseService.updateRepairStatus(incident.id, 'Repaired');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _fetchMySlips(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair proof submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                color: const Color(0xFF4CAF50), // Citizen Green
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CITIZEN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('My Clearance Slips'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => SupabaseService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Phone Number Input Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter Registered Phone (e.g. 03001234567)',
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onFieldSubmitted: (_) => _fetchMySlips(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _fetchMySlips,
                  child: const Text(
                    'Find Slips',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Slips List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.folder_shared_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Enter your phone to view slips',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _slips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'No Active Slips',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your vehicle records are clear.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _slips.length,
                    itemBuilder: (context, index) {
                      final incident = _slips[index];
                      final isRepaired = incident.repairStatus == 'Repaired';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isRepaired ? Colors.green : Colors.amber,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    incident.vehicleNumber,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRepaired
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isRepaired
                                            ? Colors.green
                                            : Colors.amber,
                                      ),
                                    ),
                                    child: Text(
                                      incident.repairStatus,
                                      style: TextStyle(
                                        color: isRepaired
                                            ? Colors.green
                                            : Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 24,
                                color: Color(0xFF333333),
                              ),
                              Text(
                                'Code: ${incident.incidentCode}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${incident.createdAt.toLocal().toString().split('.')[0]}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),

                              const Text(
                                'Damage Summary',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                incident.aiDamageSummary ??
                                    'Visual damage recorded.',
                                style: const TextStyle(fontSize: 13),
                              ),

                              const SizedBox(height: 16),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRepaired
                                        ? const Color(0xFF2C2C2C)
                                        : const Color(0xFF1E88E5),
                                    foregroundColor: isRepaired
                                        ? Colors.grey
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: isRepaired
                                      ? null
                                      : () => _submitRepairProof(incident),
                                  icon: Icon(
                                    isRepaired
                                        ? Icons.verified
                                        : Icons.upload_file,
                                  ),
                                  label: Text(
                                    isRepaired
                                        ? 'Repairs Verified'
                                        : 'Submit Repair Proof',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
