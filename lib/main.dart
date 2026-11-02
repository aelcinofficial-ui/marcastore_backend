// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'providers/providers.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/complaint_form.dart';
import 'screens/vendor/shop_application_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/auth_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb && AuthConfig.facebookAppId.isNotEmpty) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: AuthConfig.facebookAppId,
      cookie: true,
      xfbml: true,
      version: 'v18.0',
    );
  }
  runApp(const BrandShoppingApp());
}

void pushAnimated(BuildContext context, Widget page) {
  Navigator.of(context).push(_SlideFadeRoute(page: page));
}

class _SlideFadeRoute extends PageRouteBuilder {
  final Widget page;
  _SlideFadeRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          final fade = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      );
}

Widget productImageWidget(
  String src, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
  Widget? loadingWidget,
}) {
  try {
    if (src.startsWith('http') || src.startsWith('https')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image),
              );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return loadingWidget ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }
    if (src.startsWith('data:')) {
      final comma = src.indexOf(',');
      final base64Str = comma >= 0 ? src.substring(comma + 1) : src;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, width: width, height: height, fit: fit);
    }
  } catch (_) {}
  return Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );
}

// ══════════════════════════════════════════════════════════════
// ORDERS PAGE
// ═════════════════════════════════════════════════════════════=

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<AppProvider>().loadOrdersFromDjango());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final orders = appProvider.getMyOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('Sifarişlərim')),
      body: appProvider.isLoadingOrders && orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
              child: Text(
                appProvider.ordersLoadError == null
                    ? 'Heç bir sifariş tapılmadı'
                    : 'Sifarişləri Django-dan yükləmək mümkün olmadı:\n'
                          '${appProvider.ordersLoadError}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appProvider.ordersLoadError == null
                      ? Colors.grey[600]
                      : Colors.red,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    title: Text('Sifariş #${order.id}'),
                    subtitle: Text(
                      '${order.itemCount} məhsul • ${order.status.label}',
                    ),
                    trailing: Text(
                      '${order.totalAmount.toStringAsFixed(2)} AZN',
                    ),
                    onTap: () {
                      pushAnimated(
                        context,
                        Scaffold(
                          appBar: AppBar(title: const Text('Sifariş detayı')),
                          body: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sifariş ID: ${order.id}'),
                                const SizedBox(height: 8),
                                Text('Status: ${order.status.label}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Ümumi: ${order.totalAmount.toStringAsFixed(2)} AZN',
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Məhsullar:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: order.items.length,
                                    itemBuilder: (c, i) {
                                      final it = order.items[i];
                                      return ListTile(
                                        leading: SizedBox(
                                          width: 48,
                                          child: productImageWidget(
                                            it.productImage,
                                          ),
                                        ),
                                        title: Text(it.productName),
                                        subtitle: Text(
                                          '${it.size} / ${it.color} • ${it.quantity}x',
                                        ),
                                        trailing: Text(
                                          '${it.total.toStringAsFixed(2)} AZN',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SAMPLE DATA
// ══════════════════════════════════════════════════════════════

class SampleData {
  static final List<String> bannerImages = [
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
    'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800',
  ];

  static final List<String> bannerTitles = [
    'Yay Endirimi - 50%',
    'Yeni Kolksiya',
    'Premium Keyfiyyət',
  ];

  static final List<Product> products = [
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

  static final List<Map<String, String>> categories = [
    {'name': 'Ayaqqabı', 'icon': '👟'},
    {'name': 'Çantalar', 'icon': '👜'},
    {'name': 'Aksesuar', 'icon': '🧢'},
    {'name': 'Kəmərlər', 'icon': '🔗'},
    {'name': 'Kişi', 'icon': '👔'},
    {'name': 'Qadın', 'icon': '👗'},
    {'name': 'İdman', 'icon': '🏃‍♂️'},
  ];

  static final List<String> brands = [
    'Dior',
    'Chanel',
    'Lora Piano',
    'Balenciaga',
    'Louis Vuitton',
    'Prada',
    'Christian Louboutin',
    'Gucci',
    'Jimmy Choo',
  ];
}

// ══════════════════════════════════════════════════════════════
// MAIN APP WIDGET
// ══════════════════════════════════════════════════════════════

class BrandShoppingApp extends StatelessWidget {
  const BrandShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'BrandShopping',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          primaryColor: const Color(0xFF6C63FF),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFFFF6584),
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.black87),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          fontFamily: 'Segoe UI',
          useMaterial3: true,
        ),
        routes: {'/home': (context) => const HomePage()},
        home: const SplashScreen(),
      ),
    );
  }
}

class AnimatedBrandLabel extends StatefulWidget {
  const AnimatedBrandLabel({super.key});

  @override
  State<AnimatedBrandLabel> createState() => _AnimatedBrandLabelState();
}

class _AnimatedBrandLabelState extends State<AnimatedBrandLabel>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    final entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(entrance);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(entrance);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final progress = _shimmerController.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.5 + (3 * progress), 0),
                end: Alignment(-0.5 + (3 * progress), 0),
                colors: const [
                  Color(0xFF5746C8),
                  Color(0xFFD8B875),
                  Color(0xFF8F68C9),
                ],
                stops: const [0.2, 0.5, 0.8],
              ).createShader(bounds),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_rounded, size: 21),
                  SizedBox(width: 8),
                  Text(
                    'BrandShopping',
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<AppProvider>().restoreDjangoSession());
      }
    });

    _navigationTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            ),
            child: const Text(
              'BrandShopping',
              style: TextStyle(
                fontSize: 40,
                letterSpacing: 3,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME PAGE
// ══════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_onCartChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AppProvider>().loadProductsFromDjango());
      unawaited(_cartManager.initialize());
    });
  }

  void _onCartChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeContent(cartManager: _cartManager),
          CategoryPage(cartManager: _cartManager),
          CartPage(cartManager: _cartManager),
          const ProfilePage(),
          StoresPage(cartManager: _cartManager),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, 0),
              activeIcon: _buildNavIcon(Icons.home, 0),
              label: 'Ana Səhifə',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.category_outlined, 1),
              activeIcon: _buildNavIcon(Icons.category, 1),
              label: 'Kateqoriyalar',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  _buildNavIcon(Icons.shopping_cart_outlined, 2),
                  if (_cartManager.cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6584),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_cartManager.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  _buildNavIcon(Icons.shopping_cart, 2),
                  if (_cartManager.cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6584),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_cartManager.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Səbət',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outlined, 3),
              activeIcon: _buildNavIcon(Icons.person, 3),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.storefront_outlined, 4),
              activeIcon: _buildNavIcon(Icons.storefront, 4),
              label: 'Mağazalar',
            ),
          ],
        ),
      ),
    );
  }

  Icon _buildNavIcon(IconData icon, int index) {
    return Icon(
      icon,
      color: _selectedIndex == index ? const Color(0xFF6C63FF) : Colors.grey,
      size: 24,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME CONTENT
// ══════════════════════════════════════════════════════════════

class HomeContent extends StatefulWidget {
  final CartManager cartManager;

  const HomeContent({super.key, required this.cartManager});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final PageController _bannerController = PageController(
    viewportFraction: 0.92,
  );
  String _searchQuery = '';

  CartManager get cartManager => widget.cartManager;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final filteredProducts = _searchQuery.trim().isEmpty
        ? appProvider.products
        : appProvider.products.where((product) {
            final query = _searchQuery.toLowerCase();
            return product.name.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query);
          }).toList();

    final premiumProducts = appProvider.products
        .where((product) => product.price >= 150)
        .toList();
    final popularProducts = List<Product>.from(appProvider.products)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverToBoxAdapter(child: _buildHeader(context)),

          if (appProvider.productsLoadError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Django məhsulları yüklənmədi: '
                  '${appProvider.productsLoadError}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (appProvider.productsLoaded && appProvider.products.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Django bazasında məhsul yoxdur. Admin paneldə mağaza və '
                  'məhsul yaradın, sonra tətbiqi yeniləyin.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          // Banner Carousel
          SliverToBoxAdapter(child: _buildBannerCarousel(appProvider)),

          // Categories
          SliverToBoxAdapter(child: _buildCategories(context, appProvider)),

          // Brands
          SliverToBoxAdapter(child: _buildBrands(context)),

          // Approved shops
          SliverToBoxAdapter(child: _buildShops(context, appProvider)),

          // Premium Products
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Premium Məhsullar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Hamısına bax',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: premiumProducts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = premiumProducts[index];
                  return SizedBox(
                    width: 200,
                    child: _buildProductCard(context, product),
                  );
                },
              ),
            ),
          ),

          // Popular Products
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Populyar Məhsullar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Hamısına bax',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: popularProducts.length >= 4
                    ? 4
                    : popularProducts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = popularProducts[index];
                  return SizedBox(
                    width: 200,
                    child: _buildProductCard(context, product),
                  );
                },
              ),
            ),
          ),

          // Products Grid
          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Axtarışa uyğun məhsul tapılmadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Zəhmət olmasa başqa sözlərlə yenidən cəhd edin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(context, product);
                }, childCount: filteredProducts.length),
              ),
            ),

          // Bottom padding for navigation
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final userName = context.watch<AppProvider>().currentUser?.firstName.trim();
    final greetingName = userName == null || userName.isEmpty
        ? 'Qonaq'
        : userName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AnimatedBrandLabel()),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEDEAF6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29254A).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Bildirişlər',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF5146D8),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Text(
                'Salam, $greetingName',
                style: const TextStyle(
                  color: Color(0xFF454451),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Sizin üçün seçdik',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF29254A).withValues(alpha: 0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Məhsul, brend və ya kateqoriya axtar',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6C63FF),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEDEAF6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C63FF),
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrands(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Brendlər',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final brand = SampleData.brands[index];
              return GestureDetector(
                onTap: () {
                  pushAnimated(
                    context,
                    Scaffold(
                      appBar: AppBar(title: Text(brand)),
                      body: Center(child: Text('$brand kolleksiyası')),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.05 * 255).round()),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      brand,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: SampleData.brands.length,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildShops(BuildContext context, AppProvider appProvider) {
    final shops = appProvider.approvedShops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mağazalar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (shops.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoresPage(cartManager: cartManager),
                      ),
                    );
                  },
                  child: const Text('Hamısına bax'),
                ),
            ],
          ),
        ),
        if (shops.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Təsdiqlənmiş mağazalar burada görünəcək.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          SizedBox(
            height: 145,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: shops.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shop = shops[index];
                final rating = appProvider.getShopRating(shop.id);
                return SizedBox(
                  width: 124,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => pushAnimated(
                        context,
                        ShopProfilePage(shop: shop, cartManager: cartManager),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: shop.logo.trim().isEmpty
                                  ? Container(
                                      width: 58,
                                      height: 58,
                                      color: const Color(0xFFF1EFFF),
                                      child: const Icon(
                                        Icons.storefront,
                                        color: Color(0xFF6C63FF),
                                        size: 30,
                                      ),
                                    )
                                  : productImageWidget(
                                      shop.logo,
                                      width: 58,
                                      height: 58,
                                      errorWidget: Container(
                                        width: 58,
                                        height: 58,
                                        color: const Color(0xFFF1EFFF),
                                        child: const Icon(
                                          Icons.storefront,
                                          color: Color(0xFF6C63FF),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              shop.shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                Text(
                                  rating == 0
                                      ? 'Yeni'
                                      : rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBannerCarousel(AppProvider appProvider) {
    return SizedBox(
      height: 208,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: appProvider.bannerImages.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.fromLTRB(7, 4, 7, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF28233D).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    appProvider.bannerImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF),
                              const Color(0xFFFF6584),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white70,
                          size: 50,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 18,
                    right: 18,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appProvider.bannerTitles.length > index
                                    ? appProvider.bannerTitles[index]
                                    : '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => pushAnimated(
                                  context,
                                  CategoryPage(cartManager: cartManager),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.12,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kəşf Et',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 7),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Kateqoriyalar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: appProvider.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = appProvider.categories[index];
              return _buildCategoryCard(category, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    Map<String, String> category,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        pushAnimated(
          context,
          CategoryDetailPage(
            categoryName: category['name']!,
            cartManager: widget.cartManager,
          ),
        );
      },
      child: Container(
        width: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (category['name'] == 'Aksesuar')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?w=200',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(category['icon']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              category['name']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        pushAnimated(
          context,
          ProductDetailPage(product: product, cartManager: cartManager),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: const Color(0xFF29254A).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEDEDF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  productImageWidget(
                    product.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    ),
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (context) {
                        final defaultSize = product.sizes.isNotEmpty
                            ? product.sizes.first
                            : 'M';
                        final defaultColor = product.colors.isNotEmpty
                            ? product.colors.first
                            : 'Black';
                        final inCart = cartManager.cartItems.any(
                          (i) =>
                              i.product.id == product.id &&
                              i.selectedSize == defaultSize &&
                              i.selectedColor == defaultColor,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                cartManager.addToCart(
                                  product: product,
                                  quantity: 1,
                                  selectedSize: defaultSize,
                                  selectedColor: defaultColor,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} səbətə əlavə edildi',
                                    ),
                                    backgroundColor: const Color(0xFF6C63FF),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 16,
                              ),
                              label: Text(
                                inCart ? 'Səbətə əlavə edildi' : 'Səbətə at',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: inCart
                                    ? Colors.white
                                    : const Color(0xFF6C63FF),
                                backgroundColor: inCart
                                    ? Colors.green
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: inCart
                                      ? Colors.green
                                      : const Color(0xFF6C63FF),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            inCart
                                ? Text(
                                    'Səbətə atıldı',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STORES
// ══════════════════════════════════════════════════════════════

class StoresPage extends StatelessWidget {
  final CartManager cartManager;

  const StoresPage({super.key, required this.cartManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mağazalar')),
      body: Consumer<AppProvider>(
        builder: (context, app, child) {
          final shops = app.approvedShops;
          if (shops.isEmpty) {
            return const Center(
              child: Text('Hazırda təsdiqlənmiş mağaza yoxdur.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final shop = shops[index];
              final rating = app.getShopRating(shop.id);
              final productCount = app.getProductsForShop(shop.id).length;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _shopLogo(shop.logo, size: 58),
                  title: Text(
                    shop.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            Text(
                              rating == 0 ? 'Yeni' : rating.toStringAsFixed(1),
                            ),
                            const SizedBox(width: 12),
                            Text('$productCount məhsul'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => pushAnimated(
                    context,
                    ShopProfilePage(shop: shop, cartManager: cartManager),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ShopProfilePage extends StatelessWidget {
  final Shop shop;
  final CartManager cartManager;

  const ShopProfilePage({
    super.key,
    required this.shop,
    required this.cartManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop.shopName)),
      body: Consumer<AppProvider>(
        builder: (context, app, child) {
          final products = app.getProductsForShop(shop.id);
          final rating = app.getShopRating(shop.id);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shopLogo(shop.logo, size: 82),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.shopName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating == 0
                                      ? 'Yeni mağaza'
                                      : rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${products.length} məhsul',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (shop.description.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      shop.description,
                      style: TextStyle(color: Colors.grey[700], height: 1.45),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: products.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('Bu mağazada hələ məhsul yoxdur.'),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = products[index];
                          return GestureDetector(
                            onTap: () => pushAnimated(
                              context,
                              ProductDetailPage(
                                product: product,
                                cartManager: cartManager,
                              ),
                            ),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: productImageWidget(
                                        product.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${product.price.toStringAsFixed(2)} AZN',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6C63FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: products.length),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _shopLogo(String logo, {required double size}) {
  if (logo.trim().isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: productImageWidget(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: _shopLogoPlaceholder(size),
      ),
    );
  }
  return _shopLogoPlaceholder(size);
}

Widget _shopLogoPlaceholder(double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: const Color(0xFFF1EFFF),
    borderRadius: BorderRadius.circular(14),
  ),
  child: const Icon(Icons.storefront, color: Color(0xFF6C63FF), size: 32),
);

// ══════════════════════════════════════════════════════════════
// PRODUCT DETAIL PAGE
// ══════════════════════════════════════════════════════════════

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final CartManager cartManager;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.cartManager,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late String selectedSize;
  late String selectedColor;
  late final AnimationController _colorController;
  late final CurvedAnimation _colorCurve;
  late Animation<Color?> _imageTintAnimation;
  int quantity = 1;
  bool _sizeSelected = false;
  bool _colorSelected = false;
  bool _added = false;

  Color _colorForName(String name) {
    if (name.trim().isEmpty) return Colors.transparent;
    switch (name.trim().toLowerCase()) {
      case 'qara':
      case 'black':
        return const Color(0xFF252525);
      case 'ağ':
      case 'ag':
      case 'white':
        return const Color(0xFFF4F1EA);
      case 'qırmızı':
      case 'qirmizi':
      case 'red':
        return const Color(0xFFD84343);
      case 'göy':
      case 'goy':
      case 'blue':
      case 'navy':
      case 'tünd göy':
        return const Color(0xFF315A9E);
      case 'yaşıl':
      case 'yasil':
      case 'green':
        return const Color(0xFF3D8B68);
      case 'boz':
      case 'gray':
      case 'grey':
        return const Color(0xFF92949A);
      case 'çəhrayı':
      case 'çəhrayi':
      case 'pink':
        return const Color(0xFFE68AA5);
      case 'qəhvəyi':
      case 'qehveyi':
      case 'brown':
        return const Color(0xFF8A5A3C);
      case 'bej':
      case 'beige':
      case 'krem':
      case 'cream':
        return const Color(0xFFD8C5A3);
      case 'bənövşəyi':
      case 'benovseyi':
      case 'purple':
        return const Color(0xFF8661B5);
      case 'sarı':
      case 'sari':
      case 'yellow':
        return const Color(0xFFE6BC45);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  void initState() {
    super.initState();
    selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';
    selectedColor = widget.product.colors.isNotEmpty
        ? widget.product.colors.first
        : '';
    _sizeSelected = widget.product.sizes.isEmpty;
    _colorSelected = widget.product.colors.isEmpty;
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _colorCurve = CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    );
    _imageTintAnimation = ColorTween(
      begin: _colorForName(selectedColor),
      end: _colorForName(selectedColor),
    ).animate(_colorCurve);
  }

  void _selectColor(String color) {
    final currentTint = _imageTintAnimation.value ?? Colors.transparent;
    _imageTintAnimation = ColorTween(
      begin: currentTint,
      end: _colorForName(color),
    ).animate(_colorCurve);
    setState(() {
      selectedColor = color;
      _colorSelected = true;
      _added = false;
    });
    _colorController.forward(from: 0);
  }

  @override
  void dispose() {
    _colorCurve.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final selectionMade =
        (product.sizes.isEmpty || _sizeSelected) &&
        (product.colors.isEmpty || _colorSelected);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with back button
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.black87,
                  ),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${product.id}',
                child: AnimatedBuilder(
                  animation: _colorController,
                  builder: (context, child) => ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      (_imageTintAnimation.value ?? Colors.transparent)
                          .withValues(alpha: 0.18),
                      BlendMode.srcATop,
                    ),
                    child: child,
                  ),
                  child: productImageWidget(
                    product.image,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(108, 99, 255, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (product.colors.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Rəng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF29283A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.25),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            selectedColor,
                            key: ValueKey(selectedColor),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: product.colors.map((color) {
                        final isSelected = selectedColor == color;
                        final swatch = _colorForName(color);
                        return Tooltip(
                          message: color,
                          child: GestureDetector(
                            onTap: () => _selectColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              width: isSelected ? 40 : 36,
                              height: isSelected ? 40 : 36,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5146D8)
                                      : const Color(0xFFE3E2E9),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: swatch.withValues(alpha: 0.25),
                                          blurRadius: 9,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: swatch,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: swatch.computeLuminance() < 0.35
                                            ? Colors.white
                                            : const Color(0xFF29283A),
                                        size: 17,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${product.price.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Təsvir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Size Selection
                  if (product.sizes.isNotEmpty) ...[
                    const Text(
                      'Ölçü',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: product.sizes.map((size) {
                        final isSelected = selectedSize == size;
                        return GestureDetector(
                          onTap: () => setState(() {
                            selectedSize = size;
                            _sizeSelected = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Miqdar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => setState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Show small 'added' label above bottom bar when item in cart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Builder(
                builder: (context) {
                  final inCart =
                      _added ||
                      widget.cartManager.cartItems.any(
                        (i) =>
                            i.product.id == product.id &&
                            i.selectedSize == selectedSize &&
                            i.selectedColor == selectedColor,
                      );
                  return inCart
                      ? Text(
                          'Səbətə atıldı',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final inCart =
                        _added ||
                        widget.cartManager.cartItems.any(
                          (i) =>
                              i.product.id == product.id &&
                              i.selectedSize == selectedSize &&
                              i.selectedColor == selectedColor,
                        );

                    return ElevatedButton.icon(
                      onPressed: () {
                        widget.cartManager.addToCart(
                          product: product,
                          quantity: quantity,
                          selectedSize: selectedSize,
                          selectedColor: selectedColor,
                        );
                        setState(() => _added = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} səbətə əlavə edildi',
                            ),
                            backgroundColor: const Color(0xFF6C63FF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart, size: 20),
                      label: Text(inCart ? 'Səbətə əlavə edildi' : 'Səbətə at'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inCart
                            ? Colors.green
                            : (selectionMade
                                  ? Colors.green
                                  : const Color(0xFF6C63FF)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6584),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CART PAGE
// ══════════════════════════════════════════════════════════════

class CartPage extends StatefulWidget {
  final CartManager cartManager;

  const CartPage({super.key, required this.cartManager});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartManager cartManager;

  String _paymentMethod = 'card';
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _appliedPromoCode;
  double _discountRate = 0;

  @override
  void initState() {
    super.initState();
    cartManager = widget.cartManager;
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = cartManager.cartItems;
    final subtotal = cartManager.getTotal();
    final total = subtotal * (1 - _discountRate);

    return Scaffold(
      appBar: AppBar(title: const Text('Səbət')),
      body: Column(
        children: [
          if (cartManager.syncError != null)
            MaterialBanner(
              content: Text(
                'Səbət Django ilə sinxronlaşmadı: ${cartManager.syncError}',
              ),
              actions: [
                TextButton(
                  onPressed: cartManager.retrySync,
                  child: const Text('Yenidən yoxla'),
                ),
              ],
            ),
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (
                        var index = 0;
                        index < cartItems.length;
                        index++
                      ) ...[
                        _buildCartItem(context, cartItems[index], cartManager),
                        if (index < cartItems.length - 1)
                          const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                      _buildCheckoutSection(
                        context,
                        subtotal,
                        total,
                        cartManager,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'Səbətiniz boşdur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alış-verişə başlamaq üçün kateqoriyalara baxın',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartManager cartManager,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shadowColor: const Color(0xFF29254A).withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEDEDF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: productImageWidget(
                item.product.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          tooltip: 'Səbətdən sil',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => cartManager.removeFromCart(item),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB05D68),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.selectedSize} / ${item.selectedColor}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.product.price.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    if (item.quantity > 1) {
                      cartManager.updateQuantity(item, item.quantity - 1);
                    } else {
                      cartManager.removeFromCart(item);
                    }
                  },
                  color: Colors.grey,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    cartManager.updateQuantity(item, item.quantity + 1);
                  },
                  color: const Color(0xFF6C63FF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    double subtotal,
    double total,
    CartManager cartManager,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29254A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Qiymət xülasəsi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF29283A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Məhsulların qiyməti', subtotal),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Çatdırılma', style: TextStyle(color: Colors.grey[700])),
              const Text(
                'Pulsuz',
                style: TextStyle(
                  color: Color(0xFF1E9B72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_discountRate > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Endirim (${(_discountRate * 100).round()}%)',
              -(subtotal * _discountRate),
              color: const Color(0xFF1E9B72),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yekun məbləğ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                '${total.toStringAsFixed(2)} AZN',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5146D8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Promo kod',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_appliedPromoCode != null)
                TextButton(
                  onPressed: () => setState(() {
                    _appliedPromoCode = null;
                    _discountRate = 0;
                    _promoCodeController.clear();
                  }),
                  child: const Text('Sil'),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCodeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: _appliedPromoCode == null,
                  decoration: InputDecoration(
                    hintText: 'Məs: WELCOME10',
                    prefixIcon: const Icon(Icons.sell_outlined, size: 19),
                    filled: true,
                    fillColor: const Color(0xFFF8F7FC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Color(0xFFE7E5F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Color(0xFFE7E5F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _appliedPromoCode == null ? _applyPromoCode : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  _appliedPromoCode == null ? 'Tətbiq et' : 'Tətbiq edildi',
                ),
              ),
            ],
          ),
          if (_appliedPromoCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_appliedPromoCode kodu tətbiq edildi',
                  style: const TextStyle(
                    color: Color(0xFF1E9B72),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),

          // Payment Method
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ödəniş üsulu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF29283A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Kartla'),
                selected: _paymentMethod == 'card',
                onSelected: (selected) {
                  if (selected) setState(() => _paymentMethod = 'card');
                },
              ),
              ChoiceChip(
                label: const Text('Nağd'),
                selected: _paymentMethod == 'cash',
                onSelected: (selected) {
                  if (selected) setState(() => _paymentMethod = 'cash');
                },
              ),
              ChoiceChip(
                label: const Text('Kuryer ilə'),
                selected: _paymentMethod == 'cod',
                onSelected: (selected) {
                  if (selected) setState(() => _paymentMethod = 'cod');
                },
              ),
            ],
          ),

          // Card fields when card selected
          if (_paymentMethod == 'card')
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBFAFF), Color(0xFFF5F2FF)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE6E1FA)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF6C63FF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kart məlumatları',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Spacer(),
                        Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: _checkoutInputDecoration(
                        label: 'Kart nömrəsi',
                        hint: '1234 5678 9012 3456',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cardExpiryController,
                            keyboardType: TextInputType.datetime,
                            decoration: _checkoutInputDecoration(
                              label: 'Etibarlılıq',
                              hint: 'AA/İİ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 105,
                          child: TextField(
                            controller: _cardCvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: _checkoutInputDecoration(
                              label: 'CVV',
                              hint: '•••',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Address
          TextField(
            controller: _addressController,
            decoration: _checkoutInputDecoration(
              label: 'Çatdırılma ünvanı',
              hint: 'Küçə, ev/mənzil',
              icon: Icons.location_on_outlined,
            ),
          ),
          const SizedBox(height: 8),

          // Date & Time pickers
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Text(
                    _selectedDate == null
                        ? 'Çatdırılma tarixi seçin'
                        : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _selectedTime = time);
                  },
                  child: Text(
                    _selectedTime == null
                        ? 'Vaxt seçin'
                        : _selectedTime!.format(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          FilledButton(
            onPressed: () {
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );

              if (!appProvider.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sifariş vermək üçün daxil olun'),
                  ),
                );
                return;
              }

              // Basic validation
              if (_addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Çatdırılma ünvanını daxil edin'),
                  ),
                );
                return;
              }

              if (_paymentMethod == 'card') {
                if (_cardNumberController.text.trim().isEmpty ||
                    _cardExpiryController.text.trim().isEmpty ||
                    _cardCvvController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kart məlumatlarını tam daxil edin'),
                    ),
                  );
                  return;
                }
              }

              // Place order
              final paymentLabel = switch (_paymentMethod) {
                'card' => 'Kartla',
                'cash' => 'Nağd',
                _ => 'Çatdırılma zamanı (kuryer)',
              };
              final confirmationDetails = [
                'Ümumi: ${total.toStringAsFixed(2)} AZN',
                'Ödəniş: $paymentLabel',
                'Çatdırılma: ${_addressController.text.trim()}',
                if (_selectedDate != null)
                  'Tarix: ${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                if (_selectedTime != null)
                  'Vaxt: ${_selectedTime!.format(context)}',
              ].join('\n');

              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Sifarişi təsdiqlə'),
                    content: Text(confirmationDetails),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ləğv et'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final appProvider = Provider.of<AppProvider>(
                            context,
                            listen: false,
                          );
                          try {
                            final cartId = await cartManager
                                .prepareForCheckout();
                            await appProvider.submitOrderToDjango(
                              userPhone:
                                  appProvider.currentUser?.phoneNumber ??
                                  appProvider.currentUser?.email ??
                                  'N/A',
                              deliveryAddress: _addressController.text.trim(),
                              cartId: cartId,
                              cartItems: cartManager.cartItems,
                              promoCode: _appliedPromoCode,
                            );
                            if (!mounted) return;
                            Navigator.of(this.context).pop();
                            cartManager.clearCart();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Sifarişiniz qəbul edildi!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() {
                              _cardNumberController.clear();
                              _cardExpiryController.clear();
                              _cardCvvController.clear();
                              _addressController.clear();
                              _promoCodeController.clear();
                              _appliedPromoCode = null;
                              _discountRate = 0;
                              _selectedDate = null;
                              _selectedTime = null;
                            });
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sifariş Django-da saxlanmadı: $error',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Təsdiqlə'),
                      ),
                    ],
                  );
                },
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: const Text('Sifarişi rəsmiləşdir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        Text(
          '${isNegative ? '-' : ''}${amount.abs().toStringAsFixed(2)} AZN',
          style: TextStyle(
            color: color ?? const Color(0xFF29283A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _checkoutInputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE7E5F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE7E5F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.2),
      ),
    );
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    final double? discount = switch (code) {
      'WELCOME10' => 0.10,
      'SUMMER20' => 0.20,
      'FREESHIP' => 0,
      _ => null,
    };
    if (discount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo kod tapılmadı və ya yanlışdır.')),
      );
      return;
    }
    setState(() {
      _appliedPromoCode = code;
      _discountRate = discount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          code == 'FREESHIP'
              ? 'Çatdırılma artıq pulsuzdur.'
              : '$code tətbiq edildi — ${(discount * 100).round()}% endirim.',
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CATEGORY PAGE
// ══════════════════════════════════════════════════════════════

class CategoryPage extends StatefulWidget {
  final CartManager cartManager;

  const CategoryPage({super.key, required this.cartManager});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final query = _searchQuery.trim().toLowerCase();
    final categories = provider.categories.where((category) {
      return (category['name'] ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kateqoriyalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Kateqoriya axtar',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Axtarışı təmizlə',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'Uyğun kateqoriya tapılmadı',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _CategoryGridCard(
                        category: categories[index],
                        cartManager: widget.cartManager,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatefulWidget {
  final Map<String, String> category;
  final CartManager cartManager;

  const _CategoryGridCard({required this.category, required this.cartManager});

  @override
  State<_CategoryGridCard> createState() => _CategoryGridCardState();
}

class _CategoryGridCardState extends State<_CategoryGridCard> {
  bool _pressed = false;

  String _imageForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'geyim':
        return 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=700';
      case 'kofta':
        return 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=700';
      case 'etek':
        return 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=700';
      case 'şalvar':
        return 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=700';
      case 'kişi':
        return 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=700';
      case 'qadın':
        return 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=700';
      case 'idman':
        return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=700';
      case 'aksesuar':
        return 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=700';
      default:
        return 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=700';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category['name'] ?? '';

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            pushAnimated(
              context,
              CategoryDetailPage(
                categoryName: categoryName,
                cartManager: widget.cartManager,
              ),
            );
          },
          onHighlightChanged: (pressed) {
            if (_pressed != pressed) setState(() => _pressed = pressed);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _imageForCategory(categoryName),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF777184),
                  alignment: Alignment.center,
                  child: Text(
                    widget.category['icon'] ?? '📦',
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 42,
                bottom: 14,
                child: Text(
                  categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryDetailPage extends StatelessWidget {
  final String categoryName;
  final CartManager cartManager;

  const CategoryDetailPage({
    super.key,
    required this.categoryName,
    required this.cartManager,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final products = appProvider.products
        .where((p) => p.category == categoryName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Bu kateqoriyada məhsul yoxdur',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(context, product);
              },
            ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        pushAnimated(
          context,
          ProductDetailPage(product: product, cartManager: cartManager),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  productImageWidget(
                    product.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        cartManager.addToCart(
                          product: product,
                          quantity: 1,
                          selectedSize: product.sizes.isNotEmpty
                              ? product.sizes.first
                              : 'M',
                          selectedColor: product.colors.isNotEmpty
                              ? product.colors.first
                              : 'Black',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} səbətə əlavə edildi',
                            ),
                            backgroundColor: const Color(0xFF6C63FF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Səbətə at'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C63FF),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE PAGE
// ══════════════════════════════════════════════════════════════

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    if (!appProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        backgroundColor: const Color(0xFFF5F5F9),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29254A).withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF958CFF)],
                        ),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'BRAND SHOPPING',
                      style: TextStyle(
                        color: Color(0xFF29283A),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Xoş gəlmisiniz! Hesabınıza daxil olun və sevimli alış-verişinizə davam edin.',
                      style: TextStyle(color: Colors.grey[600], height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () =>
                            pushAnimated(context, const AuthScreen()),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Daxil ol / Qeydiyyatdan keç',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'E-poçt, Apple və Facebook giriş seçimləri '
                      'qeydiyyat səhifəsində mövcuddur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final user = appProvider.currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFFF5F5F9),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 22),
          _profileSection(
            title: 'Mağaza & Biznes',
            children: [
              _buildProfileMenuItem(
                context,
                icon: Icons.admin_panel_settings_outlined,
                title: appProvider.isAdmin ? 'Admin Panel' : 'Admin Giriş',
                tint: const Color(0xFF6C63FF),
                onTap: () => pushAnimated(
                  context,
                  appProvider.isAdmin
                      ? const AdminPanelScreen()
                      : const AdminLoginScreen(),
                ),
              ),
              if (user.role == UserRole.vendor && appProvider.isVendor)
                _buildProfileMenuItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'Mağazam və Məhsul Əlavə Et',
                  subtitle: appProvider.vendorShop?.shopName,
                  tint: const Color(0xFF1E9B72),
                  onTap: () =>
                      pushAnimated(context, const VendorDashboardScreen()),
                )
              else if (user.role == UserRole.user)
                _buildProfileMenuItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: appProvider.myShop?.status == ShopStatus.pending
                      ? 'Müraciətiniz nəzərdən keçirilir'
                      : appProvider.myShop?.status == ShopStatus.rejected
                      ? 'Müraciət rədd edilib — yenidən müraciət et'
                      : 'Mağaza Aç / Satıcı Ol',
                  subtitle: appProvider.myShop?.status == ShopStatus.pending
                      ? 'Admin təsdiqini gözləyir'
                      : null,
                  tint: const Color(0xFFF08A3C),
                  trailing: appProvider.myShop?.status == ShopStatus.pending
                      ? Icons.hourglass_top
                      : Icons.arrow_forward_ios,
                  onTap: appProvider.myShop?.status == ShopStatus.pending
                      ? null
                      : () => pushAnimated(
                          context,
                          const ShopApplicationScreen(),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _profileSection(
            title: 'Alış-veriş',
            children: [
              _buildProfileMenuItem(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'Sifarişlərim',
                tint: const Color(0xFF5286E8),
                onTap: () => pushAnimated(context, const OrdersPage()),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.favorite_border,
                title: 'Sevimlilər',
                tint: const Color(0xFFE56D8A),
                onTap: () => _openProfilePlaceholder(context, 'Sevimlilər'),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.location_on_outlined,
                title: 'Ünvanlar',
                tint: const Color(0xFF29A7A0),
                onTap: () => _openProfilePlaceholder(context, 'Ünvanlar'),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.local_offer_outlined,
                title: 'Promo Kodlar',
                tint: const Color(0xFF9B70D3),
                onTap: () => _openProfilePlaceholder(context, 'Promo Kodlar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _profileSection(
            title: 'Tənzimləmələr',
            children: [
              _buildProfileMenuItem(
                context,
                icon: Icons.local_shipping_outlined,
                title: 'Çatdırılma və Ödəniş',
                tint: const Color(0xFF5286E8),
                onTap: () => pushAnimated(context, const DeliveryPaymentPage()),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.payment_outlined,
                title: 'Ödəniş üsulları',
                tint: const Color(0xFF29A7A0),
                onTap: () =>
                    _openProfilePlaceholder(context, 'Ödəniş üsulları'),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.language,
                title: 'Dil',
                subtitle: appProvider.language.name.toUpperCase(),
                tint: const Color(0xFF9B70D3),
                onTap: () async {
                  final choice = await showDialog<AppLanguage>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Dil seçin'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, AppLanguage.az),
                          child: const Text('Azərbaycanca'),
                        ),
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, AppLanguage.en),
                          child: const Text('English'),
                        ),
                        SimpleDialogOption(
                          onPressed: () =>
                              Navigator.pop(context, AppLanguage.ru),
                          child: const Text('Русский'),
                        ),
                      ],
                    ),
                  );
                  if (choice != null) appProvider.setLanguage(choice);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _profileSection(
            title: 'Yardım və dəstək',
            children: [
              _buildProfileMenuItem(
                context,
                icon: Icons.report_problem_outlined,
                title: 'Şikayətlər və Dəstək',
                tint: const Color(0xFFE58A49),
                onTap: () => pushAnimated(context, const ComplaintFormPage()),
              ),
              _buildProfileMenuItem(
                context,
                icon: Icons.headset_mic_outlined,
                title: 'Dəstək Xidməti',
                tint: const Color(0xFF5286E8),
                onTap: () => pushAnimated(context, const SupportPage()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: appProvider.logout,
            icon: const Icon(Icons.logout, color: Color(0xFFD94B5B)),
            label: const Text(
              'Çıxış',
              style: TextStyle(
                color: Color(0xFFD94B5B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    final displayName = user.fullName.trim().isEmpty
        ? 'İstifadəçi'
        : user.fullName.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5146D8), Color(0xFF8177F4), Color(0xFFA59CFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child:
                      user.profileImage == null ||
                          user.profileImage!.trim().isEmpty
                      ? Container(
                          width: 66,
                          height: 66,
                          color: Colors.white.withValues(alpha: 0.18),
                          alignment: Alignment.center,
                          child: Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : productImageWidget(
                          user.profileImage!,
                          width: 66,
                          height: 66,
                          errorWidget: const CircleAvatar(
                            radius: 33,
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF777786),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEDF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF29254A).withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 68),
                    child: Divider(height: 1, thickness: 0.7),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color tint,
    required VoidCallback? onTap,
    String? subtitle,
    IconData trailing = Icons.chevron_right,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.11),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: tint, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF29283A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF898996)),
            ),
      trailing: Icon(
        trailing,
        size: trailing == Icons.arrow_forward_ios ? 14 : 20,
        color: const Color(0xFFB7B7C2),
      ),
      onTap: onTap,
    );
  }

  void _openProfilePlaceholder(BuildContext context, String title) {
    pushAnimated(
      context,
      Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      ),
    );
  }

  // Close ProfilePage class
}

// ══════════════════════════════════════════════════════════════

class DeliveryPaymentPage extends StatefulWidget {
  const DeliveryPaymentPage({super.key});

  @override
  State<DeliveryPaymentPage> createState() => _DeliveryPaymentPageState();
}

class _DeliveryPaymentPageState extends State<DeliveryPaymentPage> {
  String _delivery = 'standard';
  String _payment = 'card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çatdırılma və Ödəniş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çatdırılma növü',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              title: const Text('Standart (2-5 iş günü)'),
              value: 'standard',
              groupValue: _delivery,
              onChanged: (v) => setState(() => _delivery = v as String),
            ),
            RadioListTile(
              title: const Text('Express (1-2 iş günü)'),
              value: 'express',
              groupValue: _delivery,
              onChanged: (v) => setState(() => _delivery = v as String),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ödəniş üsulu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              title: const Text('Kart ilə ödəniş'),
              value: 'card',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v as String),
            ),
            RadioListTile(
              title: const Text('Kuryerə nağd ödəniş'),
              value: 'cash',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v as String),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seçildi: Çatdırılma=$_delivery, Ödəniş=$_payment',
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Saxla')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoCodesPage extends StatelessWidget {
  const PromoCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final codes = ['WELCOME10', 'SUMMER20', 'FREESHIP'];
    return Scaffold(
      appBar: AppBar(title: const Text('Promo Kodlar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final code = codes[index];
          return Card(
            child: ListTile(
              title: Text(
                code,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Endirim və ya pulsuz çatdırılma təklif edir',
              ),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$code tətbiq olundu')),
                  );
                },
                child: const Text('Tətbiq et'),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: codes.length,
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dəstək Xidməti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bizimlə əlaqə',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('E-poçt: support@brandshopping.az'),
            const SizedBox(height: 4),
            const Text('Telefon: +994 12 345 67 89'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => pushAnimated(context, const ComplaintFormPage()),
              child: const Text('Yeni müraciət yarat'),
            ),
          ],
        ),
      ),
    );
  }
}

class CartManager extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final bool _syncWithDjango;
  final Map<String, int> _pendingAdds = {};
  final Map<String, int> _pendingQuantities = {};
  final Set<String> _pendingRemovals = {};
  Future<void>? _initialization;
  Future<void> _syncQueue = Future<void>.value();
  String? _cartId;
  String? _syncError;
  int _mutationVersion = 0;
  bool _clearPending = false;
  bool _initializationComplete = false;

  CartManager({bool syncWithDjango = true}) : _syncWithDjango = syncWithDjango;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  String? get syncError => _syncError;

  Future<void> initialize() {
    if (!_syncWithDjango) return Future<void>.value();
    return _initialization ??= _loadCartFromDjango();
  }

  Future<void> _loadCartFromDjango() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _cartId = preferences.getString('django_cart_id');
      if (_cartId == null) {
        final randomPart = List<int>.generate(
          16,
          (_) => Random.secure().nextInt(256),
        ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
        _cartId = '${DateTime.now().microsecondsSinceEpoch}-$randomPart';
        await preferences.setString('django_cart_id', _cartId!);
      }

      final startingVersion = _mutationVersion;
      final remoteItems = await ApiService.getCart(_cartId!);
      final products = <String, CartItem>{};
      for (final record in remoteItems) {
        final productData = record['product'];
        if (productData is! Map) {
          throw const FormatException('Django səbət məhsulu düzgün deyil.');
        }
        final product = Product.fromJson(
          Map<String, dynamic>.from(productData),
        );
        final item = CartItem(
          product: product,
          quantity: record['quantity'] as int,
          selectedSize: record['size']?.toString() ?? '',
          selectedColor: record['color']?.toString() ?? '',
        );
        products[_itemKey(item)] = item;
      }

      if (startingVersion == _mutationVersion) {
        _cartItems
          ..clear()
          ..addAll(products.values);
      } else {
        if (_clearPending) products.clear();
        for (final key in _pendingRemovals) {
          products.remove(key);
        }
        for (final entry in _pendingQuantities.entries) {
          final localItem = _findLocalItem(entry.key);
          if (entry.value <= 0) {
            products.remove(entry.key);
          } else if (localItem != null) {
            products[entry.key] = CartItem(
              product: localItem.product,
              quantity: entry.value,
              selectedSize: localItem.selectedSize,
              selectedColor: localItem.selectedColor,
            );
          }
        }
        for (final entry in _pendingAdds.entries) {
          final localItem = _findLocalItem(entry.key);
          if (localItem == null) continue;
          final remoteItem = products[entry.key];
          if (remoteItem == null) {
            products[entry.key] = CartItem(
              product: localItem.product,
              quantity: entry.value,
              selectedSize: localItem.selectedSize,
              selectedColor: localItem.selectedColor,
            );
          } else {
            remoteItem.quantity += entry.value;
          }
        }
        _cartItems
          ..clear()
          ..addAll(products.values);
        _pendingAdds.clear();
        _pendingQuantities.clear();
        _pendingRemovals.clear();
        _clearPending = false;
        _queueCartSync();
      }
      _syncError = null;
    } catch (error) {
      _syncError = error.toString();
    } finally {
      _initializationComplete = true;
      notifyListeners();
    }
  }

  String _itemKey(CartItem item) =>
      '${item.product.id}|${item.selectedSize}|${item.selectedColor}';

  CartItem? _findLocalItem(String key) {
    for (final item in _cartItems) {
      if (_itemKey(item) == key) return item;
    }
    return null;
  }

  void addToCart({
    required Product product,
    required int quantity,
    required String selectedSize,
    required String selectedColor,
  }) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be at least 1.');
    }
    final itemKey = '${product.id}|$selectedSize|$selectedColor';
    final existingIndex = _cartItems.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == selectedSize &&
          item.selectedColor == selectedColor,
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
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
    _mutationVersion++;
    if (!_initializationComplete) {
      _pendingAdds.update(
        itemKey,
        (current) => current + quantity,
        ifAbsent: () => quantity,
      );
      _pendingRemovals.remove(itemKey);
    }
    notifyListeners();
    _queueCartSync();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    final key = _itemKey(item);
    _mutationVersion++;
    if (!_initializationComplete) {
      _pendingRemovals.add(key);
      _pendingAdds.remove(key);
      _pendingQuantities.remove(key);
    }
    notifyListeners();
    _queueCartSync();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      removeFromCart(item);
      return;
    }
    item.quantity = quantity;
    _mutationVersion++;
    if (!_initializationComplete) {
      _pendingQuantities[_itemKey(item)] = quantity;
      _pendingAdds.remove(_itemKey(item));
    }
    notifyListeners();
    _queueCartSync();
  }

  void clearCart() {
    _mutationVersion++;
    if (!_initializationComplete) {
      _clearPending = true;
      _pendingAdds.clear();
      _pendingQuantities.clear();
      _pendingRemovals.clear();
    }
    _cartItems.clear();
    notifyListeners();
    _queueCartSync();
  }

  void retrySync() {
    _queueCartSync();
  }

  Future<String> prepareForCheckout() async {
    await initialize();
    await _syncQueue;
    if (_syncError != null) {
      throw StateError('Səbət Django ilə sinxron deyil: $_syncError');
    }
    final cartId = _cartId;
    if (cartId == null) {
      throw StateError('Django səbət ID-si yaradıla bilmədi.');
    }
    return cartId;
  }

  void _queueCartSync() {
    if (!_syncWithDjango) return;
    _syncQueue = _syncQueue.then((_) async {
      try {
        await initialize();
        final cartId = _cartId;
        if (cartId == null) {
          throw StateError('Django səbət ID-si yaradıla bilmədi.');
        }
        await ApiService.saveCart(
          cartId,
          _cartItems
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
        _syncError = null;
      } catch (error) {
        _syncError = error.toString();
      }
      notifyListeners();
    });
  }

  double getTotal() {
    double total = 0;
    for (final item in _cartItems) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  int getItemCount() {
    int count = 0;
    for (final item in _cartItems) {
      count += item.quantity;
    }
    return count;
  }
}
