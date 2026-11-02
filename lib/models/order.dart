enum OrderStatus {
  pending,
  confirmed,
  preparing,
  deliveredToCourier,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Gözləyir';
      case OrderStatus.confirmed:
        return 'Təsdiqləndi';
      case OrderStatus.preparing:
        return 'Hazırlanır';
      case OrderStatus.deliveredToCourier:
        return 'Kuryerə təhvil verildi';
      case OrderStatus.delivered:
        return 'Çatdırıldı';
      case OrderStatus.cancelled:
        return 'Ləğv edildi';
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String size;
  final String color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String? deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.deliveryAddress,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.deliveredAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    String? deliveryAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.index,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.index == (json['status'] ?? 0),
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: json['deliveryAddress'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
    );
  }
}
