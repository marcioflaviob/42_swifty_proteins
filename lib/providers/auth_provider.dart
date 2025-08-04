import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        
        final prefs = await SharedPreferences.getInstance();
        final storedUsername = prefs.getString('biometric_username');
        
        if (storedUsername != null && storedUsername != username) {
          await _clearBiometricLogin();
        }
        
        await _storeUserForBiometricLogin(username);
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

  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('biometric_username');
      
      if (storedUsername == null) {
        _errorMessage = 'No user registered for biometric login';
        return false;
      }

      if (await _databaseService.userExists(storedUsername)) {
        _currentUser = User(id: 0, username: storedUsername);
        
        final dbUser = await _databaseService.getUserByUsername(storedUsername);
        if (dbUser != null) {
          _currentUser = dbUser;
        }
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'User no longer exists';

        await _clearBiometricLogin();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Biometric login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _storeUserForBiometricLogin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_username', username);
    await prefs.setBool('canUseBiometrics', true);
  }

  Future<void> _clearBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_username');
    await prefs.setBool('canUseBiometrics', false);
  }

  Future<bool> canUseBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final canUseBiometrics = prefs.getBool('canUseBiometrics') ?? false;
    final storedUsername = prefs.getString('biometric_username');
    
    return canUseBiometrics && storedUsername != null;
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

  Future<void> logoutAndClearBiometrics() async {
    _currentUser = null;
    _errorMessage = '';
    await _clearBiometricLogin();
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