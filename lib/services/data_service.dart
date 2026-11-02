import '../models/models.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Sample products data
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Nike Air Max',
      description:
          'Rahat və şıq idman ayaqqabısı. Hər addımda maksimum rahatlıq təmin edir. Yüksək keyfiyyətli materiallardan hazırlanmışdır.',
      price: 189.99,
      image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
      category: 'İdman',
      rating: 4.8,
      sizes: ['38', '39', '40', '41', '42', '43', '44'],
      colors: ['Qırmızı', 'Ağ', 'Qara'],
    ),
    Product(
      id: '2',
      name: 'Klassik Dəri Kurtka',
      description:
          'Premium dəri materialdan hazırlanmış şıq kurtka. Hər mövsüm istifadə edilə bilər.',
      price: 349.99,
      image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
      category: 'Kişi',
      rating: 4.6,
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Qara', 'Qəhvəyi'],
    ),
    Product(
      id: '3',
      name: 'Zərif Yay Paltarı',
      description:
          'Yüngül və rahat parçadan hazırlanmış yay paltarı. Xüsusi günlər üçün ideal seçim.',
      price: 89.99,
      image:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400',
      category: 'Qadın',
      rating: 4.9,
      sizes: ['XS', 'S', 'M', 'L'],
      colors: ['Göy', 'Çəhrayı', 'Ağ'],
    ),
    Product(
      id: '4',
      name: 'Adidas Running',
      description:
          'Peşəkar qaçış ayaqqabısı. Əla amortizasiya və dəstək təmin edir.',
      price: 159.99,
      image:
          'https://images.unsplash.com/photo-1587560699334-cc4da63c4928?w=400',
      category: 'İdman',
      rating: 4.7,
      sizes: ['39', '40', '41', '42', '43', '44', '45'],
      colors: ['Qara', 'Boz', 'Yaşıl'],
    ),
    Product(
      id: '5',
      name: 'Oxford Köynək',
      description:
          'Klassik Oxford köynək. İş və rəsmi görüşlər üçün mükəmməl seçim.',
      price: 69.99,
      image:
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400',
      category: 'Kişi',
      rating: 4.5,
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Ağ', 'Göy', 'Çəhrayı'],
    ),
    Product(
      id: '6',
      name: 'Designer Çanta',
      description:
          'Premium dəri çanta. Geniş bölmələri ilə gündəlik istifadə üçün idealdır.',
      price: 249.99,
      image:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400',
      category: 'Qadın',
      rating: 4.8,
      colors: ['Qara', 'Bej', 'Qırmızı'],
    ),
    Product(
      id: '7',
      name: 'Sport Hoodie',
      description:
          'Rahat və isti hoodie. Gündəlik istifadə və idman üçün uyğundur.',
      price: 79.99,
      image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400',
      category: 'İdman',
      rating: 4.4,
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Boz', 'Qara', 'Göy'],
    ),
    Product(
      id: '8',
      name: 'Yun Şarf',
      description: 'Yumşaq yun şarf. Soyuk hava üçün ideal aksesuar.',
      price: 39.99,
      image:
          'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=400',
      category: 'Qadın',
      rating: 4.6,
      colors: ['Qırmızı', 'Boz', 'Krem'],
    ),
  ];

  // Categories
  final List<Map<String, String>> _categories = [
    {'name': 'Geyim', 'icon': '👚'},
    {'name': 'Kofta', 'icon': '👕'},
    {'name': 'Etek', 'icon': '👗'},
    {'name': 'Şalvar', 'icon': '👖'},
    {'name': 'Kişi', 'icon': '👔'},
    {'name': 'Qadın', 'icon': '👗'},
    {'name': 'İdman', 'icon': '👟'},
    {'name': 'Aksesuar', 'icon': '👜'},
  ];

  // Banners
  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
    'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800',
  ];

  final List<String> _bannerTitles = [
    'Yay Endirimi - 50%',
    'Yeni Kolksiya',
    'Premium Keyfiyyət',
  ];

  // In-memory storage
  final List<Order> _orders = [];
  final List<Complaint> _complaints = [];
  final List<Review> _reviews = [];
  final List<Notification> _notifications = [];
  final List<Shop> _shops = [];
  final Map<String, User> _knownUsers = {};
  final Set<String> _favoriteProductIds = {};
  final Set<String> _likedProductIds = {};

  // Current user (simulated)
  User? _currentUser;

  // Getters
  List<Product> get products => List.unmodifiable(_products);

  void replaceProducts(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
  }

  List<Map<String, String>> get categories => List.unmodifiable(_categories);
  List<String> get bannerImages => List.unmodifiable(_bannerImages);
  List<String> get bannerTitles => List.unmodifiable(_bannerTitles);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Complaint> get complaints => List.unmodifiable(_complaints);
  List<Review> get reviews => List.unmodifiable(_reviews);
  List<Notification> get notifications => List.unmodifiable(_notifications);
  List<Shop> get shops => List.unmodifiable(_shops);
  Set<String> get favoriteProductIds => Set.unmodifiable(_favoriteProductIds);
  Set<String> get likedProductIds => Set.unmodifiable(_likedProductIds);
  User? get currentUser => _currentUser;
  User? getUserById(String userId) => _knownUsers[userId];
  Shop? getShopForOwner(String ownerId) {
    for (final shop in _shops.reversed) {
      if (shop.ownerId == ownerId) return shop;
    }
    return null;
  }

  List<Shop> get pendingShops =>
      _shops.where((shop) => shop.status == ShopStatus.pending).toList();

  List<Product> getProductsForShop(String shopId) =>
      _products.where((product) => product.shopId == shopId).toList();

  Shop submitShopApplication({
    required String shopName,
    required String logo,
    required String description,
  }) {
    final user = _currentUser;
    if (user == null || user.role != UserRole.user) {
      throw StateError('Satıcı müraciəti üçün istifadəçi hesabı tələb olunur.');
    }

    final existing = getShopForOwner(user.id);
    if (existing?.status == ShopStatus.pending ||
        existing?.status == ShopStatus.approved) {
      throw StateError('Bu hesab üçün artıq aktiv mağaza müraciəti var.');
    }

    final shop = Shop(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      ownerId: user.id,
      shopName: shopName.trim(),
      logo: logo.trim(),
      description: description.trim(),
    );
    if (existing == null) {
      _shops.add(shop);
    } else {
      _shops[_shops.indexOf(existing)] = shop;
    }
    return shop;
  }

  void reviewShopApplication(String shopId, {required bool approve}) {
    if (_currentUser?.role != UserRole.admin) {
      throw StateError('Bu əməliyyat yalnız admin üçün əlçatandır.');
    }
    final index = _shops.indexWhere((shop) => shop.id == shopId);
    if (index == -1 || _shops[index].status != ShopStatus.pending) {
      throw StateError('Gözləyən mağaza müraciəti tapılmadı.');
    }
    final shop = _shops[index];
    if (approve) updateUserRole(shop.ownerId, UserRole.vendor);
    _shops[index] = shop.copyWith(
      status: approve ? ShopStatus.approved : ShopStatus.rejected,
    );
  }

  Shop? getApprovedShopForCurrentVendor() {
    final user = _currentUser;
    if (user == null || user.role != UserRole.vendor) return null;
    final shop = getShopForOwner(user.id);
    return shop?.status == ShopStatus.approved ? shop : null;
  }

  void addVendorProduct(Product product) {
    final shop = getApprovedShopForCurrentVendor();
    if (shop == null || product.shopId != shop.id) {
      throw StateError(
        'Yalnız təsdiqlənmiş satıcı öz mağazasına məhsul əlavə edə bilər.',
      );
    }
    _products.add(product);
  }

  void updateVendorProduct(Product product) {
    final shop = getApprovedShopForCurrentVendor();
    final index = _products.indexWhere((item) => item.id == product.id);
    if (shop == null ||
        index == -1 ||
        _products[index].shopId != shop.id ||
        product.shopId != shop.id) {
      throw StateError('Bu məhsulu redaktə etmək icazəniz yoxdur.');
    }
    _products[index] = product;
  }

  void removeVendorProduct(String productId) {
    final shop = getApprovedShopForCurrentVendor();
    final productIndex = _products.indexWhere((item) => item.id == productId);
    final product = productIndex == -1 ? null : _products[productIndex];
    if (shop == null || product == null || product.shopId != shop.id) {
      throw StateError('Bu məhsulu silmək icazəniz yoxdur.');
    }
    _products.removeWhere((item) => item.id == productId);
  }

  void updateUserRole(String userId, UserRole role) {
    final user = _knownUsers[userId];
    if (user == null) {
      throw StateError('Mağaza sahibinin istifadəçi hesabı tapılmadı.');
    }
    final updatedUser = user.copyWith(role: role);
    _knownUsers[userId] = updatedUser;
    if (_currentUser?.id == userId) _currentUser = updatedUser;
  }

  // Product methods
  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void addProduct(Product product) {
    if (_currentUser?.role != UserRole.admin) {
      throw StateError('Məhsul yaratmaq üçün admin icazəsi tələb olunur.');
    }
    _products.add(product);
  }

  void removeProduct(String productId) {
    if (_currentUser?.role != UserRole.admin) {
      throw StateError('Məhsul silmək üçün admin icazəsi tələb olunur.');
    }
    _products.removeWhere((p) => p.id == productId);
  }

  void updateProduct(Product product) {
    if (_currentUser?.role != UserRole.admin) {
      throw StateError('Məhsul redaktə etmək üçün admin icazəsi tələb olunur.');
    }
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  void addCategory(Map<String, String> category) {
    if (category['name'] != null &&
        category['name']!.trim().isNotEmpty &&
        !_categories.any((c) => c['name'] == category['name'])) {
      _categories.add(category);
    }
  }

  void removeCategory(String categoryName) {
    _categories.removeWhere((c) => c['name'] == categoryName);
  }

  void updateCategory(String oldName, String newName, String newIcon) {
    final index = _categories.indexWhere((c) => c['name'] == oldName);
    if (index != -1) {
      _categories[index] = {
        'name': newName.trim().isNotEmpty ? newName : oldName,
        'icon': newIcon.trim().isNotEmpty
            ? newIcon
            : _categories[index]['icon']!,
      };
    }
  }

  void addBannerImage(String imageUri) {
    if (imageUri.trim().isNotEmpty) {
      _bannerImages.add(imageUri.trim());
    }
  }

  void removeBannerImage(String imageUri) {
    _bannerImages.remove(imageUri);
  }

  // Favorite methods
  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
  }

  List<Product> getFavoriteProducts() {
    return _products.where((p) => _favoriteProductIds.contains(p.id)).toList();
  }

  // Like methods
  bool isLiked(String productId) => _likedProductIds.contains(productId);

  void toggleLike(String productId) {
    if (_likedProductIds.contains(productId)) {
      _likedProductIds.remove(productId);
    } else {
      _likedProductIds.add(productId);
    }
  }

  // Order methods
  Order createOrder({
    String? orderId,
    required String userId,
    required String userName,
    required String userPhone,
    required List<OrderItem> items,
    required double totalAmount,
    String? deliveryAddress,
    String? notes,
  }) {
    final order = Order(
      id: orderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      items: items,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
    _orders.add(order);

    // Create notification for user
    _notifications.add(
      Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: NotificationType.orderUpdate,
        title: 'Sifariş qəbul edildi',
        message: 'Sifarişiniz qəbul edildi və tezliklə təsdiqlənəcək.',
      ),
    );

    return order;
  }

  List<Order> getOrdersByUserId(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final updatedOrder = order.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        deliveredAt: status == OrderStatus.delivered ? DateTime.now() : null,
      );
      _orders[index] = updatedOrder;

      // Create notification for user
      _notifications.add(
        Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: order.userId,
          type: NotificationType.orderUpdate,
          title: 'Sifariş statusu yeniləndi',
          message: 'Sifarişinizin statusu: ${status.label}',
          actionId: orderId,
          actionType: 'order',
        ),
      );
    }
  }

  // Complaint methods
  Complaint createComplaint({
    required String userId,
    required String userName,
    required ComplaintType type,
    required String subject,
    required String description,
    String? orderId,
    String? productId,
  }) {
    final complaint = Complaint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      type: type,
      subject: subject,
      description: description,
      orderId: orderId,
      productId: productId,
    );
    _complaints.add(complaint);

    return complaint;
  }

  void updateComplaintStatus(
    String complaintId,
    ComplaintStatus status, {
    String? adminResponse,
  }) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final complaint = _complaints[index];
      final updatedComplaint = complaint.copyWith(
        status: status,
        adminResponse: adminResponse,
        updatedAt: DateTime.now(),
        resolvedAt: status == ComplaintStatus.resolved ? DateTime.now() : null,
      );
      _complaints[index] = updatedComplaint;

      // Create notification for user
      _notifications.add(
        Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: complaint.userId,
          type: NotificationType.complaint,
          title: 'Şikayətinizə cavab',
          message:
              'Şikayətinizin statusu: ${status.label}${adminResponse != null ? "\n$adminResponse" : ""}',
          actionId: complaintId,
          actionType: 'complaint',
        ),
      );
    }
  }

  // Review methods
  Review createReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? userImage,
  }) {
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      rating: rating,
      comment: comment,
    );
    _reviews.add(review);
    return review;
  }

  List<Review> getReviewsByProductId(String productId) {
    return _reviews.where((r) => r.productId == productId).toList();
  }

  List<Review> getReviewsByUserId(String userId) {
    return _reviews.where((r) => r.userId == userId).toList();
  }

  // User methods
  void setCurrentUser(User? user) {
    _currentUser = user;
    if (user != null) _knownUsers[user.id] = user;
  }

  void logout() {
    _currentUser = null;
  }

  void updateCurrentUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    String? address,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        address: address,
      );
      _knownUsers[_currentUser!.id] = _currentUser!;
    }
  }

  List<Notification> getNotificationsByUserId(String userId) {
    return _notifications.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
    }
  }

  int getUnreadNotificationCount(String userId) {
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  // Sample data getters for compatibility
  List<String> getSampleBannerImages() => _bannerImages;
  List<String> getSampleBannerTitles() => _bannerTitles;
}
