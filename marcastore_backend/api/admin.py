from django.contrib import admin
from django.utils.html import format_html

from .models import (
    Banner,
    Cart,
    CartItem,
    Category,
    Complaint,
    Notification,
    Order,
    Product,
    ProductReview,
    Shop,
    SocialIdentity,
    User,
)


def _image_preview(image):
    if not image:
        return "Şəkil yoxdur"
    return format_html(
        '<img src="{}" width="100" height="70" '
        'style="object-fit:contain;" />',
        image.url,
    )


class SocialIdentityInline(admin.TabularInline):
    model = SocialIdentity
    extra = 0
    show_change_link = True


class ComplaintInline(admin.TabularInline):
    model = Complaint
    extra = 0
    show_change_link = True


class NotificationInline(admin.TabularInline):
    model = Notification
    extra = 0
    show_change_link = True


class ShopProductInline(admin.TabularInline):
    model = Product
    fk_name = "shop"
    extra = 0
    show_change_link = True


class CategoryProductInline(admin.TabularInline):
    model = Product
    fk_name = "category"
    extra = 0
    show_change_link = True


class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    show_change_link = True


class ProductReviewInline(admin.TabularInline):
    model = ProductReview
    extra = 0
    show_change_link = True


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "email", "phone", "created_at")
    search_fields = ("name", "email", "phone")
    ordering = ("-created_at",)
    readonly_fields = ("created_at",)
    inlines = (SocialIdentityInline, ComplaintInline, NotificationInline)


@admin.register(SocialIdentity)
class SocialIdentityAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "provider", "provider_user_id", "created_at")
    list_filter = ("provider", "created_at")
    search_fields = ("user__name", "user__email", "provider_user_id")
    autocomplete_fields = ("user",)
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(Shop)
class ShopAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "address")
    search_fields = ("name", "description", "address")
    ordering = ("name",)
    inlines = (ShopProductInline,)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "slug", "image_tag", "created_at")
    search_fields = ("name", "slug")
    ordering = ("name",)
    readonly_fields = ("created_at", "image_tag")
    prepopulated_fields = {"slug": ("name",)}
    inlines = (CategoryProductInline,)

    @admin.display(description="Ön baxış")
    def image_tag(self, obj):
        return _image_preview(obj.image if obj else None)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "shop",
        "category",
        "price",
        "stock",
        "image_tag",
    )
    list_filter = ("shop", "category")
    list_editable = ("price", "stock")
    search_fields = ("name", "description", "shop__name", "category__name")
    autocomplete_fields = ("shop", "category")
    ordering = ("name",)
    readonly_fields = ("image_tag",)
    inlines = (ProductReviewInline,)

    @admin.display(description="Ön baxış")
    def image_tag(self, obj):
        return _image_preview(obj.image if obj else None)


@admin.register(ProductReview)
class ProductReviewAdmin(admin.ModelAdmin):
    list_display = ("id", "product", "user", "rating", "created_at")
    list_filter = ("rating", "created_at")
    search_fields = ("product__name", "user__name", "user__email", "comment")
    autocomplete_fields = ("product", "user")
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ("id", "subject", "user", "status", "created_at")
    list_filter = ("status", "created_at")
    list_editable = ("status",)
    search_fields = ("subject", "message", "user__name", "user__email")
    autocomplete_fields = ("user",)
    readonly_fields = ("created_at",)
    ordering = ("status", "-created_at")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "user", "is_read", "created_at")
    list_filter = ("is_read", "created_at")
    list_editable = ("is_read",)
    search_fields = ("title", "message", "user__name", "user__email")
    autocomplete_fields = ("user",)
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(Banner)
class BannerAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "is_active", "image_tag", "created_at")
    list_filter = ("is_active", "created_at")
    list_editable = ("is_active",)
    search_fields = ("title",)
    readonly_fields = ("created_at", "image_tag")
    ordering = ("-created_at",)

    @admin.display(description="Ön baxış")
    def image_tag(self, obj):
        return _image_preview(obj.image if obj else None)


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "total_price",
        "status",
        "promo_code",
        "created_at",
    )
    list_filter = ("status", "created_at")
    list_editable = ("status",)
    search_fields = ("user__name", "user__email", "promo_code", "delivery_address")
    autocomplete_fields = ("user",)
    date_hierarchy = "created_at"
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ("cart_id", "updated_at")
    search_fields = ("cart_id",)
    date_hierarchy = "updated_at"
    readonly_fields = ("updated_at",)
    ordering = ("-updated_at",)
    inlines = (CartItemInline,)


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ("id", "cart", "product", "quantity", "size", "color")
    list_filter = ("product__shop",)
    search_fields = ("cart__cart_id", "product__name", "size", "color")
    autocomplete_fields = ("cart", "product")
    ordering = ("cart", "product")
