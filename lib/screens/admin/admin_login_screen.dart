import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Hardcoded credentials as requested
    if (username == 'elcin1989' && password == '1989Elcin') {
      final admin = User(
        id: 'admin-1',
        firstName: 'Elcin',
        lastName: 'Admin',
        email: 'elcin@admin.local',
        role: UserRole.admin,
      );
      Provider.of<AppProvider>(context, listen: false).setCurrentUser(admin);

      setState(() => _loading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'İstifadəçi adı'),
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Parol'),
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Giriş'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
