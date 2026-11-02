from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.test import override_settings
from rest_framework.test import APITestCase

from .models import (
    Cart,
    CartItem,
    Order,
    Product,
    ProductReview,
    Shop,
    SocialIdentity,
    User,
)


class CommerceModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create(name='Review User', email='review@example.test')
        shop = Shop.objects.create(name='Review Shop')
        self.product = Product.objects.create(
            shop=shop,
            name='Review Product',
            price='12.50',
        )

    def test_product_review_rating_is_limited_to_one_through_five(self):
        for rating in (0, 6):
            with self.subTest(rating=rating):
                review = ProductReview(
                    product=self.product,
                    user=self.user,
                    rating=rating,
                    comment='Review',
                )
                with self.assertRaises(ValidationError):
                    review.full_clean()

        ProductReview(
            product=self.product,
            user=self.user,
            rating=5,
            comment='Review',
        ).full_clean()


class CommerceAdminTests(TestCase):
    def setUp(self):
        admin_user = get_user_model().objects.create_superuser(
            username='admin',
            email='admin@example.test',
            password='test-password',
        )
        self.client.force_login(admin_user)

    def test_image_model_admin_add_pages_render(self):
        for model in ('category', 'product', 'banner'):
            with self.subTest(model=model):
                response = self.client.get(f'/admin/api/{model}/add/')
                self.assertEqual(response.status_code, 200)


class AuthApiTests(APITestCase):
    @override_settings(GOOGLE_CLIENT_IDS=['google-web-client-id'])
    @patch(
        'api.auth_views.google_id_token.verify_oauth2_token',
        return_value={
            'sub': 'google-123',
            'email': 'google@example.test',
            'email_verified': True,
            'name': 'Google User',
        },
    )
    def test_google_identity_verifies_token_for_configured_client(
        self, verify_google_token
    ):
        from .auth_views import _google_identity

        identity = _google_identity('signed-google-token')

        self.assertEqual(identity['provider_user_id'], 'google-123')
        self.assertEqual(identity['email'], 'google@example.test')
        self.assertTrue(identity['email_verified'])
        self.assertEqual(
            verify_google_token.call_args.args[0], 'signed-google-token'
        )
        self.assertEqual(
            verify_google_token.call_args.kwargs['audience'],
            ['google-web-client-id'],
        )

    @override_settings(GOOGLE_CLIENT_ID='google-web-client-id')
    @patch(
        'api.auth_views.google_id_token.verify_oauth2_token',
        return_value={
            'sub': 'google-endpoint-user',
            'email': 'google.endpoint@example.test',
            'email_verified': True,
            'name': 'Google Endpoint User',
        },
    )
    def test_google_auth_endpoint_creates_user_and_returns_jwts(
        self, verify_google_token
    ):
        response = self.client.post(
            '/api/auth/google/',
            {'id_token': 'signed-google-token'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['access'])
        self.assertTrue(response.data['refresh'])
        self.assertEqual(
            response.data['user']['email'], 'google.endpoint@example.test'
        )
        self.assertTrue(
            get_user_model().objects.filter(
                email='google.endpoint@example.test'
            ).exists()
        )
        verify_google_token.assert_called_once()
        self.assertEqual(
            verify_google_token.call_args.kwargs['audience'],
            'google-web-client-id',
        )

    def test_email_registration_hashes_password_and_returns_working_jwt(self):
        response = self.client.post(
            '/api/auth/register/',
            {
                'first_name': 'Test',
                'last_name': 'User',
                'email': 'Test.User@example.test',
                'password': 'StrongPass!8292',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        auth_user = get_user_model().objects.get(email='test.user@example.test')
        self.assertTrue(auth_user.check_password('StrongPass!8292'))
        self.assertNotEqual(auth_user.password, 'StrongPass!8292')
        self.assertEqual(response.data['user']['email'], auth_user.email)

        profile_response = self.client.get(
            '/api/auth/me/',
            HTTP_AUTHORIZATION=f"Bearer {response.data['access']}",
        )
        self.assertEqual(profile_response.status_code, 200)
        self.assertEqual(profile_response.data['name'], 'Test User')

    def test_duplicate_email_registration_is_rejected(self):
        payload = {
            'first_name': 'Test',
            'last_name': 'User',
            'email': 'duplicate@example.test',
            'password': 'StrongPass!8292',
        }
        first = self.client.post(
            '/api/auth/register/', payload, format='json'
        )
        second = self.client.post(
            '/api/auth/register/', payload, format='json'
        )

        self.assertEqual(first.status_code, 201)
        self.assertEqual(second.status_code, 400)
        self.assertEqual(get_user_model().objects.count(), 1)

    def test_email_login_checks_password_and_returns_jwt(self):
        self.client.post(
            '/api/auth/register/',
            {
                'first_name': 'Test',
                'last_name': 'User',
                'email': 'login@example.test',
                'password': 'StrongPass!8292',
            },
            format='json',
        )

        wrong_password = self.client.post(
            '/api/auth/login/',
            {'email': 'login@example.test', 'password': 'wrong-password'},
            format='json',
        )
        login = self.client.post(
            '/api/auth/login/',
            {'email': 'LOGIN@example.test', 'password': 'StrongPass!8292'},
            format='json',
        )

        self.assertEqual(wrong_password.status_code, 401)
        self.assertEqual(login.status_code, 200)
        self.assertTrue(login.data['access'])
        self.assertTrue(login.data['refresh'])

    @override_settings(FACEBOOK_APP_ID='test-app', FACEBOOK_APP_SECRET='test-secret')
    @patch(
        'api.auth_views._facebook_identity',
        return_value={
            'provider_user_id': 'facebook-123',
            'email': 'facebook@example.test',
            'email_verified': True,
            'name': 'Facebook User',
        },
    )
    def test_facebook_identity_is_stored_in_django(self, verify_facebook):
        response = self.client.post(
            '/api/auth/social/facebook/',
            {'access_token': 'provider-token'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user']['email'], 'facebook@example.test')
        self.assertTrue(response.data['access'])
        self.assertTrue(
            SocialIdentity.objects.filter(
                provider='facebook', provider_user_id='facebook-123'
            ).exists()
        )
        verify_facebook.assert_called_once_with('provider-token')

    @override_settings(APPLE_CLIENT_IDS=['com.example.marcastoreApp'])
    @patch(
        'api.auth_views._apple_identity',
        return_value={
            'provider_user_id': 'apple-123',
            'email': 'apple@example.test',
            'email_verified': True,
        },
    )
    def test_apple_identity_is_stored_in_django(self, verify_apple):
        response = self.client.post(
            '/api/auth/social/apple/',
            {'identity_token': 'provider-token', 'name': 'Apple User'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user']['email'], 'apple@example.test')
        self.assertTrue(
            SocialIdentity.objects.filter(
                provider='apple', provider_user_id='apple-123'
            ).exists()
        )
        verify_apple.assert_called_once_with('provider-token')

    @override_settings(GOOGLE_CLIENT_IDS=['google-web-client-id'])
    @patch(
        'api.auth_views._google_identity',
        return_value={
            'provider_user_id': 'google-123',
            'email': 'google@example.test',
            'email_verified': True,
            'name': 'Google User',
        },
    )
    def test_google_identity_is_stored_in_django(self, verify_google):
        response = self.client.post(
            '/api/auth/social/google/',
            {'id_token': 'provider-token'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['user']['email'], 'google@example.test')
        self.assertTrue(response.data['access'])
        self.assertTrue(response.data['refresh'])
        self.assertTrue(
            SocialIdentity.objects.filter(
                provider='google', provider_user_id='google-123'
            ).exists()
        )
        verify_google.assert_called_once_with('provider-token')

    def test_social_login_rejects_unverified_email(self):
        with patch(
            'api.auth_views._apple_identity',
            return_value={
                'provider_user_id': 'apple-unverified',
                'email': 'unverified@example.test',
                'email_verified': False,
            },
        ):
            response = self.client.post(
                '/api/auth/social/apple/',
                {'identity_token': 'provider-token'},
                format='json',
            )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(SocialIdentity.objects.count(), 0)

    @override_settings(GOOGLE_CLIENT_IDS=['google-web-client-id'])
    @patch(
        'api.auth_views._google_identity',
        return_value={
            'provider_user_id': 'google-unverified',
            'email': 'unverified@example.test',
            'email_verified': False,
            'name': 'Unverified Google User',
        },
    )
    def test_google_login_rejects_unverified_email(self, verify_google):
        response = self.client.post(
            '/api/auth/social/google/',
            {'id_token': 'provider-token'},
            format='json',
        )

        self.assertEqual(response.status_code, 401)
        self.assertFalse(
            SocialIdentity.objects.filter(provider='google').exists()
        )
        verify_google.assert_called_once_with('provider-token')

    def test_android_apple_callback_redirects_to_fixed_app_scheme(self):
        response = self.client.post(
            '/api/auth/apple/callback/',
            {'code': 'authorization-code', 'state': 'request-state'},
        )

        self.assertEqual(response.status_code, 302)
        self.assertTrue(
            response['Location'].startswith(
                'intent://callback?code=authorization-code'
            )
        )
        self.assertIn(
            'package=com.example.marcastore_app;scheme=signinwithapple;end',
            response['Location'],
        )


class ProductApiTests(APITestCase):
    def test_products_endpoint_returns_cart_compatible_product_data(self):
        shop = Shop.objects.create(name='Test mağaza')
        product = Product.objects.create(
            shop=shop,
            name='Test məhsul',
            price='19.99',
            stock=5,
            description='Django API məhsulu',
        )

        response = self.client.get('/api/products/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], product.id)
        self.assertEqual(response.data[0]['name'], product.name)
        self.assertEqual(response.data[0]['price'], '19.99')
        self.assertEqual(response.data[0]['shop'], shop.id)


class CartApiTests(APITestCase):
    def setUp(self):
        shop = Shop.objects.create(name='Test mağaza')
        self.product = Product.objects.create(
            shop=shop,
            name='Test məhsul',
            price='19.99',
            stock=5,
        )
        self.cart_url = '/api/cart/test-cart/'

    def test_cart_can_be_loaded_and_updated(self):
        initial = self.client.get(self.cart_url)
        self.assertEqual(initial.status_code, 200)
        self.assertEqual(initial.data['items'], [])

        updated = self.client.put(
            self.cart_url,
            {
                'items': [{
                    'product': self.product.id,
                    'quantity': 2,
                    'size': 'M',
                    'color': 'Black',
                }],
            },
            format='json',
        )

        self.assertEqual(updated.status_code, 200)
        self.assertEqual(len(updated.data['items']), 1)
        self.assertEqual(updated.data['items'][0]['quantity'], 2)
        self.assertEqual(CartItem.objects.count(), 1)

    def test_cart_rejects_unknown_products(self):
        response = self.client.put(
            self.cart_url,
            {'items': [{'product': 999, 'quantity': 1}]},
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(CartItem.objects.count(), 0)


class OrderApiTests(APITestCase):
    def setUp(self):
        auth_response = self.client.post(
            '/api/auth/register/',
            {
                'first_name': 'Test',
                'last_name': 'Customer',
                'email': 'customer@example.test',
                'password': 'StrongPass!8292',
            },
            format='json',
        )
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {auth_response.data['access']}"
        )
        shop = Shop.objects.create(name='Test mağaza')
        self.product = Product.objects.create(
            shop=shop,
            name='Test məhsul',
            price='19.99',
            stock=5,
        )

    def test_order_is_created_with_server_price_and_cart_snapshot(self):
        cart = Cart.objects.create(cart_id='checkout-cart')
        CartItem.objects.create(
            cart=cart,
            product=self.product,
            quantity=2,
            size='M',
            color='Black',
        )
        response = self.client.post(
            '/api/orders/',
            {
                'user': {
                    'name': 'Test müştəri',
                    'email': 'customer@example.test',
                    'phone': '+994500000000',
                },
                'cart_id': cart.cart_id,
                'items': [{
                    'product': self.product.id,
                    'quantity': 2,
                    'size': 'M',
                    'color': 'Black',
                }],
                'delivery_address': 'Bakı',
                'promo_code': 'WELCOME10',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['total_price'], '35.98')
        self.assertEqual(response.data['delivery_address'], 'Bakı')
        self.assertEqual(response.data['promo_code'], 'WELCOME10')
        self.assertEqual(response.data['items'][0]['product'], self.product.id)
        self.assertEqual(response.data['items'][0]['quantity'], 2)
        self.assertEqual(Order.objects.count(), 1)
        self.assertEqual(CartItem.objects.count(), 0)

        order_history = self.client.get(
            '/api/orders/',
            {'email': 'CUSTOMER@example.test'},
        )
        self.assertEqual(order_history.status_code, 200)
        self.assertEqual(len(order_history.data), 1)
        self.assertEqual(order_history.data[0]['id'], response.data['id'])

    def test_order_rejects_unknown_products(self):
        response = self.client.post(
            '/api/orders/',
            {
                'user': {
                    'name': 'Test müştəri',
                    'email': 'customer@example.test',
                },
                'items': [{'product': 999, 'quantity': 1}],
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Order.objects.count(), 0)

    def test_orders_require_authenticated_account(self):
        self.client.credentials()

        response = self.client.get('/api/orders/')

        self.assertEqual(response.status_code, 401)
