import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'category_banner_management_screen.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'complaint_management_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (!appProvider.isAdmin) {
            return const Center(
              child: Text('Bu bölmə yalnız admin istifadəçilər üçündür.'),
            );
          }
          final orders = appProvider.getAllOrders();
          final complaints = appProvider.getAllComplaints();
          final pendingOrders = orders
              .where((o) => o.status == OrderStatus.pending)
              .length;
          final preparingOrders = orders
              .where((o) => o.status == OrderStatus.preparing)
              .length;
          final pendingComplaints = complaints
              .where((c) => c.status == ComplaintStatus.pending)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  color: const Color(0xFF6C63FF),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panelinə Xoş Gəlmisiniz',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bütün sifarişləri və şikayətləri buradan idarə edə bilərsiniz.',
                          style: TextStyle(
                            color: const Color.fromRGBO(255, 255, 255, 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics
                const Text(
                  'Statistika',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Gözləyən Sifarişlər',
                        '$pendingOrders',
                        Icons.access_time,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Hazırlanır',
                        '$preparingOrders',
                        Icons.kitchen,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Ümumi Sifarişlər',
                        '${orders.length}',
                        Icons.shopping_bag,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Gözləyən Şikayətlər',
                        '$pendingComplaints',
                        Icons.report_problem,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Satıcı müraciətləri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(label: Text('${appProvider.pendingShops.length}')),
                  ],
                ),
                const SizedBox(height: 8),
                if (appProvider.pendingShops.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Gözləyən müraciət yoxdur'),
                    ),
                  )
                else
                  ...appProvider.pendingShops.map((shop) {
                    final owner = appProvider.dataService.getUserById(
                      shop.ownerId,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.shopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (owner != null)
                              Text('${owner.fullName} • ${owner.email}'),
                            if (shop.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(shop.description),
                              ),
                            if (shop.logo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Logo: ${shop.logo}'),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => _reviewShop(
                                    context,
                                    appProvider,
                                    shop,
                                    approve: true,
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Onayla'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _reviewShop(
                                    context,
                                    appProvider,
                                    shop,
                                    approve: false,
                                  ),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rədd et'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Management Sections
                const Text(
                  'İdarəetmə',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  context,
                  'Məhsul İdarəetməsi',
                  'Yeni məhsul əlavə edin və mövcud məhsulları idarə edin',
                  Icons.inventory_2,
                  const Color(0xFF6C63FF),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  context,
                  'Kateqoriyalar və Bannerlər',
                  'Kateqoriyaları idarə edin və ana səhifə şəkilləri əlavə edin',
                  Icons.category,
                  Colors.deepPurple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CategoryBannerManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  context,
                  'Sifariş İdarəetməsi',
                  'Gələn sifarişləri görün və statuslarını yeniləyin',
                  Icons.receipt_long,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  context,
                  'Şikayət İdarəetməsi',
                  'İstifadəçi şikayətlərinə baxın və cavablandırın',
                  Icons.feedback,
                  Colors.red,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComplaintManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _reviewShop(
    BuildContext context,
    AppProvider appProvider,
    Shop shop, {
    required bool approve,
  }) {
    try {
      appProvider.reviewShopApplication(shop.id, approve: approve);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${shop.shopName} təsdiqləndi; sahibinin rolu satıcı oldu.'
                : '${shop.shopName} müraciəti rədd edildi.',
          ),
        ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
