import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_driver/models/auth_model.dart';
import 'package:app_driver/services/auth_service.dart';
import 'package:app_driver/core/storage_manager.dart';

enum AuthStatus { notAuthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageManager _storageManager = StorageManager();

  AuthStatus _status = AuthStatus.notAuthenticated;
  User? _user;
  String? _errorMessage;
  bool _isLoadingProfile = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoadingProfile => _isLoadingProfile;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authService.login(username, password);

      await _storageManager.saveToken(authResponse.token);
      await _storageManager.saveUser(jsonEncode(authResponse.user.toJson()));

      _user = authResponse.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.notAuthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageManager.clearAll();
    _user = null;
    _status = AuthStatus.notAuthenticated;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storageManager.getToken();
    final userJson = await _storageManager.getUser();

    if (token != null && userJson != null) {
      try {
        // First try to load from storage for immediate UI
        final storedUser = User.fromJson(jsonDecode(userJson));
        _user = storedUser;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Then fetch fresh data from API
        final freshUser = await _authService.getMe();
        _user = freshUser;
        // Update storage with fresh data
        await _storageManager.saveUser(jsonEncode(freshUser.toJson()));
        notifyListeners();
      } catch (e) {
        // If API fails but we have token, we might still be valid or token might be expired
        // simplistic approach: if unauthorized, logout. for now keep stored if just network error?
        // Let's assume strict: if check fails, maybe token is bad or network down.
        // For better UX, keep stored user if just network error.
        if (e.toString().contains("401") || e.toString().contains("403")) {
          await logout();
        }
        // If it's network error, we stay authenticated with stored user
      }
    } else {
      _status = AuthStatus.notAuthenticated;
    }
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      final freshUser = await _authService.getMe();
      if (freshUser.id != 0) {
        _user = freshUser;
        // Update storage with fresh data
        await _storageManager.saveUser(jsonEncode(freshUser.toJson()));
      }
    } catch (e) {
      debugPrint("Error refreshing user profile: $e");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }
}
