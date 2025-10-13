// lib/app/modules/pengaturan_alasan_keuangan/views/pengaturan_alasan_keuangan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pengaturan_alasan_keuangan_controller.dart';

class PengaturanAlasanKeuanganView extends GetView<PengaturanAlasanKeuanganController> {
  const PengaturanAlasanKeuanganView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alasan Keuangan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => controller.showAddEditDialog(),
            tooltip: "Tambah Alasan Baru",
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.alasanList.isEmpty) {
          return const Center(child: Text("Belum ada alasan. Silakan tambahkan."));
        }
        return ReorderableListView.builder(
          itemCount: controller.alasanList.length,
          itemBuilder: (context, index) {
            final alasan = controller.alasanList[index];
            return ListTile(
              key: ValueKey(alasan + index.toString()),
              leading: const Icon(Icons.drag_handle),
              title: Text(alasan),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => controller.showAddEditDialog(initialValue: alasan, index: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.removeAlasan(index),
                  ),
                ],
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = controller.alasanList.removeAt(oldIndex);
            controller.alasanList.insert(newIndex, item);
          },
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : controller.saveChanges,
          icon: controller.isSaving.value 
              ? const SizedBox(width:18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.save),
          label: const Text("Simpan Perubahan Urutan/Daftar"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        )),
      ),
    );
  }
}