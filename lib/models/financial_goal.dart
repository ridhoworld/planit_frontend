class FinancialGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final double percentage;
  final double suggestedMonthly;
  final String? deadline;
  final String status; // in_progress, completed, paused
  final String? color;
  final String? icon;

  FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.suggestedMonthly,
    this.deadline,
    required this.status,
    this.color,
    this.icon,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      targetAmount: double.tryParse(json['target_amount']?.toString() ?? '0') ?? 0.0,
      currentAmount: double.tryParse(json['current_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      suggestedMonthly: double.tryParse(json['suggested_monthly']?.toString() ?? '0') ?? 0.0,
      deadline: json['deadline'],
      status: json['status'] ?? 'in_progress',
      color: json['color'],
      icon: json['icon'],
    );
  }
}

