import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/data/models/product_model.dart';

class FormProductPage extends StatefulWidget {
  final ProductModel? product; // Jika null = Tambah Baru. Jika ada isinya = Edit.

  const FormProductPage({super.key, this.product});

  @override
  State<FormProductPage> createState() => _FormProductPageState();
}

class _FormProductPageState extends State<FormProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _selectedCategory;

  // --- VARIABEL UNTUK IMAGE PICKER ---
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Daftar kategori
  final List<String> _categories = ['Mesin', 'Pengabutan', 'Transmisi', 'Kelistrikan', 'Pengereman', 'Kaki-kaki', 'Pelumas', 'Aksesoris'];

  @override
  void initState() {
    super.initState();
    final isEdit = widget.product != null;

    _nameController = TextEditingController(text: isEdit ? widget.product!.name : '');
    _descController = TextEditingController(text: isEdit ? widget.product!.description : '');
    _priceController = TextEditingController(text: isEdit ? widget.product!.price.toString() : '');
    _stockController = TextEditingController(text: isEdit ? (widget.product!.stock?.toString() ?? '0') : '');
    _selectedCategory = isEdit ? widget.product!.category : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // --- FUNGSI PILIH GAMBAR DARI GALERI ---
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80); // Kompresi gambar
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- FUNGSI UPLOAD GAMBAR KE SUPABASE ---
  Future<String?> _uploadImageToSupabase() async {
    if (_imageFile == null) return null;

    setState(() => _isUploading = true);
    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = 'komponen_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Pastikan kamu punya bucket bernama 'product-images' yang Public di Supabase Storage
      await Supabase.instance.client.storage
          .from('product-images')
          .upload(fileName, _imageFile!);

      final publicUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload gambar: $e'), backgroundColor: Colors.red));
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- FUNGSI SIMPAN FORM ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {

      // Validasi Gambar
      if (_imageFile == null && widget.product == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih foto komponen!'), backgroundColor: Colors.orange));
        return;
      }

      // Ambil URL lama (jika edit) atau upload baru
      String imageUrl = widget.product?.imageUrl ?? '';
      if (_imageFile != null) {
        final uploadedUrl = await _uploadImageToSupabase();
        if (uploadedUrl == null) return; // Berhenti jika gagal upload
        imageUrl = uploadedUrl;
      }

      final newProduct = ProductModel(
        id: widget.product?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: num.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        imageUrl: imageUrl,
        category: _selectedCategory,
      );

      // Lempar ke BLoC
      if (widget.product != null) {
        context.read<ProductBloc>().add(UpdateProductEvent(newProduct));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Komponen berhasil diperbarui!'), backgroundColor: Colors.green));
      } else {
        context.read<ProductBloc>().add(AddProductEvent(newProduct));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Komponen baru ditambahkan!'), backgroundColor: Colors.green));
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Komponen' : 'Tambah Komponen Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- KOTAK IMAGE PICKER ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                    : (isEdit && widget.product!.imageUrl.isNotEmpty)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(widget.product!.imageUrl, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 50, color: theme.primaryColor),
                    const SizedBox(height: 12),
                    Text("Tap untuk memilih foto", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- NAMA PRODUK ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Komponen',
                hintText: 'Contoh: Piston Forged R15',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build_circle_outlined),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // --- DESKRIPSI ---
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Detail',
                hintText: 'Masukkan spesifikasi teknis komponen...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // --- HARGA & STOK ---
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Isi harga' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stok',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Isi stok' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- KATEGORI ---
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'Pilih satu kategori' : null,
            ),
            const SizedBox(height: 32),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // Jangan biarkan diklik jika sedang upload
                onPressed: _isUploading ? null : _submitForm,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN KOMPONEN',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}