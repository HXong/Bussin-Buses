// lib/viewmodels/account_viewmodel.dart
import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountService _accountService;
  final AuthService _authService;
  
  bool _isLoading = false;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _userType = '';
  String? _errorMessage;
  String? _successMessage;
  
  AccountViewModel(this._accountService, this._authService) {
    loadUserProfile();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get userType => _userType;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  
  // Setters
  set fullName(String value) {
    _fullName = value;
    notifyListeners();
  }
  
  set phone(String value) {
    _phone = value;
    notifyListeners();
  }
  
  // Load user profile
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final profile = await _accountService.getUserProfile();
      _fullName = profile['username'] ?? '';
      _email = profile['email'] ?? '';
      _phone = profile['phone'] ?? '';
      _userType = profile['user_type'] ?? '';
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update profile
  Future<bool> updateProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final success = await _accountService.updateUserProfile(
        fullName: _fullName,
        phone: _phone,
      );
      
      if (success) {
        _successMessage = 'Profile updated successfully';
        return true;
      } else {
        _errorMessage = 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      // First verify the current password
      try {
        await _authService.signIn(_email, currentPassword);
      } catch (e) {
        _errorMessage = 'Current password is incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Then change the password
      final success = await _accountService.changePassword(newPassword);
      
      if (success) {
        _successMessage = 'Password changed successfully';
        return true;
      } else {
        _errorMessage = 'Failed to change password';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

