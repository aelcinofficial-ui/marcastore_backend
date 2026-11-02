import 'package:flutter_test/flutter_test.dart';
import 'package:marcastore_app/main.dart';
import 'package:marcastore_app/models/product.dart';

void main() {
  test('Django product data can be added to the cart', () {
    final product = Product.fromJson({
      'id': 12,
      'name': 'Test məhsul',
      'description': 'Django API məhsulu',
      'price': '19.99',
      'shop': 3,
    });
    final cart = CartManager(syncWithDjango: false);

    cart.addToCart(
      product: product,
      quantity: 1,
      selectedSize: 'M',
      selectedColor: 'Black',
    );
    cart.addToCart(
      product: product,
      quantity: 2,
      selectedSize: 'M',
      selectedColor: 'Black',
    );

    expect(cart.cartItems, hasLength(1));
    expect(cart.cartItems.single.product.id, '12');
    expect(cart.cartItems.single.quantity, 3);
    expect(cart.getTotal(), 59.97);
  });
}
