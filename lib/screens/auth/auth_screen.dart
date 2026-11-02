import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../providers/providers.dart';
import '../../config/auth_config.dart';
import '../../widgets/google_sign_in_web_button_stub.dart'
    if (dart.library.js_interop) '../../widgets/google_sign_in_web_button_web.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static Future<void>? _googleSignInInitialization;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isRegister = true;
  bool _loading = false;
  bool _googleWebReady = false;
  String? _googleWebConfigurationError;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeGoogleWeb();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isRegister && _passwordCtrl.text != _confirmPasswordCtrl.text) {
        throw const FormatException('Şifrələr uyğun deyil.');
      }

      final appProvider = context.read<AppProvider>();
      if (_isRegister) {
        await appProvider.registerWithDjango(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await appProvider.loginWithDjango(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegister
                ? 'Qeydiyyat Django-da uğurla tamamlandı'
                : 'Django hesabına uğurla daxil oldunuz',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Giriş alınmadı: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPasswordRecoveryInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_reset, color: Color(0xFF6C63FF)),
        title: const Text('Şifrəni unutmusunuz?'),
        content: const Text(
          'Şifrə bərpası hazırda aktiv deyil. Hesabınıza daxil olmaq üçün Django qeydiyyatında istifadə etdiyiniz şifrədən istifadə edin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bağla'),
          ),
        ],
      ),
    );
  }

  Future<void> _socialLogin(String provider) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final appProvider = context.read<AppProvider>();
      if (provider == 'facebook') {
        if (kIsWeb && AuthConfig.facebookAppId.isEmpty) {
          throw StateError('FACEBOOK_APP_ID konfiqurasiya edilməyib.');
        }
        final result = await FacebookAuth.instance.login(
          permissions: const ['email', 'public_profile'],
          loginTracking: LoginTracking.enabled,
        );
        if (result.status == LoginStatus.cancelled) return;
        if (result.status != LoginStatus.success ||
            result.accessToken == null) {
          throw Exception(result.message ?? 'Facebook girişi uğursuz oldu.');
        }
        await appProvider.loginWithSocialProvider(
          provider: provider,
          token: result.accessToken!.tokenString,
        );
      } else {
        const appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
        const appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');
        final options = defaultTargetPlatform == TargetPlatform.android
            ? WebAuthenticationOptions(
                clientId: appleServiceId,
                redirectUri: Uri.parse(appleRedirectUri),
              )
            : null;
        if (defaultTargetPlatform == TargetPlatform.android &&
            (appleServiceId.isEmpty ||
                appleRedirectUri.isEmpty ||
                options!.redirectUri.host.isEmpty)) {
          throw StateError(
            'Android Apple girişi üçün APPLE_SERVICE_ID, '
            'APPLE_REDIRECT_URI tələb olunur.',
          );
        }
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: options,
        );
        final identityToken = credential.identityToken;
        if (identityToken == null || identityToken.isEmpty) {
          throw const FormatException('Apple identity token qaytarmadı.');
        }
        final name = [
          credential.givenName,
          credential.familyName,
        ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
        await appProvider.loginWithSocialProvider(
          provider: provider,
          token: identityToken,
          name: name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${provider == 'apple' ? 'Apple' : 'Facebook'} hesabı ilə Django-ya qoşuldunuz.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sosial giriş alınmadı: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (AuthConfig.googleWebClientId.isEmpty) {
        throw StateError('GOOGLE_WEB_CLIENT_ID konfiqurasiya edilməyib.');
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          AuthConfig.googleIosClientId.isEmpty) {
        throw StateError('iOS üçün GOOGLE_IOS_CLIENT_ID tələb olunur.');
      }

      final initialization = _googleSignInInitialization ??= GoogleSignIn
          .instance
          .initialize(
            clientId: AuthConfig.googleIosClientId.isEmpty
                ? null
                : AuthConfig.googleIosClientId,
            serverClientId: AuthConfig.googleWebClientId,
          );
      await initialization;

      final googleSignIn = GoogleSignIn.instance;
      if (!googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError('Google ilə giriş bu platformada mövcud deyil.');
      }
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('Google ID Token tapılmadı!');
        throw const FormatException('Google identity token qaytarmadı.');
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      if (response.statusCode != 200) {
        throw StateError(
          'Django Google auth sorğusu uğursuz oldu '
          '(${response.statusCode}): ${response.body}',
        );
      }
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = responseData['access'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const FormatException('Django cavabında access token tapılmadı.');
      }
      final refreshToken = responseData['refresh'];
      if (refreshToken != null && refreshToken is! String) {
        throw const FormatException(
          'Django cavabındakı refresh token düzgün deyil.',
        );
      }

      await _secureStorage.write(key: 'access_token', value: accessToken);
      if (refreshToken is String && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on GoogleSignInException catch (error) {
      debugPrint('Google Sign-In Xətası: $error');
      if (error.code == GoogleSignInExceptionCode.canceled || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google girişi alınmadı: $error')));
    } catch (error) {
      debugPrint('Google Sign-In Xətası: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google girişi alınmadı: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initializeGoogleWeb() async {
    if (AuthConfig.googleWebClientId.isEmpty) {
      _googleWebConfigurationError =
          'GOOGLE_WEB_CLIENT_ID --dart-define ilə verilməlidir.';
      return;
    }
    try {
      await GoogleSignIn.instance.initialize(
        clientId: AuthConfig.googleWebClientId,
      );
      if (mounted) setState(() => _googleWebReady = true);
    } catch (error) {
      if (mounted) {
        setState(() => _googleWebConfigurationError = error.toString());
      }
    }
  }

  Future<void> _googleWebAccount(GoogleSignInAccount account) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _exchangeGoogleAccount(context.read<AppProvider>(), account);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google hesabı ilə Django-ya qoşuldunuz.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google girişi alınmadı: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _googleWebError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Google girişi alınmadı: $error')));
  }

  Future<void> _exchangeGoogleAccount(
    AppProvider appProvider,
    GoogleSignInAccount account,
  ) async {
    final identityToken = account.authentication.idToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const FormatException('Google identity token qaytarmadı.');
    }
    await appProvider.loginWithSocialProvider(
      provider: 'google',
      token: identityToken,
      name: account.displayName,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9E9EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        title: Text(_isRegister ? 'Qeydiyyat' : 'Daxil ol'),
        backgroundColor: const Color(0xFFF5F5F9),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29254A).withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF958CFF)],
                          ),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'BRAND SHOPPING',
                        style: TextStyle(
                          color: Color(0xFF29283A),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegister
                            ? 'Yeni hesabınızı yaradın və alış-verişə başlayın'
                            : 'Xoş gəlmisiniz! Hesabınıza daxil olun',
                        style: TextStyle(color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F2F8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildModeButton('Qeydiyyat', _isRegister, true),
                            _buildModeButton('Daxil ol', !_isRegister, false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isRegister) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                  label: 'Ad',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Adınızı daxil edin'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                  label: 'Soyad',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Soyadınızı daxil edin'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: _inputDecoration(
                          label: 'E-poçt',
                          icon: Icons.mail_outline,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Düzgün e-poçt daxil edin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegister
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_isRegister) _submit();
                        },
                        decoration: _inputDecoration(
                          label: 'Şifrə',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Şifrəni göstər'
                                : 'Şifrəni gizlət',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Şifrəni daxil edin'
                            : null,
                      ),
                      if (_isRegister) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            label: 'Şifrəni təkrar edin',
                            icon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Şifrəni göstər'
                                  : 'Şifrəni gizlət',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Şifrəni təkrar daxil edin'
                              : null,
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showPasswordRecoveryInfo,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Şifrəni unutmusunuz?'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Hesab yarat' : 'Daxil ol',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'və ya bununla davam edin',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (kIsWeb)
                        if (_googleWebReady)
                          SizedBox(
                            height: 48,
                            child: GoogleSignInWebButton(
                              onAccount: _googleWebAccount,
                              onError: _googleWebError,
                            ),
                          )
                        else
                          Column(
                            children: [
                              _buildSocialButton(
                                label: 'Google ilə davam et',
                                foreground: const Color(0xFF202124),
                                background: Colors.white,
                                border: const Color(0xFFDADCE0),
                                leading: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                              if (_googleWebConfigurationError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _googleWebConfigurationError!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          )
                      else
                        _buildSocialButton(
                          label: 'Google ilə davam et',
                          foreground: const Color(0xFF202124),
                          background: Colors.white,
                          border: const Color(0xFFDADCE0),
                          leading: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          onPressed: _handleGoogleSignIn,
                        ),
                      const SizedBox(height: 10),
                      _buildSocialButton(
                        label: 'Apple ilə davam et',
                        foreground: Colors.white,
                        background: const Color(0xFF17171A),
                        leading: const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => _socialLogin('apple'),
                      ),
                      const SizedBox(height: 10),
                      _buildSocialButton(
                        label: 'Facebook ilə davam et',
                        foreground: Colors.white,
                        background: const Color(0xFF1877F2),
                        leading: const Text(
                          'f',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => _socialLogin('facebook'),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _isRegister
                                ? 'Hesabınız var? '
                                : 'Hesabınız yoxdur? ',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegister = !_isRegister;
                                _formKey.currentState?.reset();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              _isRegister ? 'Daxil olun' : 'Qeydiyyatdan keçin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool selected, bool registerMode) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isRegister != registerMode) {
            setState(() {
              _isRegister = registerMode;
              _formKey.currentState?.reset();
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF777786),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color foreground,
    required Color background,
    required Widget leading,
    required VoidCallback onPressed,
    Color? border,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(color: border ?? background),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, child: Center(child: leading)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
