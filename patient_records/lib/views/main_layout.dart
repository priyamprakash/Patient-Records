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
          // Clean, Full-Width Ultra-Modern App Bar
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Clinic Logo Badge
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMobile ? 'MEDICARE' : 'MEDICARE CLINIC EMR',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              'Smart Clinical Practice System',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Live Date & System Pill (Desktop)
                        if (!isMobile) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.statusCompleted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Reset Sample DB Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryDark,
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryTeal),
                          label: Text(
                            isMobile ? 'Reset DB' : 'Reset Sample DB',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () async {
                            await _repository.resetToFakeDatabase();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Database reset with sample patients, queue, and medicines!'),
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

          // Body: Desktop gets Sidebar + Screen; Mobile gets Screen + Floating Bottom Dock
          body: isMobile
              ? Column(
                  children: [
                    // Mobile Header Stats Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.white,
                        borderRadius: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMobileStatBadge('Waiting', '$waitingCount', AppTheme.statusWaiting),
                            Container(width: 1, height: 18, color: const Color(0xFFE2E8F0)),
                            _buildMobileStatBadge('Attended', '$attendedTodayCount', AppTheme.statusCompleted),
                            Container(width: 1, height: 18, color: const Color(0xFFE2E8F0)),
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
                    // Ultra-Modern Desktop Navigation Rail
                    Container(
                      width: 230,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDark,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Section Header Label
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'CLINIC DASHBOARD',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Navigation Items
                          _buildDesktopNavItem(
                            index: 0,
                            icon: Icons.hourglass_top_rounded,
                            activeIcon: Icons.hourglass_bottom_rounded,
                            label: 'Waiting Queue',
                            badgeCount: waitingCount,
                            badgeColor: AppTheme.statusWaiting,
                          ),
                          _buildDesktopNavItem(
                            index: 1,
                            icon: Icons.check_circle_outline_rounded,
                            activeIcon: Icons.check_circle_rounded,
                            label: 'Attended Today',
                            badgeCount: attendedTodayCount,
                            badgeColor: AppTheme.statusCompleted,
                          ),
                          _buildDesktopNavItem(
                            index: 2,
                            icon: Icons.person_add_alt_outlined,
                            activeIcon: Icons.person_add_alt_1_rounded,
                            label: 'Register Patient',
                          ),
                          _buildDesktopNavItem(
                            index: 3,
                            icon: Icons.folder_shared_outlined,
                            activeIcon: Icons.folder_shared_rounded,
                            label: 'Patient Directory',
                          ),
                          _buildDesktopNavItem(
                            index: 4,
                            icon: Icons.receipt_long_outlined,
                            activeIcon: Icons.receipt_long_rounded,
                            label: 'Bill Generator',
                          ),

                          const Spacer(),

                          // Quick Doctor Profile Card at Bottom
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primaryTeal,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Dr. Sharma',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'General Physician',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: screens[_selectedIndex],
                      ),
                    ),
                  ],
                ),

          bottomNavigationBar: isMobile
              ? _buildCleanFloatingDock(waitingCount)
              : null,
        );
      },
    );
  }

  Widget _buildDesktopNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : (badgeColor ?? AppTheme.statusWaiting),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryDark : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanFloatingDock(int waitingCount) {
    final items = [
      {'icon': Icons.hourglass_top_rounded, 'activeIcon': Icons.hourglass_bottom_rounded, 'label': 'Queue', 'badge': waitingCount},
      {'icon': Icons.check_circle_outline_rounded, 'activeIcon': Icons.check_circle_rounded, 'label': 'Attended', 'badge': 0},
      {'icon': Icons.person_add_outlined, 'activeIcon': Icons.person_add_rounded, 'label': 'Add', 'badge': 0},
      {'icon': Icons.folder_shared_outlined, 'activeIcon': Icons.folder_shared_rounded, 'label': 'Directory', 'badge': 0},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long_rounded, 'label': 'Billing', 'badge': 0},
    ];

    return SafeArea(
      child: Container(
        color: Colors.transparent,
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
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0),
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
                        color: isSelected ? Colors.white : AppTheme.primaryDark,
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
