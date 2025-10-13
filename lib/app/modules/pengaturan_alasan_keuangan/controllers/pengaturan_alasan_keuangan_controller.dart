// lib/app/modules/pengaturan_alasan_keuangan/controllers/pengaturan_alasan_keuangan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';

class PengaturanAlasanKeuanganController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  
  final RxList<String> alasanList = <String>[].obs;
  late final DocumentReference _docRef;

  @override
  void onInit() {
    super.onInit();
    _docRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('pengaturan').doc('konfigurasi_keuangan');
    _fetchAlasan();
  }

  Future<void> _fetchAlasan() async {
    isLoading.value = true;
    try {
      final doc = await _docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['alasanEditUangPangkal'] is List) {
          alasanList.assignAll(List<String>.from(data['alasanEditUangPangkal']));
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar alasan: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void showAddEditDialog({String? initialValue, int? index}) {
    final textC = TextEditingController(text: initialValue);
    Get.defaultDialog(
      title: initialValue == null ? "Tambah Alasan Baru" : "Edit Alasan",
      content: TextField(
        controller: textC,
        decoration: const InputDecoration(labelText: "Teks Alasan"),
        autofocus: true,
      ),
      onConfirm: () {
        final text = textC.text.trim();
        if (text.isNotEmpty) {
          if (index != null) {
            // Edit
            alasanList[index] = text;
          } else {
            // Tambah
            alasanList.add(text);
          }
          Get.back();
        }
      },
      textConfirm: "Simpan",
      textCancel: "Batal",
    );
  }
  
  void removeAlasan(int index) {
    alasanList.removeAt(index);
  }

  Future<void> saveChanges() async {
    isSaving.value = true;
    try {
      await _docRef.set({
        'alasanEditUangPangkal': alasanList.toList(),
      }, SetOptions(merge: true));

      Get.snackbar("Berhasil", "Daftar alasan berhasil diperbarui.",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}