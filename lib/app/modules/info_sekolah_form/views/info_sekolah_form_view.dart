import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart'; // Pastikan import ini ada
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/info_sekolah/controllers/info_sekolah_controller.dart';

class InfoSekolahFormView extends GetView<InfoSekolahController> {
  const InfoSekolahFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DocumentSnapshot? infoToEdit = Get.arguments;
    // Gunakan 'addPostFrameCallback' untuk mengisi form setelah frame pertama selesai dirender
    // Ini mencegah error saat build sedang berlangsung.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (infoToEdit != null) {
        final data = infoToEdit.data() as Map<String, dynamic>;
        controller.judulC.text = data['judul'] ?? '';
        controller.isiC.text = data['isi'] ?? '';
        controller.existingImageUrl.value = data['imageUrl'] ?? '';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(infoToEdit == null ? 'Buat Informasi Baru' : 'Edit Informasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: controller.judulC, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22), decoration: const InputDecoration(hintText: 'Judul Informasi...', border: InputBorder.none)),
            const Divider(),
            const SizedBox(height: 20),
            _buildImagePicker(),
            const SizedBox(height: 20),
            TextField(controller: controller.isiC, maxLines: 15, keyboardType: TextInputType.multiline, style: const TextStyle(fontSize: 16, height: 1.5), decoration: const InputDecoration(hintText: 'Tuliskan informasi selengkapnya di sini...', border: InputBorder.none)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton(
              onPressed: controller.isFormLoading.value ? null : () => controller.simpanInfo(docIdToEdit: infoToEdit?.id),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: controller.isFormLoading.value ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('Publikasikan', style: TextStyle(fontSize: 16)),
            )),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Obx(() {
      if (controller.imageFile.value != null) {
        return _buildImagePreview(Image.file(controller.imageFile.value!, fit: BoxFit.cover));
      }
      if (controller.existingImageUrl.isNotEmpty) {
        return _buildImagePreview(Image.network(controller.existingImageUrl.value, fit: BoxFit.cover));
      }
      return _buildImageUploader();
    });
  }

  Widget _buildImageUploader() {
    // --- [PERBAIKAN KUNCI DI SINI] ---
    // Sintaks yang benar dan aman untuk DottedBorder
    return GestureDetector(
      onTap: controller.pickImage,
      child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            dashPattern: const [8, 4],
            strokeWidth: 2,
            radius: const Radius.circular(12),
            color: Colors.grey,
            padding: EdgeInsets.zero,
          ),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8), Text('Tambahkan Gambar (Opsional)', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _buildImagePreview(Widget imageWidget) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: double.infinity, height: 200, child: imageWidget)),
        Positioned(
          top: 8, right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: controller.removeImage),
          ),
        ),
      ],
    );
  }
}