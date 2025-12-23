import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart' hide ErrorWidget;
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../core/utils/utils.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_providers.dart';
import '../widgets/stats_card.dart';
import '../widgets/medication_timeline.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final todaysLogs = ref.watch(todaysMedicationLogsProvider);
    final overdueMedications = ref.watch(overdueMedicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DoseTime'),
        actions: [
          NotificationBadge(
            count: overdueMedications.length,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.push(AppConstants.remindersRoute),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push(AppConstants.profileRoute),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(todaysMedicationLogsProvider);
            ref.refresh(prescriptionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(user),
                const SizedBox(height: AppConstants.paddingLarge),

                // Overdue Medications Alert
                if (overdueMedications.isNotEmpty) ...[
                  _buildOverdueAlert(overdueMedications),
                  const SizedBox(height: AppConstants.paddingLarge),
                ],

                // Today's Statistics
                _buildStatsSection(dashboardStats),
                const SizedBox(height: AppConstants.paddingLarge),

                // Quick Actions
                const QuickActionsWidget(),
                const SizedBox(height: AppConstants.paddingLarge),

                // Today's Medications Timeline
                todaysLogs.when(
                  data: (logs) => _buildMedicationTimeline(logs),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => app_error.ErrorWidget(
                    message: 'Failed to load today\'s medications',
                    onRetry: () => ref.refresh(todaysMedicationLogsProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.prescriptionsRoute),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildWelcomeSection(AsyncValue<UserModel?> user) {
    return user.when(
      data: (userData) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRoleIcon(userData?.role ?? UserRole.patient),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        userData?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              DateTimeUtils.formatDate(DateTime.now()),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildOverdueAlert(List<dynamic> overdueMedications) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overdue Medications',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: AppConstants.largeFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${overdueMedications.length} medication${overdueMedications.length == 1 ? '' : 's'} overdue',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppConstants.remindersRoute),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Today\'s Progress'),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Adherence',
                value: '${stats.adherenceRate}%',
                icon: Icons.trending_up,
                color: stats.adherenceRate >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: StatsCard(
                title: 'Taken',
                value: '${stats.taken}/${stats.totalToday}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Upcoming',
                value: '${stats.upcoming}',
                icon: Icons.schedule,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: StatsCard(
                title: 'Overdue',
                value: '${stats.overdue}',
                icon: Icons.warning,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationTimeline(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.medication,
        title: 'No medications today',
        message: 'You don\'t have any medications scheduled for today.',
        actionText: 'Add Medication',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Today\'s Schedule',
          actionText: 'View Calendar',
          onActionPressed: () => context.push('/calendar'),
        ),
        MedicationTimeline(logs: logs),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPage,
      onTap: (index) {
        setState(() {
          _currentPage = index;
        });
        
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            context.push(AppConstants.prescriptionsRoute);
            break;
          case 2:
            context.push(AppConstants.remindersRoute);
            break;
          case 3:
            context.push(AppConstants.profileRoute);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication),
          label: 'Medications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Reminders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return Icons.person;
      case UserRole.doctor:
        return Icons.medical_services;
      case UserRole.caretaker:
        return Icons.favorite;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}

