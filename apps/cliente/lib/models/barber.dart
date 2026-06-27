class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.shopName,
    required this.imageUrl,
    required this.rating,
    required this.startingPrice,
    required this.bio,
    this.categoryIds = const [],
  });

  final String id;
  final String name;
  final String shopName;
  final String imageUrl;
  final double rating;
  final double startingPrice;
  final String bio;
  final List<String> categoryIds;

  factory Barber.fromMap(Map<String, dynamic> map) {
    return Barber(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      shopName: map['barber_shops']?['name'] ?? map['shop_name'] ?? '',
      imageUrl: map['photo_url'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      startingPrice: (map['starting_price'] ?? 0).toDouble(),
      bio: map['bio'] ?? '',
      categoryIds: (map['category_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
