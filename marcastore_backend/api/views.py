from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Category, Cart, CartItem, Order, Product, Shop, User
from .serializers import (
    CategorySerializer,
    CartItemSerializer,
    CartUpdateSerializer,
    OrderCreateSerializer,
    OrderSerializer,
    ProductSerializer,
    ShopSerializer,
    UserSerializer,
)

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class ShopViewSet(viewsets.ModelViewSet):
    queryset = Shop.objects.all()
    serializer_class = ShopSerializer


class ProductViewSet(viewsets.ModelViewSet):
  queryset = Product.objects.all()
  serializer_class = ProductSerializer


class OrderViewSet(viewsets.ModelViewSet):
  queryset = Order.objects.all()
  serializer_class = OrderSerializer
  permission_classes = [IsAuthenticated]

  def get_queryset(self):
    queryset = super().get_queryset()
    return queryset.filter(user__email__iexact=self.request.user.email)

  def create(self, request, *args, **kwargs):
    serializer = OrderCreateSerializer(
        data=request.data, context={'request': request}
    )
    serializer.is_valid(raise_exception=True)
    order = serializer.save()
    return Response(
        OrderSerializer(order).data, status=status.HTTP_201_CREATED
    )


class CartView(APIView):
  def get(self, request, cart_id):
    cart, _ = Cart.objects.get_or_create(cart_id=cart_id)
    return Response({
        'cart_id': cart.cart_id,
        'items': CartItemSerializer(cart.items.select_related('product'), many=True).data,
    })

  def put(self, request, cart_id):
    cart, _ = Cart.objects.get_or_create(cart_id=cart_id)
    serializer = CartUpdateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.update_cart(cart)
    return self.get(request, cart_id)

  def delete(self, request, cart_id):
    cart, _ = Cart.objects.get_or_create(cart_id=cart_id)
    with transaction.atomic():
      cart.items.all().delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
