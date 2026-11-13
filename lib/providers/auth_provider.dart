import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool _rememberMe = false;
  String? _savedEmail;
  int _autoLockMinutes = 3; // Inactivity timeout in minutes (0 = immediately on close/switch)
  bool _sessionTimedOut = false;
  DateTime? _lastBackgroundedTime;

  User? get user => _user;
  bool get isAuthenticated => _user != null && _api.token != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get rememberMe => _rememberMe;
  String? get savedEmail => _savedEmail;
  int get autoLockMinutes => _autoLockMinutes;
  bool get sessionTimedOut => _sessionTimedOut;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    _savedEmail = prefs.getString('saved_email');
    _autoLockMinutes = prefs.getInt('auto_lock_minutes') ?? 3;

    // Check if previous session was timed out while app was closed
    final lastBgMillis = prefs.getInt('last_backgrounded_at');
    if (lastBgMillis != null && _rememberMe) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastBgMillis;
      final timeoutMillis = _autoLockMinutes * 60 * 1000;
      if (_autoLockMinutes > 0 && elapsed > timeoutMillis) {
        // Timed out while app was in background
        await _api.setToken(null);
        _sessionTimedOut = true;
      }
    }

    await _api.init();
    if (_api.token != null) {
      try {
        final res = await _api.get('/user');
        if (res['user'] != null) {
          _user = User.fromJson(res['user']);
        }
      } catch (e) {
        // Token expired or invalid
        await _api.setToken(null);
        _user = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSessionTimeoutNotice() {
    _sessionTimedOut = false;
    notifyListeners();
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_lock_minutes', minutes);
    notifyListeners();
  }

  Future<void> onAppBackgrounded() async {
    if (!isAuthenticated) return;
    _lastBackgroundedTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_backgrounded_at', _lastBackgroundedTime!.millisecondsSinceEpoch);
  }

  Future<void> onAppResumed() async {
    if (!isAuthenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final lastBgMillis = prefs.getInt('last_backgrounded_at') ?? _lastBackgroundedTime?.millisecondsSinceEpoch;

    if (lastBgMillis == null) return;

    final elapsedMillis = DateTime.now().millisecondsSinceEpoch - lastBgMillis;

    // If rememberMe is false, any backgrounding longer than 30 seconds triggers re-login
    if (!_rememberMe && elapsedMillis > 30 * 1000) {
      await _triggerAutoLock();
      return;
    }

    // If rememberMe is true, check configured timeout
    if (_autoLockMinutes > 0) {
      final timeoutMillis = _autoLockMinutes * 60 * 1000;
      if (elapsedMillis >= timeoutMillis) {
        await _triggerAutoLock();
        return;
      }
    }

    // Reset background timestamp when successfully resumed
    await prefs.remove('last_backgrounded_at');
    _lastBackgroundedTime = null;
  }

  Future<void> _triggerAutoLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_backgrounded_at');
    _lastBackgroundedTime = null;

    // Invalidate token locally
    await _api.setToken(null);
    _user = null;
    _sessionTimedOut = true;
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _sessionTimedOut = false;
    notifyListeners();

    try {
      final res = await _api.post('/login', {
        'email': email,
        'password': password,
      });

      final token = res['token'];
      _rememberMe = rememberMe;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      if (rememberMe) {
        await prefs.setString('saved_email', email);
        await _api.setToken(token, persist: true);
      } else {
        await prefs.remove('saved_email');
        await _api.setToken(token, persist: false);
      }

      _user = User.fromJson(res['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, [String currency = 'IDR']) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'primary_currency': currency,
      });

      final token = res['token'];
      await _api.setToken(token, persist: true);
      _user = User.fromJson(res['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? password,
    String? primaryCurrency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (password != null && password.trim().isNotEmpty) body['password'] = password.trim();
      if (primaryCurrency != null && primaryCurrency.trim().isNotEmpty) {
        body['primary_currency'] = primaryCurrency.trim();
      }

      final res = await _api.put('/user', body);
      if (res['user'] != null) {
        _user = User.fromJson(res['user']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout', {});
    } catch (_) {}
    await _api.setToken(null);
    _user = null;
    _sessionTimedOut = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_backgrounded_at');
    notifyListeners();
  }
}
