import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/services/database_service.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription? _tasksSubscription;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TaskModel> get todoTasks =>
      _tasks.where((t) => t.status == TaskStatus.todo).toList();
  List<TaskModel> get inProgressTasks =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get doneTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();

  void setUserId(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribeToTasks();
  }

  void _subscribeToTasks() {
    _tasksSubscription?.cancel();
    if (_userId == null) return;

    _tasksSubscription = _dbService.userTasksStream(_userId!).listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createTask({
    required String title,
    String? description,
    required TaskDifficulty difficulty,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = TaskModel(
        id: _uuid.v4(),
        userId: _userId!,
        title: title,
        description: description,
        status: TaskStatus.todo,
        difficulty: difficulty,
        createdAt: DateTime.now(),
      );

      await _dbService.createTask(task);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startTask(String taskId) async {
    if (_userId == null) return false;

    try {
      await _dbService.startTask(_userId!, taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(String taskId) async {
    if (_userId == null) return false;

    try {
      await _dbService.completeTask(_userId!, taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (_userId == null) return false;

    try {
      await _dbService.deleteTask(_userId!, taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      await _dbService.updateTask(task);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}

