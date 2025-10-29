// lib/app/modules/manajemen_anggaran/controllers/manajemen_anggaran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../widgets/number_input_formatter.dart'; // Pastikan import ini benar

class ManajemenAnggaranController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // --- State UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;

  // --- State Data ---
  late String tahunAnggaran;
  final RxList<String> daftarKategori = <String>[].obs;
  final Map<String, TextEditingController> anggaranControllers = {};

  @override
  void onInit() {
    super.onInit();
    tahunAnggaran = Get.arguments as String;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      // 1. Ambil daftar kategori yang tersedia
      final configDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_keuangan').get();
      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        final kategoriFromDb = (data['daftarKategoriPengeluaran'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        daftarKategori.assignAll(kategoriFromDb);
      }

      // 2. Ambil data anggaran yang sudah ada untuk tahun ini
      final budgetDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunAnggaran').doc(tahunAnggaran)
          .collection('anggaran').doc('data_anggaran').get();
      
      Map<String, dynamic> existingBudgets = {};
      if (budgetDoc.exists) {
        existingBudgets = budgetDoc.data()?['anggaranPengeluaran'] ?? {};
      }

      // 3. Buat TextEditingController untuk setiap kategori
      for (var kategori in daftarKategori) {
        final existingValue = existingBudgets[kategori]?.toString() ?? '';
        anggaranControllers[kategori] = TextEditingController(text: existingValue);
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simpanAnggaran() async {
    isSaving.value = true;
    try {
      final Map<String, int> dataToSave = {};
      anggaranControllers.forEach((kategori, controller) {
        final amount = int.tryParse(controller.text.replaceAll('.', '')) ?? 0;
        dataToSave[kategori] = amount;
      });

      await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunAnggaran').doc(tahunAnggaran)
          .collection('anggaran').doc('data_anggaran').set({
            'anggaranPengeluaran': dataToSave,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Get.back(); // Kembali ke halaman laporan
      Get.snackbar("Berhasil", "Anggaran untuk tahun $tahunAnggaran telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan anggaran: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    // Penting untuk membersihkan semua controller
    for (var controller in anggaranControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }
}