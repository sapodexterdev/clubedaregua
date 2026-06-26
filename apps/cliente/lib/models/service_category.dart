class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final String icon;

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'content_cut',
    );
  }
}
