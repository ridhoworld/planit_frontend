import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null && _api.token != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/login', {
        'email': email,
        'password': password,
      });

      final token = res['token'];
      await _api.setToken(token);
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
      await _api.setToken(token);
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
    notifyListeners();
  }
}

