import 'package:flutter/foundation.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  double _netWorth = 0.0;
  double _totalBalance = 0.0;
  double _totalInvestments = 0.0;
  double _totalDebts = 0.0;
  double _totalReceivables = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  double _netCashflow = 0.0;

  List<TransactionItem> _recentTransactions = [];
  List<Map<String, dynamic>> _budgetsPreview = [];
  List<RecurringTransaction> _upcomingBills = [];
  List<Map<String, dynamic>> _goalsPreview = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get netWorth => _netWorth;
  double get totalBalance => _totalBalance;
  double get totalInvestments => _totalInvestments;
  double get totalDebts => _totalDebts;
  double get totalReceivables => _totalReceivables;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  double get netCashflow => _netCashflow;

  List<TransactionItem> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get budgetsPreview => _budgetsPreview;
  List<RecurringTransaction> get upcomingBills => _upcomingBills;
  List<Map<String, dynamic>> get goalsPreview => _goalsPreview;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/dashboard');

      _netWorth = double.tryParse(res['net_worth']?.toString() ?? '0') ?? 0.0;
      _totalBalance = double.tryParse(res['total_balance']?.toString() ?? '0') ?? 0.0;
      _totalInvestments = double.tryParse(res['total_investments']?.toString() ?? '0') ?? 0.0;
      _totalDebts = double.tryParse(res['total_debts']?.toString() ?? '0') ?? 0.0;
      _totalReceivables = double.tryParse(res['total_receivables']?.toString() ?? '0') ?? 0.0;
      _monthlyIncome = double.tryParse(res['monthly_income']?.toString() ?? '0') ?? 0.0;
      _monthlyExpense = double.tryParse(res['monthly_expense']?.toString() ?? '0') ?? 0.0;
      _netCashflow = double.tryParse(res['net_cashflow']?.toString() ?? '0') ?? 0.0;

      var rawRecent = res['recent_transactions'] as List<dynamic>? ?? [];
      _recentTransactions = rawRecent.map((t) => TransactionItem.fromJson(t)).toList();

      var rawBudgets = res['budgets_preview'] as List<dynamic>? ?? [];
      _budgetsPreview = rawBudgets.map((b) => Map<String, dynamic>.from(b)).toList();

      var rawBills = res['upcoming_bills'] as List<dynamic>? ?? [];
      _upcomingBills = rawBills.map((b) => RecurringTransaction.fromJson(b)).toList();

      var rawGoals = res['goals_preview'] as List<dynamic>? ?? [];
      _goalsPreview = rawGoals.map((g) => Map<String, dynamic>.from(g)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}

