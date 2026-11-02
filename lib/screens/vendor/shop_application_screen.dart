import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

class ShopApplicationScreen extends StatefulWidget {
  const ShopApplicationScreen({super.key});

  @override
  State<ShopApplicationScreen> createState() => _ShopApplicationScreenState();
}

class _ShopApplicationScreenState extends State<ShopApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      context.read<AppProvider>().submitShopApplication(
        shopName: _nameController.text,
        logo: _logoController.text,
        description: _descriptionController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müraciətiniz admin tərəfindən baxılır.'),
        ),
      );
      Navigator.pop(context);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı müraciəti')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Mağazanız haqqında məlumatları daxil edin. Müraciət admin tərəfindən təsdiqləndikdən sonra məhsul əlavə edə biləcəksiniz.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Mağaza adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Mağaza adını daxil edin'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _logoController,
              decoration: const InputDecoration(
                labelText: 'Logo URL-i (istəyə bağlı)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mağaza haqqında',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 6,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Mağaza haqqında qısa məlumat daxil edin'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Müraciəti göndər'),
            ),
          ],
        ),
      ),
    );
  }
}
