class SplitBillParticipant {
  final int id;
  final int splitBillId;
  final String name;
  final double amount;
  bool isPaid;

  SplitBillParticipant({
    required this.id,
    required this.splitBillId,
    required this.name,
    required this.amount,
    this.isPaid = false,
  });

  factory SplitBillParticipant.fromJson(Map<String, dynamic> json) {
    return SplitBillParticipant(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      splitBillId: json['split_bill_id'] is int
          ? json['split_bill_id']
          : int.parse(json['split_bill_id'].toString()),
      name: json['name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
    );
  }
}

class SplitBill {
  final int id;
  final String title;
  final double totalAmount;
  final String? notes;
  final List<SplitBillParticipant> participants;
  final DateTime createdAt;

  SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.notes,
    required this.participants,
    required this.createdAt,
  });

  factory SplitBill.fromJson(Map<String, dynamic> json) {
    var rawParticipants = json['participants'] as List<dynamic>? ?? [];
    List<SplitBillParticipant> parsed =
        rawParticipants.map((p) => SplitBillParticipant.fromJson(p)).toList();

    return SplitBill(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      notes: json['notes'],
      participants: parsed,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  double get paidAmount {
    return participants
        .where((p) => p.isPaid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get unpaidAmount => totalAmount - paidAmount;
  bool get isAllPaid => participants.isNotEmpty && participants.every((p) => p.isPaid);
}

