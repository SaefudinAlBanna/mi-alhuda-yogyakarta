// lib/app/modules/manajemen_kategori_keuangan/views/manajemen_kategori_keuangan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manajemen_kategori_keuangan_controller.dart';

class ManajemenKategoriKeuanganView extends GetView<ManajemenKategoriKeuanganController> {
  const ManajemenKategoriKeuanganView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarKategori.isEmpty) {
          return const Center(
            child: Text("Belum ada kategori pengeluaran.\nSilakan tambahkan satu.", textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          itemCount: controller.daftarKategori.length,
          itemBuilder: (context, index) {
            final kategori = controller.daftarKategori[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                title: Text(kategori),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => controller.showFormDialog(kategoriLama: kategori),
                      tooltip: "Edit Kategori",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => controller.hapusKategori(kategori),
                      tooltip: "Hapus Kategori",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Tambah Kategori"),
      ),
    );
  }
}