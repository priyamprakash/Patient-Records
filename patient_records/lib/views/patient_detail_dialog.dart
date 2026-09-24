import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';

class PatientDetailDialog extends StatelessWidget {
  final Patient patient;

  const PatientDetailDialog({super.key, required this.patient});

  static void show(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => PatientDetailDialog(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ClinicRepository();
    final visits = repo.getVisitsForPatient(patient.id);
    final bills = repo.getBillsForPatient(patient.id);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? mediaQuery.size.width * 0.95 : 700,
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 20 : 26,
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${patient.gender}, ${patient.age} yrs • Phone: ${patient.phone}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Patient Info & Medical History
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(patient.address.isNotEmpty ? patient.address : 'Not provided', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                        const SizedBox(height: 6),
                        const Text('Medical History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(patient.medicalHistory.isNotEmpty ? patient.medicalHistory : 'None recorded', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(patient.address.isNotEmpty ? patient.address : 'Not provided', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Medical History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(patient.medicalHistory.isNotEmpty ? patient.medicalHistory : 'None recorded', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Tabs / Section Lists
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppTheme.primaryTeal,
                      indicatorColor: AppTheme.primaryTeal,
                      labelStyle: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(text: 'Visits (${visits.length})'),
                        Tab(text: 'Bills (${bills.length})'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Visits List
                          visits.isEmpty
                              ? const Center(child: Text('No past visits found.'))
                              : ListView.separated(
                                  itemCount: visits.length,
                                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, index) {
                                    final v = visits[index];
                                    return Card(
                                      elevation: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  dateFormat.format(v.date),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryTeal,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text('#${v.tokenNumber}'),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ],
                                            ),
                                            if (v.vitals != null && !v.vitals!.isEmpty) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Vitals: ${v.vitals!.summaryText}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                                ),
                                              ),
                                            ],
                                            if (v.diagnosis.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text('Diagnosis: ${v.diagnosis}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                            ],
                                            if (v.medicines.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              const Text('Prescribed Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(height: 4),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: v.medicines.map((m) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                                                    child: Text(
                                                      '• ${m.displayText}',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ] else if (v.prescription.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Prescription: ${v.prescription}', style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          // Bills List
                          bills.isEmpty
                              ? const Center(child: Text('No bills found.'))
                              : ListView.separated(
                                  itemCount: bills.length,
                                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, index) {
                                    final b = bills[index];
                                    return Card(
                                      elevation: 1,
                                      child: ListTile(
                                        dense: true,
                                        title: Text('Invoice #${b.billNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        subtitle: Text('${DateFormat('MMM dd, yyyy').format(b.date)} • ${b.paymentMethod}', style: const TextStyle(fontSize: 11)),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹${b.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: b.paymentStatus == 'Paid' ? Colors.green.shade100 : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                b.paymentStatus,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: b.paymentStatus == 'Paid' ? Colors.green.shade800 : Colors.red.shade800),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
      ),
    );
  }
}
