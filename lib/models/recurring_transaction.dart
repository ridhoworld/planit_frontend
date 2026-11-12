import 'account.dart';
import 'category.dart';

class RecurringTransaction {
  final int id;
  final int accountId;
  final int? categoryId;
  final String title;
  final double amount;
  final String type; // expense, income
  final String frequency; // daily, weekly, monthly, yearly
  final String nextDueDate;
  final bool autoCreate;
  final bool isActive;
  final Account? account;
  final Category? category;

  RecurringTransaction({
    required this.id,
    required this.accountId,
    this.categoryId,
    required this.title,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextDueDate,
    this.autoCreate = false,
    this.isActive = true,
    this.account,
    this.category,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      accountId: json['account_id'] is int ? json['account_id'] : int.parse(json['account_id'].toString()),
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'expense',
      frequency: json['frequency'] ?? 'monthly',
      nextDueDate: json['next_due_date'] ?? '',
      autoCreate: json['auto_create'] == true || json['auto_create'] == 1,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      account: json['account'] != null ? Account.fromJson(json['account']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}

