class Investment {
  final int id;
  final String name;
  final String type; // stock, mutual_fund, gold, crypto, property
  final double units;
  final double avgBuyPrice;
  final double currentPrice;
  final double totalInvested;
  final double currentValue;
  final double unrealizedGainLoss;
  final double unrealizedGainLossPercentage;
  final String? lastPriceUpdatedAt;
  final String? notes;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.units,
    required this.avgBuyPrice,
    required this.currentPrice,
    required this.totalInvested,
    required this.currentValue,
    required this.unrealizedGainLoss,
    required this.unrealizedGainLossPercentage,
    this.lastPriceUpdatedAt,
    this.notes,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      type: json['type'] ?? 'stock',
      units: double.tryParse(json['units']?.toString() ?? '0') ?? 0.0,
      avgBuyPrice: double.tryParse(json['avg_buy_price']?.toString() ?? '0') ?? 0.0,
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '0') ?? 0.0,
      totalInvested: double.tryParse(json['total_invested']?.toString() ?? '0') ?? 0.0,
      currentValue: double.tryParse(json['current_value']?.toString() ?? '0') ?? 0.0,
      unrealizedGainLoss: double.tryParse(json['unrealized_gain_loss']?.toString() ?? '0') ?? 0.0,
      unrealizedGainLossPercentage: double.tryParse(json['unrealized_gain_loss_percentage']?.toString() ?? '0') ?? 0.0,
      lastPriceUpdatedAt: json['last_price_updated_at'],
      notes: json['notes'],
    );
  }

  String get typeLabel {
    switch (type) {
      case 'stock':
        return 'Saham';
      case 'mutual_fund':
        return 'Reksadana';
      case 'gold':
        return 'Emas';
      case 'crypto':
        return 'Kripto';
      case 'property':
        return 'Properti';
      default:
        return 'Aset';
    }
  }
}

