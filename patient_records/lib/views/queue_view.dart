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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          "Today's Live Waiting Queue",
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppTheme.secondaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shadowColor: AppTheme.primaryTeal.withValues(alpha: 0.4),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                    onPressed: widget.onNavigateToAddPatient,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(isMobile ? '+ Register' : 'Register & Add Patient', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Summary Glass Stat Cards
              Row(
                children: [
                  _buildGlassStatCard('Waiting', '$waitingCount', Icons.hourglass_top_rounded, AppTheme.statusWaiting, AppTheme.goldGradient, isMobile, isDark),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildGlassStatCard('In Consult', '$inConsultationCount', Icons.medical_services_rounded, AppTheme.statusInConsultation, AppTheme.accentGradient, isMobile, isDark),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildGlassStatCard('Attended', '${_repository.attendedTodayQueue.length}', Icons.check_circle_rounded, AppTheme.statusCompleted, AppTheme.emeraldGradient, isMobile, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Search & Filter Bar
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search queue by name, phone, or token #...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal),
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
                    // Quick Filter Chips
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
                              size: isMobile ? 40 : 60,
                              color: AppTheme.primaryTeal.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No patients match your search criteria.'
                                  : 'No patients currently waiting in queue!',
                              style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "+ Register" to issue an instant token.',
                              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
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

                        return InkWell(
                          onTap: () => _openPrescriptionConsultation(item),
                          borderRadius: BorderRadius.circular(20),
                          child: GlassCard(
                            borderColor: hasAlert
                                ? AppTheme.accentRose
                                : (isConsulting ? AppTheme.statusInConsultation : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            backgroundColor: isConsulting
                                ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : Colors.blue.shade50.withValues(alpha: 0.9))
                                : null,
                            padding: EdgeInsets.all(isMobile ? 14 : 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Token Circle
                                    Container(
                                      width: isMobile ? 52 : 62,
                                      height: isMobile ? 52 : 62,
                                      decoration: BoxDecoration(
                                        gradient: isConsulting
                                            ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                                            : (hasAlert ? AppTheme.goldGradient : AppTheme.primaryGradient),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isConsulting
                                                    ? AppTheme.statusInConsultation
                                                    : (hasAlert ? AppTheme.accentRose : AppTheme.primaryTeal))
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'TOKEN',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5),
                                            ),
                                            Text(
                                              '#${item.tokenNumber}',
                                              style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Patient Main Information
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  item.patientName,
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 16 : 19,
                                                    fontWeight: FontWeight.w800,
                                                    color: isDark ? Colors.white : AppTheme.secondaryNavy,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatusBadge(isConsulting, hasAlert),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '📞 ${item.patientPhone}   •   ⌛ Added: ${dateFormat.format(item.timeAdded)}',
                                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Buttons (Desktop)
                                    if (!isMobile) ...[
                                      IconButton(
                                        tooltip: 'View Patient Record & History',
                                        icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          shape: const StadiumBorder(),
                                        ),
                                        icon: const Icon(Icons.medical_services_rounded, size: 16),
                                        label: Text(isConsulting ? 'Attend & Prescribe' : 'Start Consultation'),
                                        onPressed: () => _openPrescriptionConsultation(item),
                                      ),
                                    ],
                                  ],
                                ),

                                // Chief Complaint Banner
                                if (item.chiefComplaint.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isDark ? const Color(0xFFB45309) : Colors.amber.shade200),
                                    ),
                                    child: Text(
                                      '📋 Chief Complaint: ${item.chiefComplaint}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],

                                // Detailed Color-Coded Vitals Pills Row
                                if (vitals != null && !vitals.isEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (vitals.bp.isNotEmpty)
                                        _buildVitalBadge(
                                          'BP',
                                          vitals.bp,
                                          _getBPColor(vitals.bp),
                                          Icons.speed_rounded,
                                        ),
                                      if (vitals.pulse.isNotEmpty)
                                        _buildVitalBadge(
                                          'Pulse',
                                          '${vitals.pulse} bpm',
                                          _getPulseColor(vitals.pulse),
                                          Icons.favorite_rounded,
                                        ),
                                      if (vitals.temperature.isNotEmpty)
                                        _buildVitalBadge(
                                          'Temp',
                                          '${vitals.temperature}°F',
                                          _getTempColor(vitals.temperature),
                                          Icons.thermostat_rounded,
                                        ),
                                      if (vitals.spo2.isNotEmpty)
                                        _buildVitalBadge(
                                          'SpO2',
                                          '${vitals.spo2}%',
                                          _getSpO2Color(vitals.spo2),
                                          Icons.air_rounded,
                                        ),
                                      if (vitals.weight.isNotEmpty)
                                        _buildVitalBadge(
                                          'Weight',
                                          '${vitals.weight} kg',
                                          AppTheme.primaryTeal,
                                          Icons.monitor_weight_rounded,
                                        ),
                                    ],
                                  ),
                                ],

                                // Mobile Action Buttons
                                if (isMobile) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: const StadiumBorder(),
                                        ),
                                        onPressed: () => _openPrescriptionConsultation(item),
                                        icon: const Icon(Icons.medical_services_rounded, size: 16),
                                        label: Text(isConsulting ? 'Prescribe & Attend' : 'Start Prescription', style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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
      selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppTheme.primaryTeal : null,
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

  Widget _buildVitalBadge(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isConsulting, bool hasAlert) {
    final color = hasAlert ? AppTheme.accentRose : (isConsulting ? AppTheme.statusInConsultation : AppTheme.statusWaiting);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        hasAlert ? 'HIGH BP ALERT ⚠️' : (isConsulting ? 'IN CONSULTATION' : 'WAITING QUEUE'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color, LinearGradient gradient, bool isMobile, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: isMobile ? 22 : 28),
            ),
            SizedBox(width: isMobile ? 10 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.primaryDark,
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
