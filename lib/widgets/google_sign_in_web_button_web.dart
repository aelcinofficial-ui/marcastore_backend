import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_sign_in_web;

class GoogleSignInWebButton extends StatefulWidget {
  const GoogleSignInWebButton({
    required this.onAccount,
    required this.onError,
    super.key,
  });

  final Future<void> Function(GoogleSignInAccount account) onAccount;
  final void Function(Object error) onError;

  @override
  State<GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<GoogleSignInWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        unawaited(_handleAccount(event.user));
      }
    }, onError: (Object error) => widget.onError(error));
  }

  Future<void> _handleAccount(GoogleSignInAccount account) async {
    try {
      await widget.onAccount(account);
    } catch (error) {
      widget.onError(error);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => google_sign_in_web.renderButton();
}
