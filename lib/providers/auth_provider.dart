import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      User? user = await _databaseService.loginUser(username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      if (await _databaseService.userExists(username)) {
        _errorMessage = 'Username already exists';
        return false;
      }

      bool success = await _databaseService.registerUser(username, password);
      if (success) {
        // Automatically log in after registration
        return await login(username, password);
      } else {
        _errorMessage = 'Registration failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = '';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}