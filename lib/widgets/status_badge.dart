import 'package:flutter/material.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor,
  });

  factory StatusBadge.taskStatus(TaskStatus status) {
    Color bgColor;
    String text;

    switch (status) {
      case TaskStatus.todo:
        bgColor = AppColors.taskTodo;
        text = 'To-Do';
        break;
      case TaskStatus.inProgress:
        bgColor = AppColors.taskInProgress;
        text = 'In Progress';
        break;
      case TaskStatus.done:
        bgColor = AppColors.taskDone;
        text = 'Done';
        break;
    }

    return StatusBadge(
      text: text,
      backgroundColor: bgColor,
      textColor: status == TaskStatus.inProgress 
          ? AppColors.background 
          : AppColors.textPrimary,
    );
  }

  factory StatusBadge.difficulty(TaskDifficulty difficulty) {
    Color bgColor;
    String text;

    switch (difficulty) {
      case TaskDifficulty.easy:
        bgColor = AppColors.difficultyEasy;
        text = 'Kolay';
        break;
      case TaskDifficulty.medium:
        bgColor = AppColors.difficultyMedium;
        text = 'Orta';
        break;
      case TaskDifficulty.hard:
        bgColor = AppColors.difficultyHard;
        text = 'Zor';
        break;
      case TaskDifficulty.veryHard:
        bgColor = AppColors.difficultyVeryHard;
        text = 'Çok Zor';
        break;
    }

    return StatusBadge(
      text: text,
      backgroundColor: bgColor,
      textColor: AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}

