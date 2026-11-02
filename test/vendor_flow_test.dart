import 'package:flutter_test/flutter_test.dart';
import 'package:marcastore_app/models/models.dart';
import 'package:marcastore_app/providers/providers.dart';

void main() {
  test('vendor applications require admin approval before product actions', () {
    final app = AppProvider();
    final email = 'vendor-${DateTime.now().microsecondsSinceEpoch}@test.local';

    expect(
      app.registerUser(
        firstName: 'Test',
        lastName: 'Vendor',
        email: email,
        password: 'pass',
      ),
      isTrue,
    );
    final applicant = app.currentUser!;
    final shop = app.submitShopApplication(
      shopName: 'Test mağaza',
      logo: '',
      description: 'Test təsviri',
    );

    expect(shop.status, ShopStatus.pending);
    expect(app.currentUser!.role, UserRole.user);
    final pendingProduct = Product(
      id: 'pending-product-${shop.id}',
      name: 'Pending məhsul',
      description: 'Təsvir',
      price: 10,
      image: 'https://example.test/image.png',
      category: 'Test',
      shopId: shop.id,
    );
    expect(() => app.addVendorProduct(pendingProduct), throwsStateError);
    expect(
      () => app.reviewShopApplication(shop.id, approve: true),
      throwsStateError,
    );

    app.setCurrentUser(
      User(
        id: 'admin-test-${shop.id}',
        firstName: 'Admin',
        lastName: 'Test',
        email: 'admin-${shop.id}@test.local',
        role: UserRole.admin,
      ),
    );
    app.reviewShopApplication(shop.id, approve: true);
    expect(app.pendingShops, isNot(contains(shop)));
    expect(
      app.dataService.getShopForOwner(applicant.id)!.status,
      ShopStatus.approved,
    );

    app.logout();
    expect(app.loginWithEmail(email: email, password: 'pass'), isTrue);
    expect(app.currentUser!.role, UserRole.vendor);
    expect(app.isVendor, isTrue);

    final product = pendingProduct.copyWith(id: 'vendor-product-${shop.id}');
    app.addVendorProduct(product);
    expect(app.vendorProducts, contains(product));
    app.updateVendorProduct(product.copyWith(name: 'Yenilənmiş məhsul'));
    expect(app.vendorProducts.single.name, 'Yenilənmiş məhsul');
    app.removeVendorProduct(product.id);
    expect(app.vendorProducts, isEmpty);
  });
}
