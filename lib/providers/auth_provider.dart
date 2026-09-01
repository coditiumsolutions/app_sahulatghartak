import 'package:flutter/material.dart';

import '../models/auth_data.dart';
import '../models/client_detail.dart';
import '../models/otp_data.dart';
import '../services/auth_api_service.dart';
import '../services/client_profile_api_service.dart';
import '../services/provider_profile_api_service.dart';
import '../services/session_service.dart';
import '../utils/api_error.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  final ProviderProfileApiService _providerProfileApiService = ProviderProfileApiService();
  final ClientProfileApiService _clientProfileApiService = ClientProfileApiService();
  final SessionService _sessionService = SessionService();

  AuthData? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  OtpData? _otpData;
  ClientDetailModel? _clientDetail;

  AuthData? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get role => _currentUser?.role;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  OtpData? get otpData => _otpData;
  ClientDetailModel? get clientDetail => _clientDetail;

  Future<void> tryAutoLogin() async {
    _currentUser = await _sessionService.getSession();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String mobileNo, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = (await _apiService.login(mobileNo, password)).copyWith(mobileNo: mobileNo);

      if (_currentUser!.role == 'Provider') {
        try {
          final providerProfile = await _providerProfileApiService.fetchById(_currentUser!.userId);
          _currentUser = _currentUser!.copyWith(categoryId: providerProfile.categoryUid, providerUid: providerProfile.uid);
        } catch (_) {
          // Category lookup is non-critical to login; proceed without it if it fails.
        }
      }

      await _sessionService.saveSession(_currentUser!);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerCustomer({
    required String fullName,
    required String mobileNo,
    required String password,
    required String confirmPassword,
    required String cnic,
    required String gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.registerCustomer(
        fullName: fullName,
        mobileNo: mobileNo,
        password: password,
        confirmPassword: confirmPassword,
        cnic: cnic,
        gender: gender,
      );
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String mobileNo, {String otpType = 'Registration'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _otpData = await _apiService.sendOtp(mobileNo, otpType: otpType);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendOtp(String mobileNo, {String otpType = 'Registration'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _otpData = await _apiService.resendOtp(mobileNo, otpType: otpType);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String mobileNo, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.verifyOtp(mobileNo, otp);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerProvider({
    required String fullName,
    required String mobileNo,
    required String password,
    required String cnic,
    required String gender,
    required int experienceYears,
    required String description,
    required int categoryId,
    required String categoryName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final providerUid = await _apiService.registerProvider(
        fullName: fullName,
        mobileNo: mobileNo,
        password: password,
        cnic: cnic,
        gender: gender,
        experienceYears: experienceYears,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
      );
      final loggedIn = await login(mobileNo, password);
      if (loggedIn && providerUid > 0) {
        // register-provider's response is the authoritative source for providerUid;
        // the provider-profile lookup inside login() is best-effort and may fail silently.
        _currentUser = _currentUser?.copyWith(providerUid: providerUid);
        await _sessionService.saveSession(_currentUser!);
        notifyListeners();
      }
      return loggedIn;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String mobileNo, String otp, String newPassword, String confirmNewPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(mobileNo, otp, newPassword, confirmNewPassword);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchClientDetail() async {
    _error = null;
    try {
      _clientDetail = await _clientProfileApiService.fetchDetail(_currentUser!.providerUid!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClientDetail({required String fullName, required String cnic, required String gender}) async {
    _error = null;
    try {
      _clientDetail = await _clientProfileApiService.updateDetail(
        clientUid: _currentUser!.providerUid!,
        fullName: fullName,
        cnic: cnic,
        gender: gender,
      );
      _currentUser = _currentUser!.copyWith(username: fullName);
      await _sessionService.saveSession(_currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mobileNo = _currentUser!.mobileNo;
      await _apiService.deleteAccount(mobileNo, password);
      await _sessionService.clearSession();
      _currentUser = null;
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
