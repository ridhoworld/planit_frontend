class Debt {
  final int id;
  final String type; // payable (utang), receivable (piutang)
  final String partyName;
  final double totalAmount;
  final double remainingAmount;
  final double interestRate;
  final String? dueDate;
  final String? notes;

  Debt({
    required this.id,
    required this.type,
    required this.partyName,
    required this.totalAmount,
    required this.remainingAmount,
    this.interestRate = 0,
    this.dueDate,
    this.notes,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      type: json['type'] ?? 'payable',
      partyName: json['party_name'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      interestRate: double.tryParse(json['interest_rate']?.toString() ?? '0') ?? 0.0,
      dueDate: json['due_date'],
      notes: json['notes'],
    );
  }

  bool get isPayable => type == 'payable';
}

