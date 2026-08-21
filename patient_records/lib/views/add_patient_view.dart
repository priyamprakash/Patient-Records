import 'package:flutter/material.dart';
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
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _complaintController = TextEditingController();

  String _gender = 'Male';
  bool _addToQueue = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
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
    final address = _addressController.text.trim();
    final medHistory = _medicalHistoryController.text.trim();
    final complaint = _complaintController.text.trim();

    final patient = await repo.addPatient(
      name,
      phone,
      age,
      _gender,
      address: address,
      medicalHistory: medHistory,
      addToTodayQueue: _addToQueue,
      chiefComplaint: complaint,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _addToQueue
                ? 'Registered "${patient.name}" and added to Queue!'
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
            'New Patient Registration',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.secondaryNavy,
            ),
          ),
          Text(
            'Register a new patient into clinic records',
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
                  ] else
                    Row(
                      children: [
                        Expanded(
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
                  const SizedBox(height: 12),

                  if (isMobile) ...[
                    TextFormField(
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ] else
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
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 16),

                  const Divider(),

                  // Today's Queue addition checkbox section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Add directly to Today\'s Waiting Queue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text('Issues an instant queue token for today.', style: TextStyle(fontSize: 12)),
                          value: _addToQueue,
                          activeColor: AppTheme.primaryTeal,
                          onChanged: (val) => setState(() => _addToQueue = val ?? true),
                        ),
                        if (_addToQueue) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _complaintController,
                            decoration: const InputDecoration(
                              labelText: 'Chief Complaint / Today\'s Problem',
                              hintText: 'e.g. High fever, headache',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Register Patient', style: TextStyle(fontSize: 16)),
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
