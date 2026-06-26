class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.categoryId,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? categoryId;

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      durationMinutes: map['duration_minutes'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
      categoryId: map['category_id']?.toString(),
    );
  }
}
