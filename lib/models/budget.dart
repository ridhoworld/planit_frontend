import 'category.dart';

class Budget {
  final int id;
  final int categoryId;
  final Category? category;
  final double amountLimit;
  final double spentAmount;
  final double remainingAmount;
  final double percentage;
  final String status; // safe, warning, exceeded
  final String period; // weekly, monthly, yearly
  final String startDate;
  final String endDate;

  Budget({
    required this.id,
    required this.categoryId,
    this.category,
    required this.amountLimit,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.status,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      categoryId: json['category_id'] is int ? json['category_id'] : int.parse(json['category_id'].toString()),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      amountLimit: double.tryParse(json['amount_limit']?.toString() ?? '0') ?? 0.0,
      spentAmount: double.tryParse(json['spent_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'safe',
      period: json['period'] ?? 'monthly',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

