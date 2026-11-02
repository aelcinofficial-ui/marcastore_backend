from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Category(models.Model):
  name = models.CharField(max_length=255)
  slug = models.SlugField(max_length=255, unique=True)
  image = models.ImageField(upload_to='categories/')
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return self.name


class User(models.Model):
  name = models.CharField(max_length=255)
  email = models.EmailField(unique=True)
  phone = models.CharField(max_length=50, blank=True, null=True)
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return self.name


class SocialIdentity(models.Model):
  class Provider(models.TextChoices):
    APPLE = 'apple', 'Apple'
    FACEBOOK = 'facebook', 'Facebook'
    GOOGLE = 'google', 'Google'

  user = models.ForeignKey(
      User, on_delete=models.CASCADE, related_name='social_identities'
  )
  provider = models.CharField(max_length=16, choices=Provider.choices)
  provider_user_id = models.CharField(max_length=255)
  created_at = models.DateTimeField(auto_now_add=True)

  class Meta:
    constraints = [
        models.UniqueConstraint(
            fields=['provider', 'provider_user_id'],
            name='unique_provider_social_identity',
        )
    ]

  def __str__(self):
    return f'{self.provider}:{self.provider_user_id}'


class Shop(models.Model):
  name = models.CharField(max_length=255)
  description = models.TextField(blank=True, null=True)
  address = models.CharField(max_length=255, blank=True, null=True)

  def __str__(self):
    return self.name


class Product(models.Model):
  shop = models.ForeignKey(
      Shop, on_delete=models.CASCADE, related_name='products'
  )
  category = models.ForeignKey(
      Category,
      on_delete=models.SET_NULL,
      related_name='products',
      blank=True,
      null=True,
  )
  name = models.CharField(max_length=255)
  price = models.DecimalField(max_digits=10, decimal_places=2)
  stock = models.IntegerField(default=0)
  description = models.TextField(blank=True, null=True)
  image = models.ImageField(upload_to='products/', blank=True)

  def __str__(self):
    return self.name


class ProductReview(models.Model):
  product = models.ForeignKey(
      Product, on_delete=models.CASCADE, related_name='reviews'
  )
  user = models.ForeignKey(
      User, on_delete=models.CASCADE, related_name='product_reviews'
  )
  rating = models.IntegerField(
      validators=[MinValueValidator(1), MaxValueValidator(5)]
  )
  comment = models.TextField()
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return f'{self.product} - {self.rating}/5'


class Complaint(models.Model):
  class Status(models.TextChoices):
    PENDING = 'pending', 'Gözləmədə'
    RESOLVED = 'resolved', 'Həll olundu'

  user = models.ForeignKey(
      User, on_delete=models.CASCADE, related_name='complaints'
  )
  subject = models.CharField(max_length=255)
  message = models.TextField()
  status = models.CharField(
      max_length=16, choices=Status.choices, default=Status.PENDING
  )
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return self.subject


class Notification(models.Model):
  user = models.ForeignKey(
      User, on_delete=models.CASCADE, related_name='notifications'
  )
  title = models.CharField(max_length=255)
  message = models.TextField()
  is_read = models.BooleanField(default=False)
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return self.title


class Banner(models.Model):
  title = models.CharField(max_length=255)
  image = models.ImageField(upload_to='banners/')
  is_active = models.BooleanField(default=True)
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return self.title


class Order(models.Model):
  user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
  total_price = models.DecimalField(max_digits=10, decimal_places=2)
  status = models.CharField(max_length=50, default='Pending')
  items = models.JSONField(default=list)
  delivery_address = models.TextField(blank=True)
  promo_code = models.CharField(max_length=32, blank=True)
  created_at = models.DateTimeField(auto_now_add=True)

  def __str__(self):
    return f'Order #{self.id} - {self.status}'


class Cart(models.Model):
  cart_id = models.CharField(max_length=64, primary_key=True)
  updated_at = models.DateTimeField(auto_now=True)


class CartItem(models.Model):
  cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
  product = models.ForeignKey(Product, on_delete=models.CASCADE)
  quantity = models.PositiveIntegerField()
  size = models.CharField(max_length=50, blank=True)
  color = models.CharField(max_length=50, blank=True)

  class Meta:
    constraints = [
        models.UniqueConstraint(
            fields=['cart', 'product', 'size', 'color'],
            name='unique_cart_product_variant',
        )
    ]
