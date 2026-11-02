import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../services/services.dart';

enum AppLanguage { az, en, ru }

class AppProvider with ChangeNotifier {
  static const FlutterSecureStorage _authStorage = FlutterSecureStorage();
  final DataService _dataService = DataService();
  final Map<String, User> _registeredUsers = {};
  final Map<String, String> _authCredentials = {};
  bool _isLoadingProducts = false;
  bool _productsLoaded = false;
  String? _productsLoadError;
  bool _isLoadingOrders = false;
  String? _ordersLoadError;
  final List<Order> _djangoOrders = [];
  String? _accessToken;
  String? _authError;

  // Language support (default Azerbaijani)
  AppLanguage _language = AppLanguage.az;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  // Cart
  final List<CartItem> _cartItems = [];

  // Getters
  DataService get dataService => _dataService;
  List<Product> get products => _dataService.products;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get productsLoaded => _productsLoaded;
  String? get productsLoadError => _productsLoadError;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersLoadError => _ordersLoadError;
  String? get authError => _authError;
  List<Map<String, String>> get categories => _dataService.categories;
  List<String> get bannerImages => _dataService.bannerImages;
  List<String> get bannerTitles => _dataService.bannerTitles;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  User? get currentUser => _dataService.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get accessToken => _accessToken;
  bool get isAdmin => currentUser?.role == UserRole.admin;
  bool get isVendor =>
      currentUser?.role == UserRole.vendor && vendorShop != null;
  Shop? get vendorShop => currentUser == null
      ? null
      : _dataService.getShopForOwner(currentUser!.id);
  List<Shop> get pendingShops => _dataService.pendingShops;
  List<Shop> get approvedShops => _dataService.shops
      .where((shop) => shop.status == ShopStatus.approved)
      .toList();

  List<Product> getProductsForShop(String shopId) =>
      _dataService.getProductsForShop(shopId);

  Future<void> loadProductsFromDjango() async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _productsLoadError = null;
    notifyListeners();

    try {
      final records = await ApiService.getProducts();
      final products = records.map((record) {
        if (record is! Map) {
          throw const FormatException('Django məhsul məlumatı düzgün deyil.');
        }
        return Product.fromJson(Map<String, dynamic>.from(record));
      }).toList();
      _dataService.replaceProducts(products);
    } catch (error) {
      _productsLoadError = error.toString();
    } finally {
      _isLoadingProducts = false;
      _productsLoaded = true;
      notifyListeners();
    }
  }

  Future<void> registerWithDjango({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    await _acceptAuthResponse(response);
  }

  Future<void> loginWithDjango({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.login(email: email, password: password);
    await _acceptAuthResponse(response);
  }

  Future<void> loginWithSocialProvider({
    required String provider,
    required String token,
    String? name,
  }) async {
    final response = await ApiService.socialLogin(
      provider: provider,
      token: token,
      name: name,
    );
    await _acceptAuthResponse(response);
  }

  Future<void> _acceptAuthResponse(Map<String, dynamic> response) async {
    final access = response['access'] as String;
    final refresh = response['refresh'] as String;
    final profile = Map<String, dynamic>.from(response['user'] as Map);
    final user = _userFromAuthProfile(profile);

    await _authStorage.write(key: 'django_access_token', value: access);
    await _authStorage.write(key: 'django_refresh_token', value: refresh);
    _accessToken = access;
    _authError = null;
    setCurrentUser(user);
  }

  User _userFromAuthProfile(Map<String, dynamic> profile) {
    final name = profile['name']?.toString() ?? '';
    final firstName =
        profile['first_name']?.toString() ??
        (name.contains(' ') ? name.split(' ').first : name);
    final lastName =
        profile['last_name']?.toString() ??
        (name.contains(' ') ? name.split(' ').skip(1).join(' ') : '');
    return User(
      id: profile['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      email: profile['email']?.toString() ?? '',
      phoneNumber: profile['phone']?.toString(),
    );
  }

  Future<void> restoreDjangoSession() async {
    try {
      final refresh = await _authStorage.read(key: 'django_refresh_token');
      if (refresh == null || refresh.isEmpty) return;

      final tokenResponse = await ApiService.refreshAccessToken(refresh);
      final access = tokenResponse['access'] as String;
      final nextRefresh = tokenResponse['refresh'] as String? ?? refresh;
      final profile = await ApiService.getCurrentUser(access);
      await _authStorage.write(key: 'django_access_token', value: access);
      await _authStorage.write(key: 'django_refresh_token', value: nextRefresh);
      _accessToken = access;
      _authError = null;
      setCurrentUser(_userFromAuthProfile(profile));
    } catch (error) {
      _authError = error.toString();
      await _clearAuthSession();
      _dataService.logout();
      notifyListeners();
    }
  }

  Future<void> _clearAuthSession() async {
    await _authStorage.delete(key: 'django_access_token');
    await _authStorage.delete(key: 'django_refresh_token');
    _accessToken = null;
  }

  double getShopRating(String shopId) {
    final products = getProductsForShop(shopId);
    if (products.isEmpty) return 0;
    return products.fold<double>(
          0,
          (total, product) => total + product.rating,
        ) /
        products.length;
  }

  List<Product> get vendorProducts {
    final shop = vendorShop;
    if (!isVendor || shop?.status != ShopStatus.approved) return [];
    return _dataService.getProductsForShop(shop!.id);
  }

  Shop? get myShop => vendorShop;

  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  // Product methods
  List<Product> getProductsByCategory(String category) {
    return _dataService.getProductsByCategory(category);
  }

  Product? getProductById(String id) {
    return _dataService.getProductById(id);
  }

  bool isFavorite(String productId) {
    return _dataService.isFavorite(productId);
  }

  void toggleFavorite(String productId) {
    _dataService.toggleFavorite(productId);
    notifyListeners();
  }

  bool isLiked(String productId) {
    return _dataService.isLiked(productId);
  }

  void toggleLike(String productId) {
    _dataService.toggleLike(productId);
    notifyListeners();
  }

  List<Product> getFavoriteProducts() {
    return _dataService.getFavoriteProducts();
  }

  // Cart methods
  void addToCart({
    required Product product,
    required int quantity,
    required String selectedSize,
    required String selectedColor,
  }) {
    final existingItem = _cartItems.firstWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == selectedSize &&
          item.selectedColor == selectedColor,
      orElse: () => CartItem(
        product: product,
        quantity: 0,
        selectedSize: '',
        selectedColor: '',
      ),
    );

    if (existingItem.product.id == product.id &&
        existingItem.selectedSize == selectedSize &&
        existingItem.selectedColor == selectedColor) {
      existingItem.quantity += quantity;
    } else {
      _cartItems.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedSize: selectedSize,
          selectedColor: selectedColor,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  void updateCartQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _cartItems.remove(item);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // User methods
  void setCurrentUser(User user) {
    _dataService.setCurrentUser(user);
    notifyListeners();
  }

  void logout() {
    _dataService.logout();
    final hadDjangoSession = _accessToken != null;
    _accessToken = null;
    if (hadDjangoSession) {
      _authStorage
          .delete(key: 'django_access_token')
          .then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Django token cleanup failed: $error');
            },
          );
      _authStorage
          .delete(key: 'django_refresh_token')
          .then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Django refresh-token cleanup failed: $error');
            },
          );
    }
    notifyListeners();
  }

  void updateCurrentUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    String? address,
  }) {
    _dataService.updateCurrentUser(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
      address: address,
    );
    notifyListeners();
  }

  bool registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return false;
    }

    if (_registeredUsers.containsKey(normalizedEmail)) {
      return false;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalizedEmail,
    );

    _registeredUsers[normalizedEmail] = user;
    _authCredentials[normalizedEmail] = password;
    setCurrentUser(user);
    return true;
  }

  bool loginWithEmail({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    if (_authCredentials[normalizedEmail] == password) {
      final user = _registeredUsers[normalizedEmail];
      if (user != null) {
        setCurrentUser(user);
        return true;
      }
    }
    return false;
  }

  // Order methods
  Order createOrder({
    required String userPhone,
    String? deliveryAddress,
    String? notes,
    List<dynamic>? cartItems,
    double? totalAmount,
  }) {
    if (currentUser == null) {
      throw Exception('İstifadəçi daxil olmayıb');
    }

    final sourceItems = cartItems ?? _cartItems;

    final items = sourceItems.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        productImage: cartItem.product.image,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
        size: cartItem.selectedSize,
        color: cartItem.selectedColor,
      );
    }).toList();

    final order = _dataService.createOrder(
      userId: currentUser!.id,
      userName: currentUser!.fullName,
      userPhone: userPhone,
      items: items,
      totalAmount: totalAmount ?? cartTotal,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );

    clearCart();
    return order;
  }

  Future<Order> submitOrderToDjango({
    required String userPhone,
    required String deliveryAddress,
    required String cartId,
    required List<CartItem> cartItems,
    String? promoCode,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Sifariş vermək üçün istifadəçi daxil olmalıdır.');
    }
    if (cartItems.isEmpty) {
      throw StateError('Səbət boş olduğu üçün sifariş yaratmaq mümkün deyil.');
    }

    final response = await ApiService.createOrder(
      name: user.fullName.trim(),
      email: user.email,
      phone: userPhone,
      deliveryAddress: deliveryAddress,
      cartId: cartId,
      promoCode: promoCode,
      authToken:
          _accessToken ??
          (throw StateError('Sifariş üçün Django hesabına daxil olun.')),
      items: cartItems
          .map(
            (item) => {
              'product': item.product.id,
              'quantity': item.quantity,
              'size': item.selectedSize,
              'color': item.selectedColor,
            },
          )
          .toList(),
    );
    final orderId = response['id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      throw const FormatException('Django sifariş nömrəsini qaytarmadı.');
    }
    final remoteTotal = double.tryParse(
      response['total_price']?.toString() ?? '',
    );
    if (remoteTotal == null) {
      throw const FormatException('Django sifariş məbləğini qaytarmadı.');
    }

    final orderItems = cartItems
        .map(
          (item) => OrderItem(
            productId: item.product.id,
            productName: item.product.name,
            productImage: item.product.image,
            price: item.product.price,
            quantity: item.quantity,
            size: item.selectedSize,
            color: item.selectedColor,
          ),
        )
        .toList();
    final order = _dataService.createOrder(
      orderId: orderId,
      userId: user.id,
      userName: user.fullName,
      userPhone: userPhone,
      items: orderItems,
      totalAmount: remoteTotal,
      deliveryAddress: deliveryAddress,
    );
    clearCart();
    return order;
  }

  List<Order> getMyOrders() {
    if (currentUser == null) return [];
    final ordersById = <String, Order>{
      for (final order in _djangoOrders) order.id: order,
      for (final order in _dataService.getOrdersByUserId(currentUser!.id))
        order.id: order,
    };
    final orders = ordersById.values.toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return orders;
  }

  Future<void> loadOrdersFromDjango() async {
    final user = currentUser;
    final token = _accessToken;
    if (user == null || token == null || _isLoadingOrders) return;

    _isLoadingOrders = true;
    _ordersLoadError = null;
    notifyListeners();
    try {
      final records = await ApiService.getOrders(authToken: token);
      final orders = records.map((record) {
        if (record is! Map) {
          throw const FormatException('Django sifariş məlumatı düzgün deyil.');
        }
        final data = Map<String, dynamic>.from(record);
        final rawItems = data['items'];
        if (rawItems is! List) {
          throw const FormatException(
            'Django sifariş məhsulları düzgün deyil.',
          );
        }
        final items = rawItems.map((rawItem) {
          if (rawItem is! Map) {
            throw const FormatException('Django sifariş sətri düzgün deyil.');
          }
          final item = Map<String, dynamic>.from(rawItem);
          final price = double.tryParse(item['price']?.toString() ?? '');
          if (price == null) {
            throw const FormatException(
              'Sifariş məhsulunun qiyməti yanlışdır.',
            );
          }
          return OrderItem(
            productId: item['product']?.toString() ?? '',
            productName: item['name']?.toString() ?? '',
            productImage: item['image']?.toString() ?? '',
            price: price,
            quantity: int.tryParse(item['quantity']?.toString() ?? '') ?? 0,
            size: item['size']?.toString() ?? '',
            color: item['color']?.toString() ?? '',
          );
        }).toList();
        final total = double.tryParse(data['total_price']?.toString() ?? '');
        if (total == null) {
          throw const FormatException('Django sifariş məbləği düzgün deyil.');
        }
        final status = switch (data['status']?.toString().toLowerCase()) {
          'confirmed' => OrderStatus.confirmed,
          'preparing' => OrderStatus.preparing,
          'delivered to courier' => OrderStatus.deliveredToCourier,
          'delivered' => OrderStatus.delivered,
          'cancelled' => OrderStatus.cancelled,
          _ => OrderStatus.pending,
        };
        return Order(
          id: data['id']?.toString() ?? '',
          userId: user.id,
          userName: user.fullName,
          userPhone: user.phoneNumber ?? user.email,
          items: items,
          totalAmount: total,
          status: status,
          deliveryAddress: data['delivery_address']?.toString(),
          createdAt: data['created_at'] == null
              ? DateTime.now()
              : DateTime.parse(data['created_at'].toString()),
        );
      }).toList();
      _djangoOrders
        ..clear()
        ..addAll(orders);
    } catch (error) {
      _ordersLoadError = error.toString();
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // Admin methods
  List<Order> getAllOrders() {
    return _dataService.orders;
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    _dataService.updateOrderStatus(orderId, status);
    notifyListeners();
  }

  void addProduct(Product product) {
    _dataService.addProduct(product);
    notifyListeners();
  }

  void removeProduct(String productId) {
    _dataService.removeProduct(productId);
    notifyListeners();
  }

  void updateProduct(Product product) {
    _dataService.updateProduct(product);
    notifyListeners();
  }

  Shop submitShopApplication({
    required String shopName,
    required String logo,
    required String description,
  }) {
    final shop = _dataService.submitShopApplication(
      shopName: shopName,
      logo: logo,
      description: description,
    );
    notifyListeners();
    return shop;
  }

  void reviewShopApplication(String shopId, {required bool approve}) {
    _dataService.reviewShopApplication(shopId, approve: approve);
    if (approve) {
      final shop = _dataService.shops.firstWhere((item) => item.id == shopId);
      final owner = _dataService.getUserById(shop.ownerId);
      if (owner != null) _registeredUsers[owner.email] = owner;
    }
    notifyListeners();
  }

  void addVendorProduct(Product product) {
    _dataService.addVendorProduct(product);
    notifyListeners();
  }

  void updateVendorProduct(Product product) {
    _dataService.updateVendorProduct(product);
    notifyListeners();
  }

  void removeVendorProduct(String productId) {
    _dataService.removeVendorProduct(productId);
    notifyListeners();
  }

  void addCategory(String name, String icon) {
    _dataService.addCategory({
      'name': name.trim(),
      'icon': icon.trim().isEmpty ? '📦' : icon.trim(),
    });
    notifyListeners();
  }

  void removeCategory(String categoryName) {
    _dataService.removeCategory(categoryName);
    notifyListeners();
  }

  void updateCategory(String oldName, String newName, String icon) {
    _dataService.updateCategory(oldName, newName, icon);
    notifyListeners();
  }

  void addBannerImage(String imageUri) {
    _dataService.addBannerImage(imageUri);
    notifyListeners();
  }

  void removeBannerImage(String imageUri) {
    _dataService.removeBannerImage(imageUri);
    notifyListeners();
  }

  // Complaint methods
  List<Complaint> getAllComplaints() {
    return _dataService.complaints;
  }

  void createComplaint({
    required ComplaintType type,
    required String subject,
    required String description,
    String? orderId,
    String? productId,
  }) {
    if (currentUser == null) return;

    _dataService.createComplaint(
      userId: currentUser!.id,
      userName: currentUser!.fullName,
      type: type,
      subject: subject,
      description: description,
      orderId: orderId,
      productId: productId,
    );
    notifyListeners();
  }

  void updateComplaintStatus(
    String complaintId,
    ComplaintStatus status, {
    String? adminResponse,
  }) {
    _dataService.updateComplaintStatus(
      complaintId,
      status,
      adminResponse: adminResponse,
    );
    notifyListeners();
  }

  // Review methods
  List<Review> getProductReviews(String productId) {
    return _dataService.getReviewsByProductId(productId);
  }

  void addReview({
    required String productId,
    required double rating,
    required String comment,
  }) {
    if (currentUser == null) return;

    _dataService.createReview(
      productId: productId,
      userId: currentUser!.id,
      userName: currentUser!.fullName,
      rating: rating,
      comment: comment,
      userImage: currentUser!.profileImage,
    );
    notifyListeners();
  }

  // Notification methods
  List<Notification> getMyNotifications() {
    if (currentUser == null) return [];
    return _dataService.getNotificationsByUserId(currentUser!.id);
  }

  int getUnreadNotificationCount() {
    if (currentUser == null) return 0;
    return _dataService.getUnreadNotificationCount(currentUser!.id);
  }

  void markNotificationAsRead(String notificationId) {
    _dataService.markNotificationAsRead(notificationId);
    notifyListeners();
  }
}

// Cart Item model for the provider
class CartItem {
  final Product product;
  int quantity;
  String selectedSize;
  String selectedColor;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize = 'M',
    this.selectedColor = 'Black',
  });
}
