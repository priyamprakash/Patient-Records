import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';

class PrescriptionConsultationDialog extends StatefulWidget {
  final QueueItem queueItem;

  const PrescriptionConsultationDialog({super.key, required this.queueItem});

  static Future<void> show(BuildContext context, QueueItem queueItem) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrescriptionConsultationDialog(queueItem: queueItem),
    );
  }

  @override
  State<PrescriptionConsultationDialog> createState() => _PrescriptionConsultationDialogState();
}

class _PrescriptionConsultationDialogState extends State<PrescriptionConsultationDialog> {
  final _repository = ClinicRepository();

  // Clinical Details
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _feeController = TextEditingController(text: '500');

  // Vitals Controllers
  late TextEditingController _bpCtrl;
  late TextEditingController _pulseCtrl;
  late TextEditingController _tempCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _spo2Ctrl;

  // Medicine Assignment Form
  final _medNameCtrl = TextEditingController();
  String _medType = 'Tablet';
  final _dosageCtrl = TextEditingController();
  String _frequency = '1-0-1';
  String _duration = '5 days';
  String _instructions = 'After food';

  final List<PrescribedMedicine> _assignedMedicines = [];

  final List<String> _quickDiagnoses = [
    'Acute Viral Fever',
    'Essential Hypertension',
    'Upper Respiratory Infection (URTI)',
    'Type 2 Diabetes Mellitus',
    'Acute Gastritis / Acid Reflux',
    'Migraine Headache',
    'Allergic Rhinitis',
    'Acute Gastroenteritis',
  ];

  final List<String> _frequencyOptions = ['1-0-1', '1-1-1', '1-0-0', '0-0-1', '1-0-1-0', 'As needed (PRN)'];
  final List<String> _durationOptions = ['3 days', '5 days', '7 days', '10 days', '14 days', '1 month'];
  final List<String> _instructionOptions = ['After food', 'Before food', 'With meals', 'At bedtime', 'Empty stomach'];
  final List<String> _typeOptions = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment', 'Drops', 'Sachet'];

  @override
  void initState() {
    super.initState();
    final v = widget.queueItem.vitals;
    _bpCtrl = TextEditingController(text: v?.bp ?? '');
    _pulseCtrl = TextEditingController(text: v?.pulse ?? '');
    _tempCtrl = TextEditingController(text: v?.temperature ?? '');
    _weightCtrl = TextEditingController(text: v?.weight ?? '');
    _spo2Ctrl = TextEditingController(text: v?.spo2 ?? '');

    // Mark status in consultation when opened if currently waiting
    if (widget.queueItem.status == 'waiting') {
      _repository.updateQueueStatus(widget.queueItem.id, 'inConsultation');
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _feeController.dispose();
    _bpCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _spo2Ctrl.dispose();
    _medNameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  TextEditingController? _autocompleteTextController;
  FocusNode? _autocompleteFocusNode;

  void _onSelectMasterMedicine(MedicineMaster med) {
    setState(() {
      _medNameCtrl.text = med.name;
      _autocompleteTextController?.text = med.name;
      _medType = med.type;
      _dosageCtrl.text = med.defaultDosage;
      if (med.defaultFrequency.isNotEmpty) _frequency = med.defaultFrequency;
      if (med.defaultDuration.isNotEmpty) _duration = med.defaultDuration;
      if (med.defaultInstructions.isNotEmpty) _instructions = med.defaultInstructions;
    });
    _autocompleteFocusNode?.unfocus();
  }

  void _addMedicineToPrescription() {
    final name = _medNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter medicine name')),
      );
      return;
    }

    setState(() {
      _assignedMedicines.add(PrescribedMedicine(
        name: name,
        type: _medType,
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        duration: _duration,
        instructions: _instructions,
      ));

      // Reset selection form completely
      _medNameCtrl.clear();
      _autocompleteTextController?.clear();
      _dosageCtrl.clear();
    });

    _autocompleteFocusNode?.unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$name" to prescription'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  void _showAddMasterMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    String type = 'Tablet';
    String freq = '1-0-1';
    String dur = '5 days';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Medicine to Master List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name *', hintText: 'e.g. Paracetamol 650mg'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => type = val!,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: 'Default Dosage', hintText: 'e.g. 500mg, 10ml'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: freq,
                      decoration: const InputDecoration(labelText: 'Default Frequency'),
                      items: _frequencyOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) => freq = val!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: dur,
                      decoration: const InputDecoration(labelText: 'Default Duration'),
                      items: _durationOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) => dur = val!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final med = MedicineMaster(
                id: 'MED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                name: name,
                type: type,
                defaultDosage: dosageCtrl.text.trim(),
                defaultFrequency: freq,
                defaultDuration: dur,
              );
              await _repository.addMedicine(med);
              if (ctx.mounted) Navigator.pop(ctx);
              _onSelectMasterMedicine(med);
            },
            child: const Text('Add to Database'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeVisit() async {
    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Diagnosis before completing visit')),
      );
      return;
    }

    final fee = double.tryParse(_feeController.text) ?? 500.0;
    final vitals = Vitals(
      bp: _bpCtrl.text.trim(),
      pulse: _pulseCtrl.text.trim(),
      temperature: _tempCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      spo2: _spo2Ctrl.text.trim(),
    );

    final prescriptionSummary = _assignedMedicines.isNotEmpty
        ? _assignedMedicines.map((m) => m.displayText).join('\n')
        : '';

    await _repository.attendPatient(
      queueItem: widget.queueItem,
      diagnosis: diagnosis,
      prescription: prescriptionSummary,
      notes: _notesController.text.trim(),
      fee: fee,
      vitals: vitals,
      medicines: _assignedMedicines,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit completed & prescription saved for "${widget.queueItem.patientName}"!'),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? mediaQuery.size.width * 0.96 : 850,
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TOKEN #${widget.queueItem.tokenNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.queueItem.patientName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Phone: ${widget.queueItem.patientPhone}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // --- CONTENT BODY ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chief Complaint Banner
                    if (widget.queueItem.chiefComplaint.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Chief Complaint: ${widget.queueItem.chiefComplaint}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- SECTION 1: Patient Vitals ---
                    Text(
                      '1. Patient Vitals',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: isMobile
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildVitalsField(_bpCtrl, 'BP (mmHg)', Icons.speed)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildVitalsField(_pulseCtrl, 'Pulse (bpm)', Icons.favorite_outline)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _buildVitalsField(_tempCtrl, 'Temp (°F)', Icons.thermostat_outlined)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildVitalsField(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildVitalsField(_spo2Ctrl, 'SpO2 (%)', Icons.air)),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildVitalsField(_bpCtrl, 'BP (mmHg)', Icons.speed)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildVitalsField(_pulseCtrl, 'Pulse (bpm)', Icons.favorite_outline)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildVitalsField(_tempCtrl, 'Temp (°F)', Icons.thermostat_outlined)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildVitalsField(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildVitalsField(_spo2Ctrl, 'SpO2 (%)', Icons.air)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // --- SECTION 2: Clinical Assessment & Notes ---
                    Text(
                      '2. Clinical Diagnosis & Doctor Notes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _diagnosisController,
                            decoration: const InputDecoration(
                              labelText: 'Diagnosis *',
                              hintText: 'e.g. Acute Viral Bronchitis, Type 2 Diabetes',
                              prefixIcon: Icon(Icons.healing_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Consult Fee (₹)',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Diagnosis Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _quickDiagnoses.map((diag) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14, color: AppTheme.primaryTeal),
                          label: Text(diag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.08),
                          side: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                          onPressed: () {
                            setState(() {
                              if (_diagnosisController.text.isEmpty) {
                                _diagnosisController.text = diag;
                              } else {
                                _diagnosisController.text = '${_diagnosisController.text}, $diag';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Remarks & Advice (Optional)',
                        hintText: 'e.g. Steam inhalation twice daily, Low salt diet',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- SECTION 3: Assign Medicines (Prescription Builder) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '3. Assign Medicines',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                        ),
                        TextButton.icon(
                          onPressed: _showAddMasterMedicineDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Medicine to Database', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Select Medicine from Master List
                          Autocomplete<MedicineMaster>(
                            displayStringForOption: (option) => option.name,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.trim().isEmpty) {
                                return const Iterable<MedicineMaster>.empty();
                              }
                              return _repository.searchMedicines(textEditingValue.text);
                            },
                            onSelected: _onSelectMasterMedicine,
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: isMobile ? mediaQuery.size.width * 0.85 : 450,
                                    constraints: const BoxConstraints(maxHeight: 220),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1),
                                      itemBuilder: (BuildContext context, int index) {
                                        final MedicineMaster option = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          leading: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              option.type,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryTeal,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            option.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          subtitle: option.defaultDosage.isNotEmpty
                                              ? Text(
                                                  'Default: ${option.defaultDosage} • ${option.defaultFrequency}',
                                                  style: const TextStyle(fontSize: 11),
                                                )
                                              : null,
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              _autocompleteTextController = controller;
                              _autocompleteFocusNode = focusNode;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Select / Search Medicine from List',
                                  hintText: 'Type to search e.g. Paracetamol, Amoxicillin...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: controller.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            controller.clear();
                                            _medNameCtrl.clear();
                                            focusNode.unfocus();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (val) {
                                  _medNameCtrl.text = val;
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Type & Dosage
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _medType,
                                  decoration: const InputDecoration(labelText: 'Form / Type'),
                                  items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (val) => setState(() => _medType = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _dosageCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Dosage',
                                    hintText: 'e.g. 500mg, 10ml',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Frequency Selector
                          const Text('Frequency:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _frequencyOptions.map((freq) {
                              final isSelected = _frequency == freq;
                              return ChoiceChip(
                                label: Text(freq, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  if (sel) setState(() => _frequency = freq);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // Duration & Instructions Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _duration,
                                  decoration: const InputDecoration(labelText: 'Duration'),
                                  items: _durationOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                  onChanged: (val) => setState(() => _duration = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _instructions,
                                  decoration: const InputDecoration(labelText: 'Instructions'),
                                  items: _instructionOptions.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                                  onChanged: (val) => setState(() => _instructions = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryNavy,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _addMedicineToPrescription,
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('+ Add Medicine to Prescription'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- ASSIGNED MEDICINES LIST TABLE ---
                    Text(
                      'Assigned Medicines (${_assignedMedicines.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),

                    _assignedMedicines.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'No medicines assigned yet. Select medicine above and tap "+ Add Medicine".',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _assignedMedicines.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
                            itemBuilder: (ctx, idx) {
                              final item = _assignedMedicines[idx];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                                    child: Text(
                                      item.type[0].toUpperCase(),
                                      style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '${item.type} ${item.name} ${item.dosage.isNotEmpty ? "(${item.dosage})" : ""}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Frequency: ${item.frequency}  •  Duration: ${item.duration}  •  [${item.instructions}]',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => setState(() => _assignedMedicines.removeAt(idx)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

            // --- FOOTER ACTIONS ---
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusCompleted,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 3,
                    ),
                    onPressed: _completeVisit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Complete Consultation & Save',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixIcon: Icon(icon, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 12),
    );
  }
}
