enum UserRole { user, vendor, admin }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String? address;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.address,
    this.role = UserRole.user,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? address,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'address': address,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'];
    final parsedRole = rawRole is String
        ? UserRole.values.firstWhere(
            (role) => role.name == rawRole,
            orElse: () => UserRole.user,
          )
        : rawRole == 1
        ? UserRole.admin
        : UserRole.user;
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      address: json['address'],
      role: parsedRole,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }
}
