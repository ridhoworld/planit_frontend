import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionItem> _transactions = [];
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  List<Category> _allCategories = [];
  List<Tag> _tags = [];

  String? _selectedType;
  int? _selectedAccountId;
  int? _selectedCategoryId;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionItem> get transactions => _transactions;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get allCategories => _allCategories;
  List<Tag> get tags => _tags;

  String? get selectedType => _selectedType;
  int? get selectedAccountId => _selectedAccountId;
  int? get selectedCategoryId => _selectedCategoryId;

  void setFilterType(String? type) {
    _selectedType = type;
    fetchTransactions();
  }

  void setFilterAccount(int? accountId) {
    _selectedAccountId = accountId;
    fetchTransactions();
  }

  void setFilterCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchTransactions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedType != null) queryParams['type'] = _selectedType;
      if (_selectedAccountId != null) queryParams['account_id'] = _selectedAccountId;
      if (_selectedCategoryId != null) queryParams['category_id'] = _selectedCategoryId;
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final res = await _api.get('/transactions', queryParams: queryParams);

      final List<dynamic> data = res['data'] ?? [];
      _transactions = data.map((t) => TransactionItem.fromJson(t)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategoriesAndTags() async {
    try {
      final catRes = await _api.get('/categories');
      final List<dynamic> flat = catRes['flat'] ?? [];

      _allCategories = flat.map((c) => Category.fromJson(c)).toList();
      _incomeCategories = _allCategories.where((c) => c.type == 'income').toList();
      _expenseCategories = _allCategories.where((c) => c.type == 'expense').toList();

      final tagRes = await _api.get('/tags');
      final List<dynamic> rawTags = tagRes['tags'] ?? [];
      _tags = rawTags.map((t) => Tag.fromJson(t)).toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addTransaction({
    required int accountId,
    int? targetAccountId,
    int? categoryId,
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    List<int>? tagIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/transactions', {
        'account_id': accountId,
        'target_account_id': targetAccountId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'transaction_date': transactionDate.toIso8601String(),
        'notes': notes,
        'tag_ids': tagIds,
      });

      await fetchTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Category?> addCategory({
    required String name,
    required String type,
    int? parentId,
    String? color,
    String? icon,
  }) async {
    try {
      final res = await _api.post('/categories', {
        'name': name,
        'type': type,
        'parent_id': parentId,
        'color': color,
        'icon': icon,
      });

      await fetchCategoriesAndTags();

      if (res['category'] != null) {
        return Category.fromJson(res['category']);
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _api.delete('/transactions/$id');
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
