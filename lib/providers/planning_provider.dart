import 'package:flutter/foundation.dart';
import '../models/debt.dart';
import '../models/financial_goal.dart';
import '../models/investment.dart';
import '../models/recurring_transaction.dart';
import '../services/api_service.dart';

class PlanningProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<FinancialGoal> _goals = [];
  double _totalGoalTarget = 0.0;
  double _totalGoalSaved = 0.0;

  List<Debt> _debts = [];
  List<Debt> _payables = [];
  List<Debt> _receivables = [];
  double _totalPayable = 0.0;
  double _totalReceivable = 0.0;

  List<Investment> _investments = [];
  double _totalInvested = 0.0;
  double _totalInvestmentValue = 0.0;
  double _totalGainLoss = 0.0;
  double _gainLossPercentage = 0.0;
  List<Map<String, dynamic>> _portfolioAllocation = [];

  List<RecurringTransaction> _recurringBills = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FinancialGoal> get goals => _goals;
  double get totalGoalTarget => _totalGoalTarget;
  double get totalGoalSaved => _totalGoalSaved;

  List<Debt> get debts => _debts;
  List<Debt> get payables => _payables;
  List<Debt> get receivables => _receivables;
  double get totalPayable => _totalPayable;
  double get totalReceivable => _totalReceivable;

  List<Investment> get investments => _investments;
  double get totalInvested => _totalInvested;
  double get totalInvestmentValue => _totalInvestmentValue;
  double get totalGainLoss => _totalGainLoss;
  double get gainLossPercentage => _gainLossPercentage;
  List<Map<String, dynamic>> get portfolioAllocation => _portfolioAllocation;

  List<RecurringTransaction> get recurringBills => _recurringBills;

  Future<void> fetchAllPlanning() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchGoals(),
        fetchDebts(),
        fetchInvestments(),
        fetchRecurring(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGoals() async {
    try {
      final res = await _api.get('/financial-goals');
      final List<dynamic> list = res['goals'] ?? [];
      _goals = list.map((g) => FinancialGoal.fromJson(g)).toList();
      _totalGoalTarget = double.tryParse(res['total_target']?.toString() ?? '0') ?? 0.0;
      _totalGoalSaved = double.tryParse(res['total_saved']?.toString() ?? '0') ?? 0.0;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addGoal({
    required String name,
    required double targetAmount,
    double initialAmount = 0,
    String? deadline,
    String? color,
  }) async {
    try {
      await _api.post('/financial-goals', {
        'name': name,
        'target_amount': targetAmount,
        'current_amount': initialAmount,
        'deadline': deadline,
        'color': color,
      });
      await fetchGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> depositGoal(int goalId, double amount, [int? accountId]) async {
    try {
      await _api.post('/financial-goals/$goalId/deposit', {
        'amount': amount,
        'account_id': accountId,
      });
      await fetchGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDebts() async {
    try {
      final res = await _api.get('/debts');
      final List<dynamic> list = res['debts'] ?? [];
      _debts = list.map((d) => Debt.fromJson(d)).toList();
      _payables = _debts.where((d) => d.type == 'payable').toList();
      _receivables = _debts.where((d) => d.type == 'receivable').toList();
      _totalPayable = double.tryParse(res['total_payable']?.toString() ?? '0') ?? 0.0;
      _totalReceivable = double.tryParse(res['total_receivable']?.toString() ?? '0') ?? 0.0;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addDebt({
    required String type,
    required String partyName,
    required double totalAmount,
    double? remainingAmount,
    String? dueDate,
    String? notes,
  }) async {
    try {
      await _api.post('/debts', {
        'type': type,
        'party_name': partyName,
        'total_amount': totalAmount,
        'remaining_amount': remainingAmount ?? totalAmount,
        'due_date': dueDate,
        'notes': notes,
      });
      await fetchDebts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDebtPayment(int debtId, double amount, String paymentDate, [int? accountId, String? notes]) async {
    try {
      await _api.post('/debts/$debtId/payments', {
        'amount': amount,
        'payment_date': paymentDate,
        'account_id': accountId,
        'notes': notes,
      });
      await fetchDebts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchInvestments() async {
    try {
      final res = await _api.get('/investments');
      final List<dynamic> list = res['investments'] ?? [];
      _investments = list.map((i) => Investment.fromJson(i)).toList();
      _totalInvested = double.tryParse(res['total_invested']?.toString() ?? '0') ?? 0.0;
      _totalInvestmentValue = double.tryParse(res['total_current_value']?.toString() ?? '0') ?? 0.0;
      _totalGainLoss = double.tryParse(res['total_gain_loss']?.toString() ?? '0') ?? 0.0;
      _gainLossPercentage = double.tryParse(res['total_gain_loss_percentage']?.toString() ?? '0') ?? 0.0;

      final List<dynamic> alloc = res['allocation'] ?? [];
      _portfolioAllocation = alloc.map((a) => Map<String, dynamic>.from(a)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addInvestment({
    required String name,
    required String type,
    required double units,
    required double avgBuyPrice,
    required double currentPrice,
    String? notes,
  }) async {
    try {
      await _api.post('/investments', {
        'name': name,
        'type': type,
        'units': units,
        'avg_buy_price': avgBuyPrice,
        'current_price': currentPrice,
        'notes': notes,
      });
      await fetchInvestments();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInvestmentPrice(int id, double currentPrice) async {
    try {
      await _api.post('/investments/$id/update-price', {
        'current_price': currentPrice,
      });
      await fetchInvestments();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchRecurring() async {
    try {
      final res = await _api.get('/recurring-transactions');
      final List<dynamic> list = res['recurring'] ?? [];
      _recurringBills = list.map((r) => RecurringTransaction.fromJson(r)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> executeRecurring(int id) async {
    try {
      await _api.post('/recurring-transactions/$id/execute', {});
      await fetchRecurring();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

