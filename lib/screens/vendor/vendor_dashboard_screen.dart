import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, child) {
        final shop = app.vendorShop;
        if (!app.isVendor ||
            shop == null ||
            shop.status != ShopStatus.approved) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mağazam')),
            body: const Center(
              child: Text(
                'Mağaza paneli yalnız təsdiqlənmiş satıcılar üçündür.',
              ),
            ),
          );
        }

        final products = app.vendorProducts;
        return Scaffold(
          appBar: AppBar(title: Text(shop.shopName)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openProductForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Məhsul əlavə et'),
          ),
          body: products.isEmpty
              ? const Center(child: Text('Mağazanızda hələ məhsul yoxdur.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        leading: _productThumbnail(product.image),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.price.toStringAsFixed(2)} AZN',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _openProductForm(context, product: product);
                            } else if (action == 'delete') {
                              _deleteProduct(context, product);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Redaktə et'),
                            ),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _productThumbnail(String source) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported_outlined),
      );
    }
    if (source.startsWith('data:')) {
      final separator = source.indexOf(',');
      if (separator >= 0) {
        try {
          return Image.memory(
            base64Decode(source.substring(separator + 1)),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          );
        } on FormatException {
          return const Icon(Icons.image_not_supported_outlined);
        }
      }
    }
    return const Icon(Icons.image_outlined);
  }

  Future<void> _openProductForm(
    BuildContext context, {
    Product? product,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VendorProductForm(product: product),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Məhsul əlavə olundu' : 'Məhsul yeniləndi',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Məhsulu silmək?'),
        content: Text('"${product.name}" mağazadan silinəcək.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ləğv et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      context.read<AppProvider>().removeVendorProduct(product.id);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _VendorProductForm extends StatefulWidget {
  final Product? product;

  const _VendorProductForm({this.product});

  @override
  State<_VendorProductForm> createState() => _VendorProductFormState();
}

class _VendorProductFormState extends State<_VendorProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imagesController;
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _imagesController = TextEditingController(
      text:
          (product?.images.isNotEmpty == true
                  ? product!.images
                  : product == null
                  ? <String>[]
                  : <String>[product.image])
              .join('\n'),
    );
    _category = product?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      final picked = <String>[];
      for (final file in result.files) {
        final Uint8List? bytes = file.bytes;
        if (bytes == null) {
          throw StateError('${file.name} şəkli oxuna bilmədi.');
        }
        final extension = (file.extension ?? 'png').toLowerCase();
        final mime = extension == 'jpg' ? 'jpeg' : extension;
        picked.add('data:image/$mime;base64,${base64Encode(bytes)}');
      }
      final existing = _imagesController.text.trim();
      _imagesController.text = [
        if (existing.isNotEmpty) existing,
        ...picked,
      ].join('\n');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Şəkillər seçilmədi: $error')));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    final shop = app.vendorShop;
    if (!app.isVendor || shop == null || shop.status != ShopStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Təsdiqlənmiş mağaza tələb olunur.')),
      );
      return;
    }

    final images = _imagesController.text
        .split('\n')
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();
    final product = Product(
      id:
          widget.product?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      image: images.first,
      images: images,
      shopId: shop.id,
      category: _category!,
      rating: widget.product?.rating ?? 4.5,
      sizes: widget.product?.sizes ?? const ['S', 'M', 'L', 'XL'],
      colors: widget.product?.colors ?? const ['Qara', 'Ağ'],
    );

    setState(() => _saving = true);
    try {
      if (widget.product == null) {
        app.addVendorProduct(product);
      } else {
        app.updateVendorProduct(product);
      }
      Navigator.pop(context, true);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppProvider>().categories;
    _category ??=
        widget.product?.category ??
        (categories.isEmpty ? null : categories.first['name']);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.product == null ? 'Yeni məhsul' : 'Məhsulu redaktə et',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Məhsulun adı'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Məhsulun adını daxil edin'
                  : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Təsvir'),
              minLines: 2,
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Məhsulun təsvirini daxil edin'
                  : null,
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Qiymət (AZN)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final price = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                return price == null || price <= 0
                    ? 'Düzgün qiymət daxil edin'
                    : null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kateqoriya'),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category['name'],
                      child: Text(category['name'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Kateqoriya seçin' : null,
            ),
            TextFormField(
              controller: _imagesController,
              decoration: const InputDecoration(
                labelText: 'Şəkillərin URL-i (hər sətirdə bir şəkil)',
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 5,
              validator: (value) =>
                  value == null ||
                      value.split('\n').every((image) => image.trim().isEmpty)
                  ? 'Ən azı bir şəkil əlavə edin'
                  : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Qalereyadan şəkil seç'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saxlanılır...' : 'Saxla'),
            ),
          ],
        ),
      ),
    );
  }
}
