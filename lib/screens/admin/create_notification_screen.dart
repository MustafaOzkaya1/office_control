import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_control/models/notification_model.dart';
import 'package:office_control/models/user_model.dart';
import 'package:office_control/providers/auth_provider.dart';
import 'package:office_control/providers/notification_provider.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/utils/app_theme.dart';
import 'package:office_control/widgets/custom_text_field.dart';
import 'package:office_control/widgets/custom_button.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _dbService = DatabaseService();

  NotificationCategory _selectedCategory = NotificationCategory.general;
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  bool _sendToAll = true;
  List<String> _selectedUserIds = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dbService.getAllUsers();
    setState(() {
      _allUsers = users.where((u) => u.role != UserRole.admin).toList();
      _isLoadingUsers = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final success = await notificationProvider.createNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      createdBy: authProvider.user?.uid ?? '',
      expiresAt: _expiresAt,
      targetUserIds: _sendToAll ? null : _selectedUserIds,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim oluşturuldu!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notificationProvider.error ?? 'Bir hata oluştu'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _expiresAt = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              Text(
                'Kategori',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _CategorySelector(
                selected: _selectedCategory,
                onChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 24),

              // Title
              CustomTextField(
                controller: _titleController,
                label: 'Başlık',
                hint: 'Bildirim başlığı',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Message
              CustomTextField(
                controller: _messageController,
                label: 'Mesaj',
                hint: 'Bildirim içeriği...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mesaj gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Priority
              Text(
                'Öncelik',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _PrioritySelector(
                selected: _selectedPriority,
                onChanged: (priority) {
                  setState(() => _selectedPriority = priority);
                },
              ),
              const SizedBox(height: 24),

              // Expiry Date
              Text(
                'Son Geçerlilik Tarihi (Opsiyonel)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectExpiryDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _expiresAt != null
                            ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                            : 'Tarih seçin (opsiyonel)',
                        style: TextStyle(
                          color: _expiresAt != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _expiresAt = null),
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Target Users
              Text(
                'Alıcılar',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Send to all toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tüm çalışanlara gönder',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Switch(
                      value: _sendToAll,
                      onChanged: (value) {
                        setState(() {
                          _sendToAll = value;
                          if (value) _selectedUserIds.clear();
                        });
                      },
                      activeColor: AppColors.accent,
                    ),
                  ],
                ),
              ),

              // User selection (if not sending to all)
              if (!_sendToAll) ...[
                const SizedBox(height: 16),
                if (_isLoadingUsers)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: _allUsers.map((user) {
                        final isSelected = _selectedUserIds.contains(user.uid);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.uid);
                              } else {
                                _selectedUserIds.remove(user.uid);
                              }
                            });
                          },
                          title: Text(user.fullName),
                          subtitle: Text(
                            user.position,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              user.firstName.isNotEmpty
                                  ? user.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: AppColors.accent),
                            ),
                          ),
                          activeColor: AppColors.accent,
                          checkColor: AppColors.background,
                        );
                      }).toList(),
                    ),
                  ),
                if (!_sendToAll && _selectedUserIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'En az bir kullanıcı seçin',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Bildirim Gönder',
                isLoading: _isLoading,
                icon: Icons.send,
                onPressed: (!_sendToAll && _selectedUserIds.isEmpty)
                    ? null
                    : _createNotification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final NotificationCategory selected;
  final ValueChanged<NotificationCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NotificationCategory.values.map((category) {
        final isSelected = selected == category;
        return GestureDetector(
          onTap: () => onChanged(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getCategoryColor(category).withValues(alpha: 0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _getCategoryColor(category) : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected
                      ? _getCategoryColor(category)
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _getCategoryLabel(category),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? _getCategoryColor(category)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  String _getCategoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.general:
        return 'Genel';
      case NotificationCategory.announcement:
        return 'Duyuru';
      case NotificationCategory.task:
        return 'Görev';
      case NotificationCategory.meeting:
        return 'Toplantı';
      case NotificationCategory.urgent:
        return 'Acil';
      case NotificationCategory.reminder:
        return 'Hatırlatma';
      case NotificationCategory.system:
        return 'Sistem';
    }
  }
}

class _PrioritySelector extends StatelessWidget {
  final NotificationPriority selected;
  final ValueChanged<NotificationPriority> onChanged;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: NotificationPriority.values.map((priority) {
        final isSelected = selected == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: priority != NotificationPriority.critical ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getPriorityColor(priority).withValues(alpha: 0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? _getPriorityColor(priority) : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getPriorityIcon(priority),
                    size: 20,
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPriorityLabel(priority),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return AppColors.textSecondary;
      case NotificationPriority.normal:
        return AppColors.info;
      case NotificationPriority.high:
        return AppColors.warning;
      case NotificationPriority.critical:
        return AppColors.error;
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.arrow_downward;
      case NotificationPriority.normal:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.arrow_upward;
      case NotificationPriority.critical:
        return Icons.priority_high;
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Düşük';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'Yüksek';
      case NotificationPriority.critical:
        return 'Kritik';
    }
  }
}

