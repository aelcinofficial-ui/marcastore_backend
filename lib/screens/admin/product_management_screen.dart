import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  Uint8List? _pickedImageBytes;
  String? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = Provider.of<AppProvider>(context).categories;
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first['name'];
    }
  }

  void _addProduct() {
    if (!_formKey.currentState!.validate()) return;
    final app = Provider.of<AppProvider>(context, listen: false);
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: '',
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      image: _imageCtrl.text.trim(),
      category: _selectedCategory?.trim() ?? '',
    );
    app.addProduct(product);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Məhsul əlavə olundu')));
    _nameCtrl.clear();
    _priceCtrl.clear();
    _imageCtrl.clear();
    _pickedImageBytes = null;
    _selectedCategory = Provider.of<AppProvider>(context, listen: false)
        .categories
        .firstWhere(
          (category) => category['name'] != null,
          orElse: () => {'name': ''},
        )['name'];
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;
      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null) return;
      final ext = result.files.first.extension ?? 'png';
      final mime = 'image/$ext';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() {
        _pickedImageBytes = bytes;
        _imageCtrl.text = dataUri;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Məhsul İdarəetməsi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qiymət'),
                validator: (v) => v == null || v.isEmpty ? 'Daxil edin' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_pickedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _pickedImageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_imageCtrl.text.startsWith('http'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageCtrl.text,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, size: 40),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Şəkil URL / Data URI',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Qalereyadan seç'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _imageCtrl.clear();
                                  _pickedImageBytes = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Təmizlə'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: appProvider.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category['name'],
                            child: Text(category['name'] ?? ''),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Kateqoriya'),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Kateqoriya seçin'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Əlavə et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
