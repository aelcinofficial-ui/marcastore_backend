# marcastore_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local Django API

Start the backend from the `marcastore_backend` directory:

```sh
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

For test products, create an admin account with `python manage.py createsuperuser`,
open `http://localhost:8000/admin/`, add a shop, then add products to that shop.
The Flutter catalog loads products from Django and can add them to the app's cart.
The cart is synchronized with Django and restored using a locally stored cart
identifier. Checkout creates an order in Django using the product prices from
the database; orders are also loaded from Django in the order history. Promo
codes `WELCOME10`, `SUMMER20`, and `FREESHIP` are validated by the backend.
Card details are not sent to Django.

## Django account sign-in

Email registration and login use Django password hashing and return short-lived
JWT access tokens with refresh tokens. The app stores tokens in the platform's
secure storage. Orders require a valid JWT and are associated with that account.
Run `python manage.py migrate` after pulling backend changes.

iOS builds require iOS 15 or later.

Facebook and Apple sign-in require provider-owned app configuration; the
repository intentionally contains placeholders, not provider credentials:

- Set `FACEBOOK_APP_ID` and `FACEBOOK_APP_SECRET` in the Django process
  environment. Keep the app secret on the server only. Replace
  `YOUR_FACEBOOK_APP_ID` and `YOUR_FACEBOOK_CLIENT_TOKEN` in
  `android/app/src/main/res/values/strings.xml` and
  `ios/Runner/Info.plist` with the values from Meta. Register the Android
  package/key hashes and iOS bundle ID in Meta Developer settings.
- Enable Sign in with Apple for the iOS app ID `com.example.marcastoreApp` in
  Apple Developer and use that ID in Django's `APPLE_CLIENT_IDS`. For Android,
  create an Apple Service ID, add the HTTPS URL
  `https://YOUR_API_HOST/api/auth/apple/callback/` as its return URL, and
  include the Service ID in `APPLE_CLIENT_IDS`.
- For Android Flutter builds, pass the Apple Service ID and the same callback
  URL:

  ```sh
  flutter run \
    --dart-define=APPLE_SERVICE_ID=YOUR_APPLE_SERVICE_ID \
    --dart-define=APPLE_REDIRECT_URI=https://YOUR_API_HOST/api/auth/apple/callback/
  ```

The backend validates Facebook access tokens with Meta and Apple identity tokens
against Apple's signing keys and configured audiences. OAuth cannot be tested
against the real providers until their credentials and app registrations are
configured. `python manage.py test api` exercises registration, password
verification, JWT profile access, and mocked provider-token verification.

### Google sign-in

1. In Google Cloud Console, configure an Android OAuth client for package
   `com.example.marcastore_app` and its signing SHA-1 fingerprint, an iOS OAuth
   client for the app's bundle ID, and a Web application OAuth client. The Web
   client ID is the audience used by Django to validate the ID token. These
   client IDs are public identifiers; never put a client secret in Flutter.
2. Set `GOOGLE_CLIENT_ID` in the Django process environment to the Web client
   ID. To accept multiple OAuth clients, set `GOOGLE_CLIENT_IDS` to a
   comma-separated list instead:

   ```sh
   GOOGLE_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID python manage.py runserver 0.0.0.0:8000
   ```

   Google sign-in is available at `POST /api/auth/google/` with an
   `id_token` JSON field. It returns access and refresh JWTs.

3. Configure the Flutter build with the same Web client ID and the iOS OAuth
   client ID. For Android:

   ```sh
   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
   ```

   For iOS, also pass `--dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_GOOGLE_IOS_CLIENT_ID`.
   For Flutter Web, set the Web client ID in `web/index.html` at
   `google-signin-client_id`, and run on a fixed localhost port registered in
   Google Cloud Console:

   ```sh
   flutter run -d chrome --web-hostname localhost --web-port 7357 \
     --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
   ```

   Add both `http://localhost` and `http://localhost:7357` to that OAuth
   client's **Authorized JavaScript origins**. The Web login uses the Google
   SDK-rendered button; browser `authenticate()` is not supported by Google's
   web implementation.
   In `ios/Runner/Info.plist`, replace
   `REPLACE_WITH_GOOGLE_REVERSED_CLIENT_ID` with the `REVERSED_CLIENT_ID` from
   Google’s iOS configuration. For physical iOS devices, use a reachable HTTPS
   API URL in `API_BASE_URL`.
4. The login screen sends Google's ID token to
   `POST /api/auth/social/google/` as `{"id_token": "..."}`. Django verifies
   the signature, expiration, issuer, and audience using Google's public keys,
   requires a verified email, creates or links the account, then returns the
   same access/refresh JWT response as the other login methods.

The backend dependency `google-auth` is listed in `marcastore_backend/requirements.txt`.
Install/update backend dependencies before starting Django. Use the Android
debug/release signing SHA-1 values appropriate to each build; OAuth will not
work until the Google Cloud client IDs and platform registrations match.

For Facebook login in Flutter Web, start the app with
`--dart-define=FACEBOOK_APP_ID=YOUR_FACEBOOK_APP_ID`. `main.dart` initializes
the Facebook JavaScript SDK before `runApp()`; the plugin loads the SDK script
itself, so do not add a second SDK script to `web/index.html`. In Meta Developer
settings, enable **Login with the JavaScript SDK** and allow `localhost` under
the Facebook Login JavaScript SDK domains. Facebook Web sign-in requires HTTPS
or localhost.

To run both Google and Facebook sign-in locally on the web:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID \
  --dart-define=FACEBOOK_APP_ID=YOUR_FACEBOOK_APP_ID \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Replace the Google client ID placeholder in `web/index.html` too, and register
`http://localhost:7357` as a Google Authorized JavaScript origin and `localhost`
as a Meta JavaScript SDK allowed domain.

The Android emulator uses `10.0.2.2` to reach the development computer; the
iOS simulator uses `127.0.0.1`. For a physical phone, pass the computer's
reachable LAN address when starting Flutter, and allow that address in
`DJANGO_ALLOWED_HOSTS` when starting Django:

```sh
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.10 python manage.py runserver 0.0.0.0:8000
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Replace `192.168.1.10` with the development computer's LAN IP. The phone and
computer must be on the same network. Use HTTPS and a production API URL for
release builds.
