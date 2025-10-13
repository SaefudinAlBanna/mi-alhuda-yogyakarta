// lib/app/modules/manajemen_penawaran_buku/controllers/manajemen_penawaran_buku_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../models/buku_model.dart';
import '../../../routes/app_pages.dart';

class ManajemenPenawaranBukuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBukuDitawarkan() {
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('buku_ditawarkan')
        .orderBy('namaItem')
        .snapshots();
  }

  void goToCreateBuku() {
    Get.toNamed(Routes.CREATE_EDIT_BUKU);
  }

  void goToEditBuku(BukuModel buku) {
    Get.toNamed(Routes.CREATE_EDIT_BUKU, arguments: buku);
  }
  
  void goToManajemenPendaftaran() {
    Get.toNamed(Routes.MANAJEMEN_PENDAFTARAN_BUKU);
  }

  Future<void> deleteBuku(BukuModel buku) async {
    // Di masa depan, kita bisa menambahkan validasi apakah buku sudah dipilih siswa.
    // Untuk sekarang, konfirmasi sederhana sudah cukup.
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Yakin ingin menghapus '${buku.namaItem}' dari daftar penawaran?",
      textConfirm: "Ya, Hapus",
      onConfirm: () async {
        Get.back();
        try {
          await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
              .collection('buku_ditawarkan').doc(buku.id)
              .delete();
          Get.snackbar("Berhasil", "Item buku telah dihapus.");
        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus: $e");
        }
      },
    );
  }
}