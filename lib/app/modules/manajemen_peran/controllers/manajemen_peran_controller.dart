// lib/app/modules/manajemen_peran/controllers/manajemen_peran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

class ManajemenPeranController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- STATE ---
  final TextEditingController textC = TextEditingController();
  final RxBool isLoading = false.obs;

  // --- HELPER UNTUK AKSES DOKUMEN ---
  DocumentReference get _docRef => _firestore
      .collection('Sekolah')
      .doc(configC.idSekolah)
      .collection('pengaturan')
      .doc('manajemen_peran');

  /// Fungsi generik untuk melakukan operasi Firestore dan menangani state.
  Future<void> _performOperation(
      Future<void> Function() operation, String successMessage) async {
    try {
      isLoading.value = true;
      await operation();
      // Sinkronkan kembali data di ConfigController setelah berhasil
      await configC.reloadRoleManagementData();
      Get.back(); // Tutup dialog
      Get.snackbar('Berhasil', successMessage);
    } catch (e) {
      Get.snackbar('Error', 'Operasi gagal: ${e.toString()}');
    } finally {
      isLoading.value = false;
      textC.clear();
    }
  }

  // --- LOGIKA UNTUK PERAN (ROLE) ---
  void tambahRole() {
    if (textC.text.trim().isEmpty) return;
    _performOperation(
      () => _docRef.update({
        'daftar_role': FieldValue.arrayUnion([textC.text.trim()])
      }),
      'Peran baru berhasil ditambahkan.',
    );
  }

  void hapusRole(String role) {
    _performOperation(
      () => _docRef.update({
        'daftar_role': FieldValue.arrayRemove([role])
      }),
      'Peran "$role" berhasil dihapus.',
    );
  }

  // --- LOGIKA UNTUK TUGAS ---
  void tambahTugas() {
    if (textC.text.trim().isEmpty) return;
    _performOperation(
      () => _docRef.update({
        'daftar_tugas': FieldValue.arrayUnion([textC.text.trim()])
      }),
      'Tugas baru berhasil ditambahkan.',
    );
  }

  void hapusTugas(String tugas) {
    _performOperation(
      () => _docRef.update({
        'daftar_tugas': FieldValue.arrayRemove([tugas])
      }),
      'Tugas "$tugas" berhasil dihapus.',
    );
  }

  // --- DIALOG FORM ---
  void showFormDialog({required bool isRole}) {
    textC.clear();
    Get.defaultDialog(
      title: isRole ? 'Tambah Peran Baru' : 'Tambah Tugas Baru',
      content: TextField(
        controller: textC,
        autofocus: true,
        decoration: InputDecoration(
          labelText: isRole ? 'Nama Peran' : 'Nama Tugas',
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
        Obx(() => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () => isRole ? tambahRole() : tambahTugas(),
              child: isLoading.value
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan'),
            )),
      ],
    );
  }
  
  // --- DIALOG KONFIRMASI HAPUS ---
  void showDeleteConfirmation({required String itemName, required bool isRole}) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Anda yakin ingin menghapus "$itemName"?',
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Get.back(); // Tutup dialog konfirmasi dulu
            isRole ? hapusRole(itemName) : hapusTugas(itemName);
          },
          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // Override onClose untuk membersihkan controller
  @override
  void onClose() {
    textC.dispose();
    super.onClose();
  }
}

// Tambahkan ini di ConfigController untuk memuat ulang data
// Buka file lib/app/controllers/config_controller.dart dan tambahkan method ini
/*
  Future<void> reloadRoleManagementData() async {
    await _syncRoleManagementData();
  }
*/