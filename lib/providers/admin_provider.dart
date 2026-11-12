import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<User> _users = [];
  Map<String, dynamic>? _dashboardStats;
  List<User> _recentUsers = [];
  List<dynamic> _recentTransactions = [];
  List<Category> _masterCategories = [];
  List<dynamic> _auditTransactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  List<dynamic> get recentTransactions => _recentTransactions;
  List<Category> get masterCategories => _masterCategories;
  List<dynamic> get auditTransactions => _auditTransactions;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Dashboard System Metrics
  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/admin/dashboard');
      if (res['stats'] != null) {
        _dashboardStats = res['stats'];
      }
      if (res['recent_users'] != null && res['recent_users'] is List) {
        _recentUsers = (res['recent_users'] as List).map((u) => User.fromJson(u)).toList();
      }
      if (res['recent_transactions'] != null && res['recent_transactions'] is List) {
        _recentTransactions = res['recent_transactions'];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. User Management
  Future<void> fetchUsers({String? search, String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (role != null && role.isNotEmpty && role != 'all') {
        queryParams['role'] = role;
      }

      final res = await _api.get('/admin/users', queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (res['data'] != null && res['data'] is List) {
        _users = (res['data'] as List).map((u) => User.fromJson(u)).toList();
      } else if (res is List) {
        _users = res.map((u) => User.fromJson(u)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String primaryCurrency = 'IDR',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/admin/users', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'primary_currency': primaryCurrency,
      });

      await fetchUsers();
      await fetchDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null && password.trim().isNotEmpty) body['password'] = password.trim();
      if (role != null) body['role'] = role;

      await _api.put('/admin/users/$id', body);
      await fetchUsers();
      await fetchDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/admin/users/$id');
      await fetchUsers();
      await fetchDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. Master Categories Management
  Future<void> fetchMasterCategories({String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }

      final res = await _api.get('/admin/categories', queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (res['categories'] != null && res['categories'] is List) {
        _masterCategories = (res['categories'] as List).map((c) => Category.fromJson(c)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMasterCategory({
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/admin/categories', {
        'name': name,
        'type': type,
        'color': color ?? '#3B82F6',
        'icon': icon ?? 'category',
      });

      await fetchMasterCategories();
      await fetchDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMasterCategory(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/admin/categories/$id');
      await fetchMasterCategories();
      await fetchDashboard();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 4. Global Audit Transactions
  Future<void> fetchAuditTransactions({String? search, String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }

      final res = await _api.get('/admin/transactions', queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (res['data'] != null && res['data'] is List) {
        _auditTransactions = res['data'];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
