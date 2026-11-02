import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInWebButton extends StatelessWidget {
  const GoogleSignInWebButton({
    required this.onAccount,
    required this.onError,
    super.key,
  });

  final Future<void> Function(GoogleSignInAccount account) onAccount;
  final void Function(Object error) onError;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
