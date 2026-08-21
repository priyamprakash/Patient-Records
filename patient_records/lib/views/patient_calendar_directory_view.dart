import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'patient_detail_dialog.dart';

class PatientCalendarDirectoryView extends StatefulWidget {
  final Function(Patient)? onGenerateBillForPatient;

  const PatientCalendarDirectoryView({super.key, this.onGenerateBillForPatient});

  @override
  State<PatientCalendarDirectoryView> createState() => _PatientCalendarDirectoryViewState();
}

class _PatientCalendarDirectoryViewState extends State<PatientCalendarDirectoryView> {
  final _repository = ClinicRepository();
  final _searchController = TextEditingController();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  int _tabIndex = 0; // 0 = Calendar View, 1 = Search Directory

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final attendedDates = _repository.getAttendedDates();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Segmented Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Calendar & Directory',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        Text(
                          'Filter by date calendar or search by Phone / Name',
                          style: TextStyle(color: Colors.grey, fontSize: isMobile ? 12 : 14),
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Calendar'),
                        icon: Icon(Icons.calendar_month, size: 16),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Search'),
                        icon: Icon(Icons.search, size: 16),
                      ),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (set) {
                      setState(() {
                        _tabIndex = set.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar Glass Card
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search by Phone Number or Name...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (_) {
                          setState(() {
                            if (_searchController.text.trim().isNotEmpty) {
                              _tabIndex = 1;
                            }
                          });
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content View
              _tabIndex == 0
                  ? _buildCalendarSection(attendedDates, isMobile)
                  : _buildSearchDirectorySection(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection(Set<DateTime> attendedDates, bool isMobile) {
    final selectedVisits = _selectedDay != null
        ? _repository.getAttendedVisitsForDate(_selectedDay!)
        : <VisitRecord>[];

    final dateFormat = DateFormat('MMMM dd, yyyy');

    final calendarCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            final cleanDay = DateTime(day.year, day.month, day.day);
            return attendedDates.contains(cleanDay) ? ['attended'] : [];
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryTeal,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.statusCompleted,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    final visitsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDay == null
                        ? 'Select a date'
                        : 'Attended on ${dateFormat.format(_selectedDay!)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${selectedVisits.length} Visits'),
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            const Divider(height: 16),
            selectedVisits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No consultations on this date.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedVisits.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final visit = selectedVisits[idx];
                      final patient = _repository.getPatientById(visit.patientId);

                      return Card(
                        elevation: 1,
                        color: Colors.grey.shade50,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.statusCompleted,
                            foregroundColor: Colors.white,
                            radius: 18,
                            child: Text(
                              '#${visit.tokenNumber}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            visit.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (patient != null) Text('Phone: ${patient.phone}', style: const TextStyle(fontSize: 12)),
                              if (visit.diagnosis.isNotEmpty)
                                Text(
                                  'Diagnosis: ${visit.diagnosis}',
                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.folder_open, color: AppTheme.primaryTeal),
                            onPressed: () {
                              if (patient != null) {
                                PatientDetailDialog.show(context, patient);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          calendarCard,
          const SizedBox(height: 12),
          visitsCard,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: calendarCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: visitsCard),
        ],
      );
    }
  }

  Widget _buildSearchDirectorySection(bool isMobile) {
    final query = _searchController.text.trim();
    final searchResults = _repository.searchPatients(query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          query.isEmpty
              ? 'All Registered Patients (${searchResults.length})'
              : 'Results for "$query" (${searchResults.length})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        searchResults.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_search, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'No patients matching "$query"',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final patient = searchResults[index];
                  final patientVisits = _repository.getVisitsForPatient(patient.id);

                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                                      child: Text(
                                        patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                                        style: const TextStyle(
                                          fontSize: 16,
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
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Phone: ${patient.phone} • ${patient.gender}, ${patient.age}y',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: const StadiumBorder(),
                                      ),
                                      icon: const Icon(Icons.add_task, size: 14),
                                      label: const Text('Queue', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _showAddToQueueDialog(patient),
                                    ),
                                    const SizedBox(width: 4),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: const StadiumBorder(),
                                      ),
                                      icon: const Icon(Icons.receipt, size: 14),
                                      label: const Text('Bill', style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        if (widget.onGenerateBillForPatient != null) {
                                          widget.onGenerateBillForPatient!(patient);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: const StadiumBorder(),
                                      ),
                                      icon: const Icon(Icons.folder_open, size: 14),
                                      label: const Text('History', style: TextStyle(fontSize: 11)),
                                      onPressed: () => PatientDetailDialog.show(context, patient),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                                  child: Text(
                                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            patient.name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 10),
                                          Chip(
                                            label: Text('${patientVisits.length} Past Visits'),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Phone: ${patient.phone}  •  ${patient.gender}, ${patient.age} yrs',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.add_task, size: 16),
                                      label: const Text('Add to Queue'),
                                      onPressed: () => _showAddToQueueDialog(patient),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt, size: 16),
                                      label: const Text('Create Bill'),
                                      onPressed: () {
                                        if (widget.onGenerateBillForPatient != null) {
                                          widget.onGenerateBillForPatient!(patient);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.folder_open, size: 16),
                                      label: const Text('Full History'),
                                      onPressed: () => PatientDetailDialog.show(context, patient),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _showAddToQueueDialog(Patient patient) {
    final complaintCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add "${patient.name}" to Queue'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: TextField(
          controller: complaintCtrl,
          decoration: const InputDecoration(
            labelText: 'Chief Complaint',
            hintText: 'e.g. Fever',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _repository.addToQueue(patient.id, complaintCtrl.text.trim());
              if (mounted && ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${patient.name} added to today\'s queue!')),
                );
              }
            },
            child: const Text('Add to Queue'),
          ),
        ],
      ),
    );
  }
}
