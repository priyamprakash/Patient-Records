import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'patient_detail_dialog.dart';

class QueueView extends StatefulWidget {
  final VoidCallback? onNavigateToAddPatient;

  const QueueView({super.key, this.onNavigateToAddPatient});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final _repository = ClinicRepository();

  void _showAttendDialog(QueueItem item) {
    final diagnosisCtrl = TextEditingController();
    final prescriptionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Attend Patient: ${item.patientName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.chiefComplaint.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complaint: ${item.chiefComplaint}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: diagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis *',
                    hintText: 'e.g. Viral Fever, Mild Bronchitis',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prescriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    hintText: 'e.g. Tab Paracetamol 500mg TDS',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Advice / Notes',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Fee (₹)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Complete Visit'),
            onPressed: () async {
              final fee = double.tryParse(feeCtrl.text) ?? 500.0;
              await _repository.attendPatient(
                queueItem: item,
                diagnosis: diagnosisCtrl.text.trim(),
                prescription: prescriptionCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
                fee: fee,
              );
              if (mounted && ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.patientName} marked as Attended!'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final queue = _repository.waitingQueue;
        final inConsultationCount = queue.where((q) => q.status == 'inConsultation').length;
        final waitingCount = queue.where((q) => q.status == 'waiting').length;

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
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.secondaryNavy,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 10 : 14,
                      ),
                    ),
                    onPressed: widget.onNavigateToAddPatient,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(isMobile ? '+ Register' : 'Register & Add Patient'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Glass Stat Cards
              Row(
                children: [
                  _buildGlassStatCard('Waiting', '$waitingCount', Icons.hourglass_top, AppTheme.statusWaiting, isMobile),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildGlassStatCard('In Consult', '$inConsultationCount', Icons.medical_services_outlined, AppTheme.statusInConsultation, isMobile),
                  SizedBox(width: isMobile ? 8 : 16),
                  _buildGlassStatCard('Attended', '${_repository.attendedTodayQueue.length}', Icons.check_circle_outline, AppTheme.statusCompleted, isMobile),
                ],
              ),
              const SizedBox(height: 20),

              // Queue List
              queue.isEmpty
                  ? GlassCard(
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: isMobile ? 40 : 60, color: AppTheme.primaryTeal.withValues(alpha: 0.7)),
                            const SizedBox(height: 12),
                            Text(
                              'No patients currently waiting in queue!',
                              style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "+ Register" to issue an instant token.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queue.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isConsulting = item.status == 'inConsultation';

                        return GlassCard(
                          borderColor: isConsulting ? AppTheme.statusInConsultation : Colors.teal.shade100,
                          backgroundColor: isConsulting
                              ? Colors.blue.shade50.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: isConsulting
                                                ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                                                : AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isConsulting ? AppTheme.statusInConsultation : AppTheme.primaryTeal).withValues(alpha: 0.3),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'TOKEN #${item.tokenNumber}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        _buildStatusBadge(isConsulting),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.patientName,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Phone: ${item.patientPhone} • Added: ${dateFormat.format(item.timeAdded)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    if (item.chiefComplaint.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Text(
                                          'Complaint: ${item.chiefComplaint}',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, color: AppTheme.primaryTeal),
                                          onPressed: () {
                                            final patient = _repository.getPatientById(item.patientId);
                                            if (patient != null) {
                                              PatientDetailDialog.show(context, patient);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isConsulting)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.statusInConsultation,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: const StadiumBorder(),
                                            ),
                                            onPressed: () => _repository.updateQueueStatus(item.id, 'inConsultation'),
                                            child: const Text('Start Visit', style: TextStyle(fontSize: 12)),
                                          ),
                                        if (isConsulting)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.statusCompleted,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: const StadiumBorder(),
                                            ),
                                            onPressed: () => _showAttendDialog(item),
                                            child: const Text('Attend Visit', style: TextStyle(fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: isConsulting
                                            ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                                            : AppTheme.primaryGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isConsulting ? AppTheme.statusInConsultation : AppTheme.primaryTeal).withValues(alpha: 0.3),
                                            blurRadius: 8,
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
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70),
                                            ),
                                            Text(
                                              '#${item.tokenNumber}',
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.patientName,
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                                              ),
                                              const SizedBox(width: 12),
                                              _buildStatusBadge(isConsulting),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Phone: ${item.patientPhone}  •  Added: ${dateFormat.format(item.timeAdded)}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                          if (item.chiefComplaint.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Complaint: ${item.chiefComplaint}',
                                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'View Patient History',
                                          icon: const Icon(Icons.info_outline, color: AppTheme.primaryTeal),
                                          onPressed: () {
                                            final patient = _repository.getPatientById(item.patientId);
                                            if (patient != null) {
                                              PatientDetailDialog.show(context, patient);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isConsulting)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusInConsultation),
                                            icon: const Icon(Icons.medical_information, size: 16),
                                            label: const Text('Start Visit'),
                                            onPressed: () => _repository.updateQueueStatus(item.id, 'inConsultation'),
                                          ),
                                        if (isConsulting)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCompleted),
                                            icon: const Icon(Icons.check_circle, size: 16),
                                            label: const Text('Attend Visit'),
                                            onPressed: () => _showAttendDialog(item),
                                          ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildStatusBadge(bool isConsulting) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConsulting ? Colors.blue.shade100 : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConsulting ? Colors.blue.shade300 : Colors.amber.shade300,
        ),
      ),
      child: Text(
        isConsulting ? 'IN CONSULTATION' : 'WAITING QUEUE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isConsulting ? Colors.blue.shade900 : Colors.amber.shade900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: GlassCard(
        padding: EdgeInsets.all(isMobile ? 10 : 16),
        borderColor: color.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 26),
            ),
            SizedBox(width: isMobile ? 8 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 24,
                      fontWeight: FontWeight.w800,
                      color: color,
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
