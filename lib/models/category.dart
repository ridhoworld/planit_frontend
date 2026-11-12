class Category {
  final int id;
  final int? parentId;
  final String name;
  final String type; // income, expense
  final String? icon;
  final String? color;
  final bool isActive;
  final List<Category> children;

  Category({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isActive = true,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    var rawChildren = json['children'] as List<dynamic>? ?? [];
    List<Category> parsedChildren = rawChildren.map((c) => Category.fromJson(c)).toList();

    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'],
      color: json['color'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      children: parsedChildren,
    );
  }
}

