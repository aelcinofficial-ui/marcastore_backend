enum NotificationType { orderUpdate, promotion, system, complaint }

extension NotificationTypeExtension on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Sifariş yenilənməsi';
      case NotificationType.promotion:
        return 'Aksiya';
      case NotificationType.system:
        return 'Sistem';
      case NotificationType.complaint:
        return 'Şikayət cavabı';
    }
  }
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? actionId;
  final String? actionType;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    DateTime? createdAt,
    this.actionId,
    this.actionType,
  }) : createdAt = createdAt ?? DateTime.now();

  Notification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? actionId,
    String? actionType,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionId: actionId ?? this.actionId,
      actionType: actionType ?? this.actionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'actionId': actionId,
      'actionType': actionType,
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.index == (json['type'] ?? 2),
        orElse: () => NotificationType.system,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      actionId: json['actionId'],
      actionType: json['actionType'],
    );
  }
}
