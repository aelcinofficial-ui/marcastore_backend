import 'package:flutter/material.dart';
import 'package:marcastore_app/services/services.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarcaStore - Məhsullar'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Xəta baş verdi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Hələ heç bir məhsul əlavə edilməyib.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    product['name'] ?? 'Adsız məhsul',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Qiymət: ${product['price'] ?? '0'} AZN'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
