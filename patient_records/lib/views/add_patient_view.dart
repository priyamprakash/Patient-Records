import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';

class AddPatientView extends StatefulWidget {
  final VoidCallback? onSuccessAdded;

  const AddPatientView({super.key, this.onSuccessAdded});

  @override
  State<AddPatientView> createState() => _AddPatientViewState();
}

class _AddPatientViewState extends State<AddPatientView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  // Vitals Controllers
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();

  // Additional Optional Fields
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _complaintController = TextEditingController();

  String _gender = 'Male';
  bool _addToQueue = true;
  bool _showVitalsSection = false;
  bool _showMoreDetails = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ClinicRepository();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final age = int.tryParse(_ageController.text) ?? 0;

    Vitals? vitals;
    if (_showVitalsSection) {
      vitals = Vitals(
        bp: _bpController.text.trim(),
        pulse: _pulseController.text.trim(),
        temperature: _tempController.text.trim(),
        weight: _weightController.text.trim(),
        spo2: _spo2Controller.text.trim(),
      );
    }

    final patient = await repo.addPatient(
      name,
      phone,
      age,
      _gender,
      address: _addressController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      addToTodayQueue: _addToQueue,
      chiefComplaint: _complaintController.text.trim(),
      vitals: vitals,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _addToQueue
                ? 'Registered "${patient.name}" & added to Live Queue!'
                : 'Registered "${patient.name}" successfully!',
          ),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
      if (widget.onSuccessAdded != null) {
        widget.onSuccessAdded!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Patient Registration',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.secondaryNavy,
            ),
          ),
          Text(
            'Enter basic patient details to register & issue queue token',
            style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STEP 1: Basic Info (Name, Age, Gender, Phone) ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'REQUIRED DETAILS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (isMobile) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Name required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Phone required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age (Yrs) *',
                              hintText: '35',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Age required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender *',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Patient Full Name *',
                              hintText: 'e.g. Ramesh Kumar',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Name required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Phone required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age (Years) *',
                              hintText: 'e.g. 35',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Age required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender *',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- STEP 2: Option to Fill Vitals ---
                  Container(
                    decoration: BoxDecoration(
                      color: _showVitalsSection ? Colors.teal.shade50.withValues(alpha: 0.6) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showVitalsSection ? AppTheme.primaryTeal.withValues(alpha: 0.5) : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: AppTheme.primaryTeal,
                          secondary: Icon(
                            Icons.monitor_heart_outlined,
                            color: _showVitalsSection ? AppTheme.primaryTeal : Colors.grey.shade600,
                          ),
                          title: Text(
                            'Record Patient Vitals (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _showVitalsSection ? AppTheme.primaryTeal : AppTheme.secondaryNavy,
                            ),
                          ),
                          subtitle: const Text(
                            'BP, Pulse rate, Body Temp, Weight, SpO2',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _showVitalsSection,
                          onChanged: (val) => setState(() => _showVitalsSection = val),
                        ),
                        if (_showVitalsSection) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bpController,
                                        decoration: const InputDecoration(
                                          labelText: 'BP (mmHg)',
                                          hintText: '120/80',
                                          prefixIcon: Icon(Icons.speed),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _pulseController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Pulse (bpm)',
                                          hintText: '72',
                                          prefixIcon: Icon(Icons.favorite_outline),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _tempController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Temp (°F)',
                                          hintText: '98.6',
                                          prefixIcon: Icon(Icons.thermostat_outlined),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _weightController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Weight (kg)',
                                          hintText: '68',
                                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _spo2Controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'SpO2 (%)',
                                          hintText: '98',
                                          prefixIcon: Icon(Icons.air),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- STEP 3: Queue Token & Chief Complaint ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Add to Today\'s Live Queue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text('Issues an instant queue token for consultation today.', style: TextStyle(fontSize: 12)),
                          value: _addToQueue,
                          activeColor: AppTheme.primaryTeal,
                          onChanged: (val) => setState(() => _addToQueue = val ?? true),
                        ),
                        if (_addToQueue) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _complaintController,
                            decoration: const InputDecoration(
                              labelText: 'Chief Complaint / Today\'s Reason for Visit',
                              hintText: 'e.g. Fever for 2 days, Cough, Dizziness',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- STEP 4: Optional Address / Medical History Expandable ---
                  InkWell(
                    onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _showMoreDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showMoreDetails ? 'Hide Address & History' : 'Add Address & Past History (Optional)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showMoreDetails) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Residential Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicalHistoryController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Known Medical History / Allergies',
                        prefixIcon: Icon(Icons.history_edu),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 3,
                      ),
                      onPressed: _submitForm,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Register & Save Patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

