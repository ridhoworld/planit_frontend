import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../services/api_service.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<Budget> _budgets = [];
  double _totalLimit = 0.0;
  double _totalSpent = 0.0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Budget> get budgets => _budgets;
  double get totalLimit => _totalLimit;
  double get totalSpent => _totalSpent;

  Future<void> fetchBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/budgets');
      final List<dynamic> list = res['budgets'] ?? [];
      _budgets = list.map((b) => Budget.fromJson(b)).toList();
      _totalLimit = double.tryParse(res['total_limit']?.toString() ?? '0') ?? 0.0;
      _totalSpent = double.tryParse(res['total_spent']?.toString() ?? '0') ?? 0.0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBudget({
    required int categoryId,
    required double amountLimit,
    required String period,
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/budgets', {
        'category_id': categoryId,
        'amount_limit': amountLimit,
        'period': period,
        'start_date': startDate,
        'end_date': endDate,
      });

      await fetchBudgets();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      await _api.delete('/budgets/$id');
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

