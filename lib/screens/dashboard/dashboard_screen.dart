import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:office_control/models/attendance_model.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/models/notification_model.dart';
import 'package:office_control/providers/auth_provider.dart';
import 'package:office_control/providers/task_provider.dart';
import 'package:office_control/providers/attendance_provider.dart';
import 'package:office_control/providers/notification_provider.dart';
import 'package:office_control/screens/tasks/create_task_screen.dart';
import 'package:office_control/screens/profile/profile_screen.dart';
import 'package:office_control/screens/settings/settings_screen.dart';
import 'package:office_control/services/door_access_service.dart';
import 'package:office_control/services/location_service.dart';
import 'package:office_control/utils/app_theme.dart';
import 'package:office_control/widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      context.read<TaskProvider>().setUserId(authProvider.user!.uid);
      context.read<AttendanceProvider>().initialize(authProvider.user!.uid);
      context.read<NotificationProvider>().setUserId(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardHome(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    final user = authProvider.user;
    final firstName = user?.firstName ?? 'User';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const Spacer(),
                // Notification Button with Badge
                _NotificationButton(
                  unreadCount: notificationProvider.unreadCount,
                  onPressed: () => _showNotificationsSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome, $firstName',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Door Access Card
            _DoorAccessCard(attendanceProvider: attendanceProvider),
            const SizedBox(height: 24),

            // Today's Summary
            Text(
              "Today's Summary",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Hours\nWorked',
                    value: attendanceProvider.formattedTodayHours,
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Latest Activity',
                    value: _formatLatestActivity(
                      attendanceProvider.latestActivity,
                    ),
                    icon: Icons.history,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Timeline
            _TimelineSection(records: attendanceProvider.todayRecords),
            const SizedBox(height: 24),

            // My Tasks
            _TasksSection(
              tasks: taskProvider.tasks,
              onStartTask: (taskId) => taskProvider.startTask(taskId),
              onCompleteTask: (taskId) => taskProvider.completeTask(taskId),
              onDeleteTask: (taskId) => taskProvider.deleteTask(taskId),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLatestActivity(AttendanceRecord? record) {
    if (record == null) return 'No activity';
    final time = DateFormat('h:mm a').format(record.timestamp);
    return '${record.isEntry ? 'Entered' : 'Left'} at $time';
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NotificationsSheet(),
    );
  }
}

// ==================== NOTIFICATION WIDGETS ====================

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            unreadCount > 0
                ? Icons.notifications_active
                : Icons.notifications_outlined,
          ),
          color: unreadCount > 0 ? AppColors.accent : AppColors.textSecondary,
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bildirimler',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (notificationProvider.hasUnread)
                    TextButton(
                      onPressed: () => notificationProvider.markAllAsRead(),
                      child: const Text('Tümünü Okundu İşaretle'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notifications List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bildirim yok',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationItem(
                          notification: notification,
                          onTap: () {
                            notificationProvider.markAsRead(notification.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    final isRead = notification.isReadByUser(userId);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isRead ? null : AppColors.accent.withValues(alpha: 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getCategoryColor(
                  notification.category,
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(notification.category),
                color: _getCategoryColor(notification.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            notification.category,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.categoryLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(notification.category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (notification.priority == NotificationPriority.high ||
                          notification.priority ==
                              NotificationPriority.critical)
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: AppColors.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.general:
        return AppColors.info;
      case NotificationCategory.announcement:
        return AppColors.accent;
      case NotificationCategory.task:
        return AppColors.taskInProgress;
      case NotificationCategory.meeting:
        return Colors.purple;
      case NotificationCategory.urgent:
        return AppColors.error;
      case NotificationCategory.reminder:
        return AppColors.warning;
      case NotificationCategory.system:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.general:
        return Icons.info_outline;
      case NotificationCategory.announcement:
        return Icons.campaign_outlined;
      case NotificationCategory.task:
        return Icons.task_outlined;
      case NotificationCategory.meeting:
        return Icons.groups_outlined;
      case NotificationCategory.urgent:
        return Icons.warning_amber_outlined;
      case NotificationCategory.reminder:
        return Icons.alarm_outlined;
      case NotificationCategory.system:
        return Icons.settings_outlined;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Şimdi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}

// ==================== DOOR ACCESS WIDGETS ====================

class _DoorAccessCard extends StatefulWidget {
  final AttendanceProvider attendanceProvider;

  const _DoorAccessCard({required this.attendanceProvider});

  @override
  State<_DoorAccessCard> createState() => _DoorAccessCardState();
}

class _DoorAccessCardState extends State<_DoorAccessCard> {
  final LocationService _locationService = LocationService();
  bool _hasLocationPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  /// Only checks permission status - doesn't request (safe to call on init)
  Future<void> _checkPermissionStatus() async {
    try {
      final hasPermission = await _locationService.checkPermissionStatus();
      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
          _checkingPermission = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
          _checkingPermission = false;
        });
      }
    }
  }

  /// Requests permission when user wants to use door access
  Future<bool> _requestPermission() async {
    try {
      final (hasPermission, isDeniedForever) = await _locationService
          .checkAndRequestPermissionWithStatus();

      if (mounted) {
        setState(() => _hasLocationPermission = hasPermission);
      }

      // Eğer izin kalıcı olarak reddedilmişse, ayarlara yönlendir
      if (!hasPermission && isDeniedForever && mounted) {
        _showDeniedForeverDialog();
      }

      return hasPermission;
    } catch (e) {
      return false;
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Konum İzni Gerekli'),
          ],
        ),
        content: const Text(
          'Kapı erişimi için konumunuza ihtiyacımız var. Bu sayede sadece ofise yakın olduğunuzda kapıyı açabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _requestPermission();
            },
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  void _showDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Ayarlara Git'),
          ],
        ),
        content: const Text(
          'Konum izni kalıcı olarak reddedilmiş. Lütfen ayarlardan konum iznini manuel olarak açın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Geolocator.openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Door Access',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!_checkingPermission && !_hasLocationPermission)
                GestureDetector(
                  onTap: _showLocationPermissionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Konum İzni',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Unlock office doors with your phone',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DoorButton(
                  label: 'Giriş',
                  icon: Icons.login,
                  isLoading: widget.attendanceProvider.isDoorOperating,
                  onPressed: () => _handleDoorAccess(AttendanceType.entry),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DoorButton(
                  label: 'Çıkış',
                  icon: Icons.logout,
                  isLoading: widget.attendanceProvider.isDoorOperating,
                  isPrimary: false,
                  onPressed: () => _handleDoorAccess(AttendanceType.exit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDoorAccess(AttendanceType type) async {
    // First check location permission, request if not granted
    if (!_hasLocationPermission) {
      final granted = await _requestPermission();
      if (!granted) {
        _showLocationPermissionDialog();
        return;
      }
    }

    final result = await widget.attendanceProvider.openDoor(type);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.status == DoorAccessStatus.success
              ? AppColors.success
              : AppColors.error,
        ),
      );
    }
  }
}

class _DoorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _DoorButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.isPrimary = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.accent : AppColors.surfaceLight,
        foregroundColor: isPrimary
            ? AppColors.background
            : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
    );
  }
}

// ==================== SUMMARY WIDGETS ====================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

// ==================== TIMELINE WIDGETS ====================

class _TimelineSection extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _TimelineSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Timeline",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // TODO: View all
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: records.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No entries today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: records
                      .take(3)
                      .map((record) => _TimelineItem(record: record))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final AttendanceRecord record;

  const _TimelineItem({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.isEntry
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              record.isEntry ? Icons.login : Icons.logout,
              color: record.isEntry ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.isEntry ? 'Entered' : 'Left'} ${record.location}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  DateFormat('h:mm a').format(record.timestamp),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TASK WIDGETS ====================

class _TasksSection extends StatelessWidget {
  final List<TaskModel> tasks;
  final Future<bool> Function(String) onStartTask;
  final Future<bool> Function(String) onCompleteTask;
  final Future<bool> Function(String) onDeleteTask;

  const _TasksSection({
    required this.tasks,
    required this.onStartTask,
    required this.onCompleteTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Tasks', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                // TODO: Filter
              },
              child: const Text('Filter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to create a new task',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...tasks
              .take(5)
              .map(
                (task) => _TaskItem(
                  task: task,
                  onStartTask: onStartTask,
                  onCompleteTask: onCompleteTask,
                  onDeleteTask: onDeleteTask,
                ),
              ),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final TaskModel task;
  final Future<bool> Function(String) onStartTask;
  final Future<bool> Function(String) onCompleteTask;
  final Future<bool> Function(String) onDeleteTask;

  const _TaskItem({
    required this.task,
    required this.onStartTask,
    required this.onCompleteTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Difficulty Indicator
          _DifficultyIndicator(difficulty: task.difficulty),
          const SizedBox(width: 12),
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusBadge.taskStatus(task.status),
                    const SizedBox(width: 8),
                    StatusBadge.difficulty(task.difficulty),
                  ],
                ),
                if (task.status == TaskStatus.done &&
                    task.durationMinutes != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.formattedDuration,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            itemBuilder: (context) => [
              if (task.status == TaskStatus.todo)
                const PopupMenuItem(
                  value: 'start',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('Başlat'),
                    ],
                  ),
                ),
              if (task.status == TaskStatus.inProgress)
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('Tamamla'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'start':
                  await onStartTask(task.id);
                  break;
                case 'complete':
                  await onCompleteTask(task.id);
                  break;
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTaskScreen(taskToEdit: task),
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text(
          '"${task.title}" görevini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteTask(task.id);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _DifficultyIndicator extends StatelessWidget {
  final TaskDifficulty difficulty;

  const _DifficultyIndicator({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Icon(_getIcon(), color: _getColor(), size: 22)),
    );
  }

  Color _getColor() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return AppColors.difficultyEasy;
      case TaskDifficulty.medium:
        return AppColors.difficultyMedium;
      case TaskDifficulty.hard:
        return AppColors.difficultyHard;
      case TaskDifficulty.veryHard:
        return AppColors.difficultyVeryHard;
    }
  }

  IconData _getIcon() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.sentiment_satisfied_alt;
      case TaskDifficulty.medium:
        return Icons.sentiment_neutral;
      case TaskDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case TaskDifficulty.veryHard:
        return Icons.whatshot;
    }
  }
}
