import 'package:flutter/material.dart';

import '../models/auth_data.dart';
import '../services/auth_api_service.dart';
import '../services/provider_profile_api_service.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  final ProviderProfileApiService _providerProfileApiService = ProviderProfileApiService();
  final SessionService _sessionService = SessionService();

  AuthData? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  AuthData? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get role => _currentUser?.role;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    _currentUser = await _sessionService.getSession();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _apiService.login(emailOrPhone, password);

      if (_currentUser!.role == 'Provider') {
        try {
          final providerProfile = await _providerProfileApiService.fetchById(_currentUser!.userId);
          _currentUser = _currentUser!.copyWith(categoryId: providerProfile.categoryUid);
        } catch (_) {
          // Category lookup is non-critical to login; proceed without it if it fails.
        }
      }

      await _sessionService.saveSession(_currentUser!);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String defaultAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.registerCustomer(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        defaultAddress: defaultAddress,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerProvider({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required int categoryId,
    required String serviceType,
    required String cnic,
    required int experienceYears,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.registerProvider(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        categoryId: categoryId,
        serviceType: serviceType,
        cnic: cnic,
        experienceYears: experienceYears,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
