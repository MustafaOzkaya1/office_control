import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/models/ai_interaction_model.dart';
import 'package:office_control/providers/task_provider.dart';
import 'package:office_control/providers/auth_provider.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/utils/app_theme.dart';
import 'package:office_control/widgets/custom_text_field.dart';
import 'package:office_control/widgets/custom_button.dart';

class CreateTaskScreen extends StatefulWidget {
  final TaskModel? taskToEdit;

  const CreateTaskScreen({super.key, this.taskToEdit});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskDifficulty _selectedDifficulty = TaskDifficulty.medium;
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<AIPredictResponse?>? _aiResponseSubscription;
  AIPredictResponse? _aiResponse;
  bool _isAiLoading = false;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description ?? '';
      _selectedDifficulty = widget.taskToEdit!.difficulty;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiResponseSubscription?.cancel();
    super.dispose();
  }

  String _getDifficultyString(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'easy';
      case TaskDifficulty.medium:
        return 'medium';
      case TaskDifficulty.hard:
        return 'hard';
      case TaskDifficulty.veryHard:
        return 'very_hard';
    }
  }

  Future<void> _askAIForPrediction() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce görev başlığı girin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiResponse = null;
    });

    // İsteği gönder
    final fullDescription = description.isNotEmpty
        ? '$title. $description'
        : title;

    await _databaseService.sendAIPredictRequest(
      uid: uid,
      description: fullDescription,
      difficulty: _getDifficultyString(_selectedDifficulty),
    );

    // Cevabı dinle
    _aiResponseSubscription?.cancel();
    _aiResponseSubscription = _databaseService
        .aiPredictResponseStream(uid)
        .listen((response) {
      if (mounted) {
        setState(() {
          _aiResponse = response;
          if (response != null && (response.hasData || response.hasError)) {
            _isAiLoading = false;
          }
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final taskProvider = context.read<TaskProvider>();
    bool success;

    if (isEditing) {
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        difficulty: _selectedDifficulty,
      );
      success = await taskProvider.updateTask(updatedTask);
    } else {
      success = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        difficulty: _selectedDifficulty,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Task updated!' : 'Task created!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? 'An error occurred'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Create Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Task Title',
                  hint: 'What needs to be done?',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Task title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Add more details about the task...',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Difficulty Selection
                Text(
                  'Difficulty',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                _DifficultySelector(
                  selected: _selectedDifficulty,
                  onChanged: (difficulty) {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Difficulty Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getDifficultyInfo(_selectedDifficulty),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Prediction Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.psychology,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu iş ne kadar sürer?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isAiLoading ? null : _askAIForPrediction,
                        icon: _isAiLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isAiLoading ? 'Analiz ediliyor...' : 'AI\'ya Sor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      // AI Response
                      if (_aiResponse != null) ...[
                        const SizedBox(height: 12),
                        _AIResponseWidget(response: _aiResponse!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Submit Button
                CustomButton(
                  text: isEditing ? 'Update Task' : 'Create Task',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyInfo(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Quick tasks that take less than 30 minutes. 1 point.';
      case TaskDifficulty.medium:
        return 'Standard tasks that take 30 min to 2 hours. 2 points.';
      case TaskDifficulty.hard:
        return 'Complex tasks that take 2-4 hours. 3 points.';
      case TaskDifficulty.veryHard:
        return 'Major tasks requiring a full day or more. 5 points.';
    }
  }
}

class _DifficultySelector extends StatelessWidget {
  final TaskDifficulty selected;
  final ValueChanged<TaskDifficulty> onChanged;

  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskDifficulty.values.map((difficulty) {
        final isSelected = selected == difficulty;
        final color = _getDifficultyColor(difficulty);

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(difficulty),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: difficulty != TaskDifficulty.veryHard ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getDifficultyIcon(difficulty),
                    color: isSelected ? color : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDifficultyLabel(difficulty),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected ? color : AppColors.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
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

  IconData _getDifficultyIcon(TaskDifficulty difficulty) {
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

  String _getDifficultyLabel(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Easy';
      case TaskDifficulty.medium:
        return 'Medium';
      case TaskDifficulty.hard:
        return 'Hard';
      case TaskDifficulty.veryHard:
        return 'Very\nHard';
    }
  }
}

class _AIResponseWidget extends StatelessWidget {
  final AIPredictResponse response;

  const _AIResponseWidget({required this.response});

  @override
  Widget build(BuildContext context) {
    if (response.hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                response.error ?? 'Bir hata oluştu',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (!response.hasData) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Tahmini',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (response.humanTime != null) ...[
            const SizedBox(height: 8),
            Text(
              response.humanTime!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
          if (response.predictedMinutes != null) ...[
            const SizedBox(height: 4),
            Text(
              'Yaklaşık ${response.predictedMinutes} dakika',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

