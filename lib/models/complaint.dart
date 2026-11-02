enum ComplaintStatus { pending, inProgress, resolved, rejected }

extension ComplaintStatusExtension on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Gözləyir';
      case ComplaintStatus.inProgress:
        return 'Araşdırılır';
      case ComplaintStatus.resolved:
        return 'Həll edildi';
      case ComplaintStatus.rejected:
        return 'Rədd edildi';
    }
  }
}

enum ComplaintType { productQuality, delivery, payment, other }

extension ComplaintTypeExtension on ComplaintType {
  String get label {
    switch (this) {
      case ComplaintType.productQuality:
        return 'Məhsul keyfiyyəti';
      case ComplaintType.delivery:
        return 'Çatdırılma';
      case ComplaintType.payment:
        return 'Ödəniş';
      case ComplaintType.other:
        return 'Digər';
    }
  }
}

class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String? orderId;
  final String? productId;
  final ComplaintType type;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  Complaint({
    required this.id,
    required this.userId,
    required this.userName,
    this.orderId,
    this.productId,
    required this.type,
    required this.subject,
    required this.description,
    this.status = ComplaintStatus.pending,
    this.adminResponse,
    DateTime? createdAt,
    this.updatedAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Complaint copyWith({
    String? id,
    String? userId,
    String? userName,
    String? orderId,
    String? productId,
    ComplaintType? type,
    String? subject,
    String? description,
    ComplaintStatus? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'productId': productId,
      'type': type.index,
      'subject': subject,
      'description': description,
      'status': status.index,
      'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      orderId: json['orderId'],
      productId: json['productId'],
      type: ComplaintType.values.firstWhere(
        (t) => t.index == (json['type'] ?? 3),
        orElse: () => ComplaintType.other,
      ),
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: ComplaintStatus.values.firstWhere(
        (s) => s.index == (json['status'] ?? 0),
        orElse: () => ComplaintStatus.pending,
      ),
      adminResponse: json['adminResponse'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
    );
  }
}
