import 'package:bussin_buses/services/auth_service.dart';
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final supabaseClient = SupabaseClientService.client;
  User? _user;
  String? _errorMsg;
  String? _successMsg;
  bool _isLoading = false;
  String? _userType;

  AuthViewModel(this._authService) {
    _listenToAuthChanges();
  }

  User? get user => _user;
  String? get userType => _userType;
  String? get errorMsg => _errorMsg;
  String? get successMsg => _successMsg;
  bool get isLoading => _isLoading;

  /// Subscribes to database changes
  /// When _userType is commuter/driver, auth_gate.dart will load the commuter/driver page
  void _listenToAuthChanges() {
    supabaseClient.auth.onAuthStateChange.listen((event) async {
      _user = _authService.getCurrentUser();
      if (_user != null) {
        _userType = await _authService.getUserType(_user!.id);
      } else {
        _userType = null;
      }
      notifyListeners();
    });
  }

  /// Signs into Supabase Auth
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _authService.signIn(email, password);
      _user = res.user;
      _errorMsg = null;
    } catch (e) {
      _errorMsg = "Login failed: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Creates new account on Supabase Auth + creates a new entry on the Profile table in Sthe database
  Future<void> signUp(String email, String password, String username, String userType) async {
    _isLoading = true;
    _errorMsg = null;
    _successMsg = null;
    notifyListeners();

    try {
      final res = await _authService.signUp(email, password, username, userType);
      _user = res.user;
      _successMsg = "Successfully registered!";
    } catch (e) {
      _errorMsg = "Signup failed: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Signs out of Supabaase Auth
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMsg = "Sign out failed: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearMsg() {
    _errorMsg = null;
    _successMsg = null;
    notifyListeners();
  }

}