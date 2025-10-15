// lib/app/modules/perangkat_ajar/controllers/perangkat_ajar_controller.dart (FINAL & LENGKAP)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/atp_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/modul_ajar_model.dart';
import 'package:uuid/uuid.dart';

class PerangkatAjarController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashboardC = Get.find<DashboardController>();
  var uuid = const Uuid();

  // State
  final RxBool isLoading = true.obs;
  final RxList<String> daftarTahunAjaran = <String>[].obs;
  final RxString tahunAjaranFilter = ''.obs;

  late final CollectionReference<Map<String, dynamic>> _atpRef;
  late final CollectionReference<Map<String, dynamic>> _modulAjarRef;

  @override
  void onInit() {
    super.onInit();
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    _atpRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('atp');
    _modulAjarRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('modulAjar');
    
    tahunAjaranFilter.value = tahunAjaran;
    _fetchTahunAjaranList();
    isLoading.value = false;
  }

  Future<void> _fetchTahunAjaranList() async {
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').orderBy('idtahunajaran', descending: true).get();
      daftarTahunAjaran.value = snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar tahun ajaran.");
    }
  }

  void gantiTahunAjaranFilter(String? tahunBaruId) {
    if (tahunBaruId != null && tahunAjaranFilter.value != tahunBaruId) {
      tahunAjaranFilter.value = tahunBaruId;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAtp() {
    Query<Map<String, dynamic>> query = _atpRef.where('idTahunAjaran', isEqualTo: tahunAjaranFilter.value);
    if (!dashboardC.isPimpinan) {
      query = query.where('idPenyusun', isEqualTo: configC.infoUser['uid']);
    }
    return query.orderBy('lastModified', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamModulAjar() {
    Query<Map<String, dynamic>> query = _modulAjarRef.where('idTahunAjaran', isEqualTo: tahunAjaranFilter.value);
    if (!dashboardC.isPimpinan) {
      query = query.where('idPenyusun', isEqualTo: configC.infoUser['uid']);
    }
    return query.orderBy('lastModified', descending: true).snapshots();
  }

  // --- Fungsi CRUD ---
  Future<void> createAtp(AtpModel atp) async {
    try {
      final newId = uuid.v4();
      atp.idAtp = newId;
      await _atpRef.doc(newId).set(atp.toJson());
      Get.back();
      Get.snackbar('Berhasil', 'ATP baru berhasil dibuat.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat ATP: $e');
    }
  }

  Future<void> updateAtp(AtpModel atp) async {
    try {
      await _atpRef.doc(atp.idAtp).update(atp.toJson());
      Get.back();
      Get.snackbar('Berhasil', 'ATP berhasil diperbarui.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui ATP: $e');
    }
  }

  void deleteAtp(String idAtp) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus", middleText: "Anda yakin ingin menghapus ATP ini?",
      textConfirm: "Ya, Hapus", textCancel: "Batal", confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          await _atpRef.doc(idAtp).delete();
          Get.snackbar('Berhasil', 'ATP berhasil dihapus.');
        } catch (e) { Get.snackbar('Error', 'Gagal menghapus ATP: $e'); }
      },
    );
  }

  Future<void> createModulAjar(ModulAjarModel modul) async {
    try {
      final newId = uuid.v4();
      modul.idModul = newId;
      await _modulAjarRef.doc(newId).set(modul.toJson());
      Get.back(); // Kembali dari halaman form
      Get.snackbar('Berhasil', 'Modul Ajar baru berhasil dibuat.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat Modul Ajar: $e');
    }
  }

  Future<void> updateModulAjar(ModulAjarModel modul) async {
    try {
      await _modulAjarRef.doc(modul.idModul).update(modul.toJson());
      Get.back(); // Kembali dari halaman form
      Get.snackbar('Berhasil', 'Modul Ajar berhasil diperbarui.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui Modul Ajar: $e');
    }
  }

  void deleteModulAjar(String idModul) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus Modul Ajar ini?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          await _modulAjarRef.doc(idModul).delete();
          Get.snackbar('Berhasil', 'Modul Ajar berhasil dihapus.');
        } catch (e) {
          Get.snackbar('Error', 'Gagal menghapus Modul Ajar: $e');
        }
      },
    );
  }

}