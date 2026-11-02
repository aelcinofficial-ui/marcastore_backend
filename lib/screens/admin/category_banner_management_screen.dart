import 'dart:convert';
import 'dart:typed_data';
import 'package:marcastore_app/services/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

class CategoryBannerManagementScreen extends StatefulWidget {
  const CategoryBannerManagementScreen({super.key});

  @override
  State<CategoryBannerManagementScreen> createState() =>
      _CategoryBannerManagementScreenState();
}

class _CategoryBannerManagementScreenState
    extends State<CategoryBannerManagementScreen> {
  final _categoryNameCtrl = TextEditingController();
  final _categoryIconCtrl = TextEditingController();
  final _bannerUrlCtrl = TextEditingController();
  Uint8List? _pickedBannerBytes;

  Future<void> _pickBannerImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() {
        _pickedBannerBytes = file.bytes;
        final ext = file.extension ?? 'png';
        final mime = 'image/$ext';
        _bannerUrlCtrl.text = 'data:$mime;base64,${base64Encode(file.bytes!)}';
      });
    } catch (_) {
      // ignore
    }
  }

  void _addCategory() {
    final name = _categoryNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kateqoriya adını daxil edin')),
      );
      return;
    }
    final icon = _categoryIconCtrl.text.trim().isEmpty
        ? '📦'
        : _categoryIconCtrl.text.trim();

    Provider.of<AppProvider>(context, listen: false).addCategory(name, icon);
    _categoryNameCtrl.clear();
    _categoryIconCtrl.clear();
  }

  void _addBannerImage() {
    final imageValue = _bannerUrlCtrl.text.trim();
    if (imageValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner şəkil URL-i və ya fayl seçin')),
      );
      return;
    }
    Provider.of<AppProvider>(context, listen: false).addBannerImage(imageValue);
    _bannerUrlCtrl.clear();
    setState(() {
      _pickedBannerBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kateqoriyaların və Bannerlərin İdarə Edilməsi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kateqoriyalar'),
              Tab(text: 'Ana Səhifə Bannerləri'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. KATEQORİYALAR TAB-I
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _categoryNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kateqoriya adı',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _categoryIconCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Simvol (məs. 👕, 📱)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _addCategory,
                    child: const Text('Kateqoriya əlavə et'),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ApiService.getCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Xəta: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('Hələ heç bir kateqoriya yoxdur.'),
                          );
                        }

                        final categories = snapshot.data!;
                        return ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return Card(
                              child: ListTile(
                                leading: Text(
                                  category['icon'] ?? '📁',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(category['name'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    // Silmə əməliyyatı
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. BANNERLƏR TAB-I
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _bannerUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Banner URL / Data URI',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickBannerImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Qalereyadan seç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addBannerImage,
                          child: const Text('Banner əlavə et'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_pickedBannerBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _pickedBannerBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.bannerImages.length,
                      itemBuilder: (context, index) {
                        final banner = provider.bannerImages[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: banner.startsWith('data:')
                                    ? Image.memory(
                                        base64Decode(banner.split(',').last),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(banner, fit: BoxFit.cover),
                              ),
                              ListTile(
                                title: Text('Banner ${index + 1}'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    provider.removeBannerImage(banner);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
