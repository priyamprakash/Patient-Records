import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'add_patient_view.dart';
import 'attended_today_view.dart';
import 'bill_generation_view.dart';
import 'patient_calendar_directory_view.dart';
import 'queue_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  Patient? _preselectedBillingPatient;
  final _repository = ClinicRepository();

  void _navigateToTab(int index, {Patient? patientForBilling}) {
    setState(() {
      _selectedIndex = index;
      if (patientForBilling != null) {
        _preselectedBillingPatient = patientForBilling;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        if (!_repository.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryTeal),
                  SizedBox(height: 16),
                  Text('Loading Clinic System...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        final waitingCount = _repository.waitingQueue.length;
        final attendedTodayCount = _repository.attendedTodayQueue.length;
        final revenueToday = _repository.todayRevenue;

        // Active screens
        final screens = [
          QueueView(onNavigateToAddPatient: () => _navigateToTab(2)),
          AttendedTodayView(
            onGenerateBillForPatient: (patient) => _navigateToTab(4, patientForBilling: patient),
          ),
          AddPatientView(onSuccessAdded: () => _navigateToTab(0)),
          PatientCalendarDirectoryView(
            onGenerateBillForPatient: (patient) => _navigateToTab(4, patientForBilling: patient),
          ),
          BillGenerationView(preselectedPatient: _preselectedBillingPatient),
        ];

        return Scaffold(
          // Clean, Full-Width Edge-to-Edge Glass Top AppBar
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.secondaryNavy.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Clinic Logo Badge
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isMobile ? 'MEDICARE' : 'MEDICARE CLINIC CARE',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppTheme.secondaryNavy,
                          ),
                        ),
                        const Spacer(),

                        // Live Date Capsule (Desktop)
                        if (!isMobile)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryTeal),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Reset Sample DB Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                            side: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.dataset, size: 16),
                          label: Text(
                            isMobile ? 'Reset DB' : 'Reset Sample DB',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            await _repository.resetToFakeDatabase();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fake database re-seeded with sample data!'),
                                  backgroundColor: AppTheme.primaryTeal,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body: Desktop gets Sidebar + Screen; Mobile gets Screen + Clean Floating Bottom Dock
          body: isMobile
              ? Column(
                  children: [
                    // Mobile Glass Quick Header Stats Bar
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        backgroundColor: Colors.white.withValues(alpha: 0.95),
                        borderRadius: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMobileStatBadge('Waiting', '$waitingCount', AppTheme.statusWaiting),
                            Container(width: 1, height: 16, color: Colors.grey.shade300),
                            _buildMobileStatBadge('Attended', '$attendedTodayCount', AppTheme.statusCompleted),
                            Container(width: 1, height: 16, color: Colors.grey.shade300),
                            _buildMobileStatBadge('Revenue', '₹${revenueToday.toStringAsFixed(0)}', AppTheme.accentCyan),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: screens[_selectedIndex],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Desktop Sidebar Navigation
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() => _selectedIndex = index);
                      },
                      extended: true,
                      minExtendedWidth: 210,
                      backgroundColor: AppTheme.secondaryNavy,
                      unselectedIconTheme: const IconThemeData(color: Colors.white60),
                      selectedIconTheme: const IconThemeData(color: Colors.tealAccent, size: 24),
                      unselectedLabelTextStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                      selectedLabelTextStyle: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: Badge(
                            label: Text('$waitingCount'),
                            isLabelVisible: waitingCount > 0,
                            child: const Icon(Icons.hourglass_top),
                          ),
                          selectedIcon: const Icon(Icons.hourglass_bottom),
                          label: const Text('Waiting Queue'),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.check_circle_outline),
                          selectedIcon: const Icon(Icons.check_circle),
                          label: const Text('Attended Today'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.person_add_outlined),
                          selectedIcon: Icon(Icons.person_add),
                          label: Text('Add Patient'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month),
                          label: Text('All Patients'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.receipt_long_outlined),
                          selectedIcon: Icon(Icons.receipt_long),
                          label: Text('Bill Generator'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: screens[_selectedIndex],
                      ),
                    ),
                  ],
                ),

          // Clean Floating Dock without any extra background container box
          bottomNavigationBar: isMobile
              ? _buildCleanFloatingDock(waitingCount)
              : null,
        );
      },
    );
  }

  Widget _buildCleanFloatingDock(int waitingCount) {
    final items = [
      {'icon': Icons.hourglass_top, 'activeIcon': Icons.hourglass_bottom, 'label': 'Queue', 'badge': waitingCount},
      {'icon': Icons.check_circle_outline, 'activeIcon': Icons.check_circle, 'label': 'Attended', 'badge': 0},
      {'icon': Icons.person_add_outlined, 'activeIcon': Icons.person_add, 'label': 'Add', 'badge': 0},
      {'icon': Icons.calendar_month_outlined, 'activeIcon': Icons.calendar_month, 'label': 'Directory', 'badge': 0},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long, 'label': 'Billing', 'badge': 0},
    ];

    return SafeArea(
      child: Container(
        color: Colors.transparent, // Zero extra background box behind the dock
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = items[index];
            final badgeCount = item['badge'] as int;

            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryTeal
                        : AppTheme.secondaryNavy.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.primaryTeal.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      label: Text('$badgeCount'),
                      isLabelVisible: badgeCount > 0,
                      backgroundColor: AppTheme.statusWaiting,
                      textColor: Colors.white,
                      child: Icon(
                        isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                        color: isSelected ? Colors.white : AppTheme.secondaryNavy,
                        size: isSelected ? 20 : 18,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMobileStatBadge(String title, String val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$title: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        Text(
          val,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
