import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'patient_detail_dialog.dart';
import 'prescription_consultation_dialog.dart';

class QueueView extends StatefulWidget {
  final VoidCallback? onNavigateToAddPatient;

  const QueueView({super.key, this.onNavigateToAddPatient});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final _repository = ClinicRepository();
  final _searchController = TextEditingController();
  String _filterMode = 'All'; // 'All', 'Alerts', 'Consulting'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPrescriptionConsultation(QueueItem item) {
    PrescriptionConsultationDialog.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final allQueue = _repository.waitingQueue;
        final inConsultationCount = allQueue.where((q) => q.status == 'inConsultation').length;
        final waitingCount = allQueue.where((q) => q.status == 'waiting').length;

        // Apply Search & Filter
        final query = _searchController.text.trim().toLowerCase();
        final filteredQueue = allQueue.where((item) {
          final matchesSearch = query.isEmpty ||
              item.patientName.toLowerCase().contains(query) ||
              item.patientPhone.contains(query) ||
              item.tokenNumber.toString().contains(query);

          if (!matchesSearch) return false;

          if (_filterMode == 'Alerts') {
            return item.vitals != null && _hasVitalAlert(item.vitals!);
          } else if (_filterMode == 'Consulting') {
            return item.status == 'inConsultation';
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Quick Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Live Queue",
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.secondaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                    onPressed: widget.onNavigateToAddPatient,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(isMobile ? '+ Register' : 'Register & Add Patient', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Summary Stat Cards (Light Executive)
              Row(
                children: [
                  _buildStatCard('Waiting Queue', '$waitingCount', Icons.hourglass_top_rounded, AppTheme.statusWaiting, isMobile),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildStatCard('In Consultation', '$inConsultationCount', Icons.medical_services_rounded, AppTheme.statusInConsultation, isMobile),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildStatCard('Attended Today', '${_repository.attendedTodayQueue.length}', Icons.check_circle_rounded, AppTheme.statusCompleted, isMobile),
                ],
              ),
              const SizedBox(height: 18),

              // Search & Filter Bar
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by patient name, phone, or token #...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => setState(() => _searchController.clear()),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'All (${allQueue.length})'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Consulting', 'In Consult ($inConsultationCount)'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Alerts', 'Vitals Alert ⚠️'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Queue List
              filteredQueue.isEmpty
                  ? GlassCard(
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty ? Icons.search_off_rounded : Icons.check_circle_outline_rounded,
                              size: isMobile ? 36 : 48,
                              color: AppTheme.primaryTeal.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No patients match your search criteria.'
                                  : 'No patients currently waiting in queue.',
                              style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Click "+ Register" to issue a new queue token.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredQueue.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredQueue[index];
                        final isConsulting = item.status == 'inConsultation';
                        final vitals = item.vitals;
                        final hasAlert = vitals != null && _hasVitalAlert(vitals);
                        final accentColor = hasAlert
                            ? AppTheme.accentRose
                            : (isConsulting ? AppTheme.statusInConsultation : AppTheme.statusWaiting);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasAlert
                                  ? AppTheme.accentRose.withValues(alpha: 0.4)
                                  : (isConsulting ? AppTheme.statusInConsultation.withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080F172A),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Status Accent Strip
                                  Container(
                                    width: 5,
                                    color: accentColor,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top Row: Token Pill + Status Pill + Wait Time
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Text(
                                                  'TOKEN #${item.tokenNumber}',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryDark,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatusBadge(isConsulting, hasAlert),
                                              const Spacer(),
                                              Text(
                                                '🕒 ${dateFormat.format(item.timeAdded)}',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Patient Name & Subtitle Info
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.patientName,
                                                      style: TextStyle(
                                                        fontSize: isMobile ? 16 : 18,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.primaryDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '📱 ${item.patientPhone}',
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Desktop Action Buttons
                                              if (!isMobile) ...[
                                                OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  ),
                                                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                                                  label: const Text('Profile'),
                                                  onPressed: () {
                                                    final patient = _repository.getPatientById(item.patientId);
                                                    if (patient != null) {
                                                      PatientDetailDialog.show(context, patient);
                                                    }
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isConsulting ? AppTheme.statusCompleted : AppTheme.statusInConsultation,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                  ),
                                                  icon: const Icon(Icons.medical_services_rounded, size: 16),
                                                  label: Text(isConsulting ? 'Prescribe & Attend' : 'Start Consultation'),
                                                  onPressed: () => _openPrescriptionConsultation(item),
                                                ),
                                              ],
                                            ],
                                          ),

                                          // Chief Complaint Banner
                                          if (item.chiefComplaint.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.amber.shade200),
                                              ),
                                              child: Text(
                                                'Complaint: ${item.chiefComplaint}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                          ],

                                          // Vitals Badges Row
                                          if (vitals != null && !vitals.isEmpty) ...[
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                if (vitals.bp.isNotEmpty)
                                                  _buildVitalBadge('BP', vitals.bp, _getBPColor(vitals.bp)),
                                                if (vitals.pulse.isNotEmpty)
                                                  _buildVitalBadge('Pulse', '${vitals.pulse} bpm', _getPulseColor(vitals.pulse)),
                                                if (vitals.temperature.isNotEmpty)
                                                  _buildVitalBadge('Temp', '${vitals.temperature}°F', _getTempColor(vitals.temperature)),
                                                if (vitals.spo2.isNotEmpty)
                                                  _buildVitalBadge('SpO2', '${vitals.spo2}%', _getSpO2Color(vitals.spo2)),
                                                if (vitals.weight.isNotEmpty)
                                                  _buildVitalBadge('Weight', '${vitals.weight} kg', AppTheme.primaryDark),
                                              ],
                                            ),
                                          ],

                                          // Mobile Actions
                                          if (isMobile) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                OutlinedButton(
                                                  onPressed: () {
                                                    final patient = _repository.getPatientById(item.patientId);
                                                    if (patient != null) {
                                                      PatientDetailDialog.show(context, patient);
                                                    }
                                                  },
                                                  child: const Text('Profile', style: TextStyle(fontSize: 12)),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isConsulting ? AppTheme.statusCompleted : AppTheme.statusInConsultation,
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  ),
                                                  onPressed: () => _openPrescriptionConsultation(item),
                                                  icon: const Icon(Icons.medical_services_rounded, size: 16),
                                                  label: Text(isConsulting ? 'Attend' : 'Start Consult', style: const TextStyle(fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterMode == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _filterMode = key);
      },
      selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade700,
      ),
    );
  }

  bool _hasVitalAlert(Vitals vitals) {
    if (vitals.bp.isNotEmpty) {
      final sys = int.tryParse(vitals.bp.split('/').first.trim()) ?? 0;
      if (sys >= 140) return true;
    }
    if (vitals.spo2.isNotEmpty) {
      final s = int.tryParse(vitals.spo2.trim()) ?? 100;
      if (s < 95) return true;
    }
    if (vitals.temperature.isNotEmpty) {
      final t = double.tryParse(vitals.temperature.trim()) ?? 98.6;
      if (t >= 100.4) return true;
    }
    return false;
  }

  Color _getBPColor(String bp) {
    final sys = int.tryParse(bp.split('/').first.trim()) ?? 120;
    if (sys >= 140) return AppTheme.accentRose;
    if (sys >= 130) return AppTheme.statusWaiting;
    return AppTheme.statusCompleted;
  }

  Color _getPulseColor(String pulseStr) {
    final pulse = int.tryParse(pulseStr.trim()) ?? 72;
    if (pulse < 55 || pulse > 105) return AppTheme.accentRose;
    return AppTheme.statusCompleted;
  }

  Color _getTempColor(String tempStr) {
    final temp = double.tryParse(tempStr.trim()) ?? 98.6;
    if (temp >= 100.4) return AppTheme.accentRose;
    if (temp >= 99.2) return AppTheme.statusWaiting;
    return AppTheme.statusCompleted;
  }

  Color _getSpO2Color(String spo2Str) {
    final spo2 = int.tryParse(spo2Str.trim()) ?? 98;
    if (spo2 < 95) return AppTheme.accentRose;
    return AppTheme.statusCompleted;
  }

  Widget _buildVitalBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isConsulting, bool hasAlert) {
    final color = hasAlert ? AppTheme.accentRose : (isConsulting ? AppTheme.statusInConsultation : AppTheme.statusWaiting);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        hasAlert ? 'HIGH BP ALERT ⚠️' : (isConsulting ? 'IN CONSULTATION' : 'WAITING QUEUE'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 24),
            ),
            SizedBox(width: isMobile ? 8 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
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
}
