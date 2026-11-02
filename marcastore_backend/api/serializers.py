from decimal import Decimal
from django.db import transaction
from rest_framework import serializers
from .models import Category, Cart, CartItem, Order, Product, Shop, User


class UserSerializer(serializers.ModelSerializer):

  class Meta:
    model = User
    fields = '__all__'


class ShopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Shop
        fields = '__all__'


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'


class OrderSerializer(serializers.ModelSerializer):

  class Meta:
    model = Order
    fields = '__all__'


class CartItemSerializer(serializers.ModelSerializer):
  product = ProductSerializer(read_only=True)

  class Meta:
    model = CartItem
    fields = ('product', 'quantity', 'size', 'color')


class CartUpdateSerializer(serializers.Serializer):
  items = serializers.ListField(
      child=serializers.DictField(), allow_empty=True
  )

  def validate_items(self, items):
    validated = []
    item_indexes = {}
    for item in items:
      try:
        product_id = int(item['product'])
        quantity = int(item['quantity'])
      except (KeyError, TypeError, ValueError):
        raise serializers.ValidationError(
            'Hər səbət sətrində düzgün product və quantity olmalıdır.'
        )
      if quantity < 1:
        raise serializers.ValidationError('Miqdar ən azı 1 olmalıdır.')
      try:
        product = Product.objects.get(pk=product_id)
      except Product.DoesNotExist:
        raise serializers.ValidationError(
            f'{product_id} ID-li məhsul tapılmadı.'
        )
      cart_item = {
          'product': product,
          'quantity': quantity,
          'size': str(item.get('size', '')),
          'color': str(item.get('color', '')),
      }
      key = (product.pk, cart_item['size'], cart_item['color'])
      if key in item_indexes:
        validated[item_indexes[key]]['quantity'] += quantity
      else:
        item_indexes[key] = len(validated)
        validated.append(cart_item)
    return validated

  def update_cart(self, cart):
    with transaction.atomic():
      cart.items.all().delete()
      CartItem.objects.bulk_create([
          CartItem(cart=cart, **item) for item in self.validated_data['items']
      ])
    return cart


class OrderCreateSerializer(serializers.Serializer):
  user = serializers.DictField()
  items = serializers.ListField(
      child=serializers.DictField(), allow_empty=False
  )
  cart_id = serializers.CharField(required=False, allow_blank=True)
  delivery_address = serializers.CharField(
      allow_blank=True, required=False, default=''
  )
  promo_code = serializers.CharField(
      allow_blank=True, required=False, default=''
  )

  def validate(self, attrs):
    request = self.context.get('request')
    if request is None or not request.user.is_authenticated:
      raise serializers.ValidationError(
          {'user': 'Sifariş üçün daxil olmaq tələb olunur.'}
      )
    user_data = attrs['user']
    email = request.user.email.strip().lower()
    name = str(user_data.get('name', '')).strip()
    phone = str(user_data.get('phone', '')).strip()
    if not email or not name:
      raise serializers.ValidationError(
          {'user': 'İstifadəçinin adı və e-poçtu tələb olunur.'}
      )
    promo_code = str(attrs.get('promo_code', '')).strip().upper()
    if promo_code not in ('', 'WELCOME10', 'SUMMER20', 'FREESHIP'):
      raise serializers.ValidationError(
          {'promo_code': 'Promo kod etibarsızdır.'}
      )

    validated_items = []
    for item in attrs['items']:
      try:
        product = Product.objects.get(pk=int(item['product']))
        quantity = int(item['quantity'])
      except (KeyError, TypeError, ValueError, Product.DoesNotExist):
        raise serializers.ValidationError(
            {'items': 'Səbətdə etibarsız məhsul var.'}
        )
      if quantity < 1:
        raise serializers.ValidationError(
            {'items': 'Məhsul miqdarı ən azı 1 olmalıdır.'}
        )
      validated_items.append({
          'product': product,
          'quantity': quantity,
          'size': str(item.get('size', '')),
          'color': str(item.get('color', '')),
      })

    attrs['user_data'] = {'email': email, 'name': name, 'phone': phone}
    attrs['validated_items'] = validated_items
    attrs['promo_code'] = promo_code
    return attrs

  def create(self, validated_data):
    with transaction.atomic():
      user_data = validated_data['user_data']
      user, created = User.objects.get_or_create(
          email=user_data['email'],
          defaults={
              'name': user_data['name'],
              'phone': user_data['phone'],
          },
      )
      if not created and (
          user.name != user_data['name']
          or (user_data['phone'] and user.phone != user_data['phone'])
      ):
        user.name = user_data['name']
        if user_data['phone']:
          user.phone = user_data['phone']
        user.save(update_fields=['name', 'phone'])

      item_snapshots = []
      total_price = 0
      for item in validated_data['validated_items']:
        product = item['product']
        quantity = item['quantity']
        total_price += product.price * quantity
        item_snapshots.append({
            'product': product.pk,
            'name': product.name,
            'price': str(product.price),
            'quantity': quantity,
            'size': item['size'],
            'color': item['color'],
        })

      discount = {
          'WELCOME10': Decimal('0.10'),
          'SUMMER20': Decimal('0.20'),
      }.get(validated_data['promo_code'], Decimal('0'))
      total_price *= Decimal('1') - discount
      order = Order.objects.create(
          user=user,
          total_price=total_price,
          items=item_snapshots,
          delivery_address=validated_data['delivery_address'],
          promo_code=validated_data['promo_code'],
      )
      cart_id = validated_data.get('cart_id', '')
      if cart_id:
        cart = Cart.objects.filter(pk=cart_id).first()
        if cart is not None:
          cart.items.all().delete()
      return order
