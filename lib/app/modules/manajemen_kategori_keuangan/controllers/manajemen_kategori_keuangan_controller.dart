// lib/app/modules/manajemen_kategori_keuangan/controllers/manajemen_kategori_keuangan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';

class ManajemenKategoriKeuanganController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxList<String> daftarKategori = <String>[].obs;

  DocumentReference get _configRef => _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('pengaturan').doc('konfigurasi_keuangan');

  @override
  void onInit() {
    super.onInit();
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    isLoading.value = true;
    try {
      final doc = await _configRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final kategoriFromDb = (data['daftarKategoriPengeluaran'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        daftarKategori.assignAll(kategoriFromDb);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kategori: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void showFormDialog({String? kategoriLama}) {
    final formKey = GlobalKey<FormState>();
    final kategoriC = TextEditingController(text: kategoriLama);
    final isEditMode = kategoriLama != null;

    Get.defaultDialog(
      title: isEditMode ? "Edit Kategori" : "Tambah Kategori Baru",
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: kategoriC,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Nama Kategori"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Nama kategori tidak boleh kosong.";
            }
            // Cek duplikat (case-insensitive)
            if (daftarKategori.any((k) => k.toLowerCase() == value.trim().toLowerCase() && k != kategoriLama)) {
              return "Kategori ini sudah ada.";
            }
            return null;
          },
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isSaving.value ? null : () {
          if (formKey.currentState?.validate() ?? false) {
            _simpanKategori(kategoriC.text.trim(), kategoriLama: kategoriLama);
          }
        },
        child: isSaving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  Future<void> _simpanKategori(String kategoriBaru, {String? kategoriLama}) async {
    isSaving.value = true;
    try {
      if (kategoriLama != null) { // Mode Edit
        // Firestore tidak bisa edit item array, jadi kita baca, ubah, lalu timpa
        List<String> listUpdated = List<String>.from(daftarKategori);
        final index = listUpdated.indexWhere((k) => k == kategoriLama);
        if (index != -1) {
          listUpdated[index] = kategoriBaru;
          await _configRef.set(
            {'daftarKategoriPengeluaran': listUpdated},
            SetOptions(merge: true),
          );
        }
      } else { // Mode Tambah
        await _configRef.set(
          {'daftarKategoriPengeluaran': FieldValue.arrayUnion([kategoriBaru])},
          SetOptions(merge: true),
        );
      }
      Get.back(); // Tutup dialog
      await _fetchKategori(); // Refresh data dari Firestore
      Get.snackbar("Berhasil", "Daftar kategori telah diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan kategori: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  void hapusKategori(String kategori) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus kategori '$kategori'? Tindakan ini tidak dapat dibatalkan.",
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          Get.back();
          try {
            await _configRef.update({
              'daftarKategoriPengeluaran': FieldValue.arrayRemove([kategori])
            });
            daftarKategori.remove(kategori); // Optimis UI update
            Get.snackbar("Berhasil", "Kategori '$kategori' telah dihapus.");
          } catch (e) {
            Get.snackbar("Error", "Gagal menghapus kategori: ${e.toString()}");
          }
        },
        child: const Text("Ya, Hapus"),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }
}