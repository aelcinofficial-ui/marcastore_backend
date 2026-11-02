import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _logout(BuildContext context) async {
    try {
      // 1. Token-ləri yaddaşdan təmizləyirik
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');

      // 2. İstifadəçini giriş ekranına yönləndiririk
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      debugPrint("Çıxış xətası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'İstifadəçi Profili',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Çıxış Yap (Logout)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
