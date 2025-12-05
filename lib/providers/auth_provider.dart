import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:office_control/models/user_model.dart';
import 'package:office_control/services/auth_service.dart';
import 'package:office_control/services/database_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, pendingApproval }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isEmployee => _user?.role == UserRole.employee;
  bool get isApproved => _user?.isApproved ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _user = await _dbService.getUser(firebaseUser.uid);
      if (_user == null) {
        _status = AuthStatus.pendingApproval;
      } else if (!_user!.isApproved) {
        _status = AuthStatus.pendingApproval;
      } else {
        _status = AuthStatus.authenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = await _dbService.getUser(credential.user!.uid);

      if (userData == null) {
        _error = 'Kullanıcı bulunamadı. Lütfen erişim talebi oluşturun.';
        await _authService.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (isAdmin && userData.role != UserRole.admin) {
        _error = 'Bu hesap admin hesabı değil.';
        await _authService.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!isAdmin && userData.role == UserRole.admin) {
        // Admin can also login as employee
      }

      if (!userData.isApproved) {
        _error = 'Hesabınız henüz onaylanmamış. Lütfen bekleyin.';
        _status = AuthStatus.pendingApproval;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = userData;
      _status = AuthStatus.authenticated;
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

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
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

  Future<void> refreshUser() async {
    if (_authService.currentUser != null) {
      _user = await _dbService.getUser(_authService.currentUser!.uid);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
