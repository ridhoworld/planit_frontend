import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _monthlyTrend = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  double get totalExpense => _totalExpense;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;
  List<Map<String, dynamic>> get monthlyTrend => _monthlyTrend;

  void setPeriod(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    fetchReports();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/reports', queryParams: {
        'month': _selectedMonth,
        'year': _selectedYear,
      });

      _totalExpense = double.tryParse(res['total_expense']?.toString() ?? '0') ?? 0.0;

      final List<dynamic> catList = res['category_breakdown'] ?? [];
      _categoryBreakdown = catList.map((c) => Map<String, dynamic>.from(c)).toList();

      final List<dynamic> trendList = res['monthly_trend'] ?? [];
      _monthlyTrend = trendList.map((t) => Map<String, dynamic>.from(t)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}

