import 'account.dart';
import 'category.dart';
import 'tag.dart';

class TransactionItem {
  final int id;
  final int accountId;
  final int? targetAccountId;
  final int? categoryId;
  final String type; // income, expense, transfer
  final double amount;
  final DateTime transactionDate;
  final String? notes;
  final String? receiptPath;
  final Account? account;
  final Account? targetAccount;
  final Category? category;
  final List<Tag> tags;

  TransactionItem({
    required this.id,
    required this.accountId,
    this.targetAccountId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.notes,
    this.receiptPath,
    this.account,
    this.targetAccount,
    this.category,
    this.tags = const [],
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'] as List<dynamic>? ?? [];
    List<Tag> parsedTags = rawTags.map((t) => Tag.fromJson(t)).toList();

    return TransactionItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      accountId: json['account_id'] is int ? json['account_id'] : int.parse(json['account_id'].toString()),
      targetAccountId: json['target_account_id'] != null ? int.tryParse(json['target_account_id'].toString()) : null,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      type: json['type'] ?? 'expense',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'],
      receiptPath: json['receipt_path'],
      account: json['account'] != null ? Account.fromJson(json['account']) : null,
      targetAccount: json['target_account'] != null ? Account.fromJson(json['target_account']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      tags: parsedTags,
    );
  }
}

