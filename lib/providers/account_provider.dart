import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/api_service.dart';

class AccountProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<Account> _accounts = [];
  double _totalBalance = 0.0;
  double _totalCreditDebt = 0.0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Account> get accounts => _accounts;
  List<Account> get activeAccounts => _accounts.where((a) => a.isActive).toList();
  double get totalBalance => _totalBalance;
  double get totalCreditDebt => _totalCreditDebt;

  Future<void> fetchAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/accounts');
      final List<dynamic> list = res['accounts'] ?? [];
      _accounts = list.map((a) => Account.fromJson(a)).toList();
      _totalBalance = double.tryParse(res['total_balance']?.toString() ?? '0') ?? 0.0;
      _totalCreditDebt = double.tryParse(res['total_credit_debt']?.toString() ?? '0') ?? 0.0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAccount({
    required String name,
    required String type,
    required double initialBalance,
    double? creditLimit,
    String? color,
    String? icon,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/accounts', {
        'name': name,
        'type': type,
        'initial_balance': initialBalance,
        'credit_limit': creditLimit,
        'color': color,
        'icon': icon,
      });

      await fetchAccounts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adjustBalance(int accountId, double newBalance, String? notes) async {
    try {
      await _api.post('/accounts/$accountId/adjust-balance', {
        'new_balance': newBalance,
        'notes': notes,
      });

      await fetchAccounts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrArchiveAccount(int accountId) async {
    try {
      await _api.delete('/accounts/$accountId');
      await fetchAccounts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

