class Account {
  final int id;
  final String name;
  final String type; // bank, e-wallet, cash, credit_card, investment
  final double initialBalance;
  final double currentBalance;
  final double? creditLimit;
  final String currency;
  final String? color;
  final String? icon;
  final bool isActive;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    this.creditLimit,
    this.currency = 'IDR',
    this.color,
    this.icon,
    this.isActive = true,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      type: json['type'] ?? 'cash',
      initialBalance: double.tryParse(json['initial_balance']?.toString() ?? '0') ?? 0.0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      creditLimit: json['credit_limit'] != null ? double.tryParse(json['credit_limit'].toString()) : null,
      currency: json['currency'] ?? 'IDR',
      color: json['color'],
      icon: json['icon'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'bank':
        return 'Rekening Bank';
      case 'e-wallet':
        return 'Dompet Digital';
      case 'cash':
        return 'Uang Tunai';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'investment':
        return 'Investasi';
      default:
        return 'Akun';
    }
  }
}

