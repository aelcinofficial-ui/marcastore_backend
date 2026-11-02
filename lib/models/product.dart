class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final List<String> images;
  final String? shopId;
  final String category;
  final double rating;
  final List<String> sizes;
  final List<String> colors;
  final bool isFavorite;
  final int likeCount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    this.images = const [],
    this.shopId,
    required this.category,
    this.rating = 4.5,
    this.sizes = const ['S', 'M', 'L', 'XL'],
    this.colors = const ['Black', 'White', 'Blue'],
    this.isFavorite = false,
    this.likeCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    List<String>? images,
    String? shopId,
    String? category,
    double? rating,
    List<String>? sizes,
    List<String>? colors,
    bool? isFavorite,
    int? likeCount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      images: images ?? this.images,
      shopId: shopId ?? this.shopId,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      isFavorite: isFavorite ?? this.isFavorite,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'images': images,
      'shop_id': shopId,
      'category': category,
      'rating': rating,
      'sizes': sizes,
      'colors': colors,
      'isFavorite': isFavorite,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');
    if (price == null) {
      throw const FormatException('Məhsulun qiyməti düzgün deyil.');
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: price,
      image: json['image']?.toString() ?? '',
      images: List<String>.from(json['images'] ?? []),
      shopId: (json['shop_id'] ?? json['shopId'] ?? json['shop'])?.toString(),
      category: json['category']?.toString() ?? 'Ümumi',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
