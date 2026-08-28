import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/widgets/product_image.dart';
import '../../customer/models/product_model.dart';
import '../providers/vendor_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _vendorNameController;
  Uint8List? _imageBytes;

  String _selectedCategory = 'Clothing';
  final List<String> _categories = [
    'Clothing',
    'Home Accessories',
    'Footwear',
    'Jewelry',
    'Bags'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _vendorNameController = TextEditingController(
        text: p?.vendorName ?? ref.read(vendorBrandProvider));
    _imageBytes = p?.imageBytes;

    if (p != null && _categories.contains(p.category)) {
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.productToEdit != null;
    final newProduct = ProductModel(
      id: isEditing
          ? widget.productToEdit!.id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      vendorName: _vendorNameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      imageUrl: _imageUrlController.text.trim(),
      imageBytes: _imageBytes,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      stockQuantity: widget.productToEdit?.stockQuantity ?? 5,
      isLightningDeal: widget.productToEdit?.isLightningDeal ?? false,
      rating: widget.productToEdit?.rating ?? 4.8,
      approvalStatus: widget.productToEdit?.approvalStatus ?? 'pending',
    );

    try {
      if (isEditing) {
        await ref.read(vendorProductsProvider.notifier).updateProduct(newProduct);
      } else {
        await ref.read(vendorProductsProvider.notifier).addProduct(newProduct);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Product updated successfully.'
                : 'Product submitted! It will appear in admin review before storefront approval.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes != null && mounted) setState(() => _imageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (₦)',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter price';
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(
                  labelText: 'Brand / Vendor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter vendor name' : null,
              ),
              const SizedBox(height: 16),
              const Text('PRODUCT IMAGE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductImage(
                    imageUrl: _imageUrlController.text,
                    imageBytes: _imageBytes,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Upload from this device'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                onChanged: (_) => setState(() => _imageBytes = null),
                decoration: const InputDecoration(
                  labelText: 'Or use an image URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Update Listing' : 'Publish Product',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
