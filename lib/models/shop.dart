enum ShopStatus { pending, approved, rejected }

class Shop {
  final String id;
  final String ownerId;
  final String shopName;
  final String logo;
  final String description;
  final ShopStatus status;

  const Shop({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.logo,
    required this.description,
    this.status = ShopStatus.pending,
  });

  Shop copyWith({
    String? shopName,
    String? logo,
    String? description,
    ShopStatus? status,
  }) {
    return Shop(
      id: id,
      ownerId: ownerId,
      shopName: shopName ?? this.shopName,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'shop_name': shopName,
    'logo': logo,
    'description': description,
    'status': status.name,
  };

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: ShopStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ShopStatus.pending,
      ),
    );
  }
}
