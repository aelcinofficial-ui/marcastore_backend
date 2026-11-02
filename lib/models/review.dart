class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isApproved;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    DateTime? createdAt,
    this.isApproved = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userImage,
    double? rating,
    String? comment,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImage: json['userImage'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isApproved: json['isApproved'] ?? true,
    );
  }
}
