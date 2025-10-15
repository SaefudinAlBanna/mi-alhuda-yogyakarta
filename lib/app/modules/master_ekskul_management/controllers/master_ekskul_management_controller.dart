// lib/app/modules/master_ekskul_management/controllers/master_ekskul_management_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/ekskul_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';

import '../../../controllers/dashboard_controller.dart';

class MasterEkskulManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  Stream<QuerySnapshot<Map<String, dynamic>>> streamEkskul() {
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('ekskul_ditawarkan')
        .where('tahunAjaran', isEqualTo: configC.tahunAjaranAktif.value)
        .where('semester', isEqualTo: configC.semesterAktif.value)
        .orderBy('namaEkskul')
        .snapshots();
  }
  
  // --- [BARU] Fungsi navigasi ke halaman Create ---
  void goToCreateEkskul() {
    Get.toNamed(Routes.CREATE_EDIT_EKSKUL, arguments: null);
  }

  // --- [BARU] Fungsi navigasi ke halaman Edit ---
  void goToEditEkskul(EkskulModel ekskul) {
    Get.toNamed(Routes.CREATE_EDIT_EKSKUL, arguments: ekskul);
  }
  
  // --- [BARU] Fungsi untuk hapus ekskul ---
  Future<void> deleteEkskul(EkskulModel ekskul) async {
    // TODO: Tambahkan validasi, apakah ekskul ini sudah ada pendaftarnya?
    // Untuk sekarang, kita buat dialog konfirmasi sederhana.

    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Apakah Anda yakin ingin menghapus ekskul '${ekskul.namaEkskul}'?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); // Tutup dialog
        try {
          await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('ekskul_ditawarkan').doc(ekskul.id)
              .delete();
          Get.snackbar("Berhasil", "Ekstrakurikuler telah dihapus.");
        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus: $e");
        }
      },
    );
  }
}