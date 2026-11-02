from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework.routers import DefaultRouter
from .views import CartView, CategoryViewSet, OrderViewSet, ProductViewSet, ShopViewSet, UserViewSet
from .auth_views import (
    AppleAndroidCallbackView,
    CurrentUserView,
    EmailLoginView,
    EmailRegisterView,
    GoogleLoginView,
    SocialLoginView,
)
router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'users', UserViewSet)
router.register(r'shops', ShopViewSet)
router.register(r'products', ProductViewSet)
router.register(r'orders', OrderViewSet)

urlpatterns = [
    path('cart/<str:cart_id>/', CartView.as_view(), name='cart-detail'),
    path('auth/register/', EmailRegisterView.as_view(), name='auth-register'),
    path('auth/login/', EmailLoginView.as_view(), name='auth-login'),
    path('auth/google/', GoogleLoginView.as_view(), name='auth-google'),
    path(
        'auth/social/<str:provider>/',
        SocialLoginView.as_view(),
        name='auth-social',
    ),
    path('auth/me/', CurrentUserView.as_view(), name='auth-me'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='auth-refresh'),
    path(
        'auth/apple/callback/',
        AppleAndroidCallbackView.as_view(),
        name='auth-apple-android-callback',
    ),
    path('', include(router.urls)),
]
