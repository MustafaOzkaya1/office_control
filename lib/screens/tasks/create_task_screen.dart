import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/providers/task_provider.dart';
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
    super.dispose();
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

