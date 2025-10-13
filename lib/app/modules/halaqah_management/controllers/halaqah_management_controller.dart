// lib/app/modules/halaqah_management/controllers/halaqah_management_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

import '../../../models/halaqah_group_model.dart';

class HalaqahManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // Stream untuk mengambil daftar grup halaqah
  Stream<QuerySnapshot<Map<String, dynamic>>> streamHalaqahGroups() {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final semester = configC.semesterAktif.value;

    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      return const Stream.empty();
    }

    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup')
        .where('semester', isEqualTo: semester)
        .orderBy('namaGrup')
        .snapshots();
  }

  // Navigasi ke halaman buat/edit grup
  // Kita kirim 'null' untuk menandakan ini adalah pembuatan grup BARU
  void goToCreateGroup() {
    Get.toNamed(Routes.CREATE_EDIT_HALAQAH_GROUP, arguments: null);
  }

  // Fungsi ini akan kita gunakan nanti saat mengedit grup yang sudah ada
  void goToEditGroup(HalaqahGroupModel group) {
    Get.toNamed(Routes.CREATE_EDIT_HALAQAH_GROUP, arguments: group);
  }

  void goToSetPengganti(HalaqahGroupModel group) {
    Get.toNamed(Routes.HALAQAH_SET_PENGGANTI, arguments: group);
  }

  Future<void> deleteGroup(HalaqahGroupModel group) async {
    try {
      final groupRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('halaqah_grup').doc(group.id);

      // LANGKAH 1: Validasi apakah grup masih memiliki anggota
      final anggotaSnapshot = await groupRef.collection('anggota').limit(1).get();
      if (anggotaSnapshot.docs.isNotEmpty) {
        Get.snackbar(
          "Gagal Menghapus",
          "Grup tidak dapat dihapus karena masih memiliki anggota siswa.",
          backgroundColor: Colors.red, colorText: Colors.white
        );
        return;
      }

      // LANGKAH 2: Tampilkan dialog konfirmasi
      Get.defaultDialog(
        title: "Konfirmasi Hapus",
        middleText: "Apakah Anda yakin ingin menghapus grup '${group.namaGrup}'?",
        textConfirm: "Ya, Hapus",
        textCancel: "Batal",
        confirmTextColor: Colors.white,
        onConfirm: () async {
          Get.back(); // Tutup dialog
          
          final WriteBatch batch = _firestore.batch();
          
          // Aksi 1: Hapus dokumen grup itu sendiri
          batch.delete(groupRef);

          // Aksi 2 (Denormalisasi): Hapus ID grup dari data pengampu
          final pengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(group.idPengampu);
          final keySemester = "${configC.tahunAjaranAktif.value}_${configC.semesterAktif.value}";
          batch.update(pengampuRef, {
            'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([group.id])
          });

          await batch.commit();
          Get.snackbar("Berhasil", "Grup halaqah telah dihapus.");
        },
      );
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    }
  }
}