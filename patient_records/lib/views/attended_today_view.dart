import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'patient_detail_dialog.dart';

class AttendedTodayView extends StatelessWidget {
  final Function(Patient)? onGenerateBillForPatient;

  const AttendedTodayView({super.key, this.onGenerateBillForPatient});

  @override
  Widget build(BuildContext context) {
    final repository = ClinicRepository();
    final timeFormat = DateFormat('hh:mm a');
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final attendedVisits = repository.attendedTodayVisits;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Attended Today Patients",
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondaryNavy,
                    ),
                  ),
                  Text(
                    'Consultations completed on ${DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now())}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Glass Metric Cards
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      borderColor: AppTheme.statusCompleted.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: AppTheme.statusCompleted.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.people_outline, color: AppTheme.statusCompleted, size: isMobile ? 22 : 30),
                          ),
                          SizedBox(width: isMobile ? 8 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Attended Today', style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                Text(
                                  '${attendedVisits.length}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 18 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.statusCompleted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      borderColor: AppTheme.accentCyan.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt_long, color: AppTheme.accentCyan, size: isMobile ? 22 : 30),
                          ),
                          SizedBox(width: isMobile ? 8 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today Fees', style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                Text(
                                  '₹${repository.todayRevenue.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 18 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Attended Patients List
              attendedVisits.isEmpty
                  ? GlassCard(
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox, size: isMobile ? 40 : 50, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No consultations completed yet today.',
                              style: TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attendedVisits.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final visit = attendedVisits[index];
                        final patient = repository.getPatientById(visit.patientId);

                        return GlassCard(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.statusCompleted.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '#${visit.tokenNumber}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.statusCompleted),
                                          ),
                                        ),
                                        Text('Attended at ${timeFormat.format(visit.date)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(visit.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy)),
                                    if (patient != null)
                                      Text('Phone: ${patient.phone} • ${patient.gender}, ${patient.age}y', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    if (visit.diagnosis.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Diagnosis: ${visit.diagnosis}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Fee: ₹${visit.fee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal)),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                shape: const StadiumBorder(),
                                              ),
                                              onPressed: () {
                                                if (patient != null) PatientDetailDialog.show(context, patient);
                                              },
                                              child: const Text('Profile', style: TextStyle(fontSize: 11)),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                shape: const StadiumBorder(),
                                              ),
                                              onPressed: () {
                                                if (patient != null && onGenerateBillForPatient != null) {
                                                  onGenerateBillForPatient!(patient);
                                                }
                                              },
                                              child: const Text('Create Bill', style: TextStyle(fontSize: 11)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusCompleted.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#${visit.tokenNumber}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.statusCompleted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                visit.patientName,
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryNavy),
                                              ),
                                              Text(
                                                'Attended at ${timeFormat.format(visit.date)}',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          if (patient != null) ...[
                                            Text(
                                              'Phone: ${patient.phone} • ${patient.gender}, ${patient.age} yrs',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          if (visit.diagnosis.isNotEmpty) ...[
                                            Text(
                                              'Diagnosis: ${visit.diagnosis}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Fee: ₹${visit.fee.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.person, size: 16),
                                              label: const Text('Profile'),
                                              onPressed: () {
                                                if (patient != null) PatientDetailDialog.show(context, patient);
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.receipt, size: 16),
                                              label: const Text('Create Bill'),
                                              onPressed: () {
                                                if (patient != null && onGenerateBillForPatient != null) {
                                                  onGenerateBillForPatient!(patient);
                                                }
                                              },
                                            ),
                                          ],
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
}
