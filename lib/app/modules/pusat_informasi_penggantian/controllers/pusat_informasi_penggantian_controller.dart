// lib/app/modules/pusat_informasi_penggantian/controllers/pusat_informasi_penggantian_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/info_penggantian_model.dart';

import '../../../controllers/dashboard_controller.dart';

class PusatInformasiPenggantianController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  final RxBool isLoadingInsidental = true.obs;
  final RxBool isLoadingRentang = true.obs;
  final RxList<InfoPenggantianModel> daftarInsidental = <InfoPenggantianModel>[].obs;
  final RxList<InfoPenggantianModel> daftarRentang = <InfoPenggantianModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    fetchPenggantianInsidental();
    fetchPenggantianRentang();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> fetchPenggantianInsidental() async {
    isLoadingInsidental.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('sesi_pengganti_kbm')
          .orderBy('tanggal', descending: true)
          .limit(50) // Batasi agar tidak terlalu banyak
          .get();
      
      final List<InfoPenggantianModel> result = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        result.add(InfoPenggantianModel(
          tipe: TipePenggantian.Insidental,
          tanggalMulai: DateTime.parse(data['tanggal']),
          namaGuruAsli: data['namaGuruAsli'] ?? 'N/A',
          namaGuruPengganti: data['namaGuruPengganti'] ?? 'N/A',
          detailSesi: "${data['namaMapel'] ?? 'Mapel'} - ${data['idKelas']} (Jam ke-${data['jamKe']})",
        ));
      }
      daftarInsidental.assignAll(result);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penggantian insidental: $e");
    } finally {
      isLoadingInsidental.value = false;
    }
  }
  
  Future<void> fetchPenggantianRentang() async {
    isLoadingRentang.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('penggantianAkademik')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      final List<InfoPenggantianModel> result = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        result.add(InfoPenggantianModel(
          tipe: TipePenggantian.RentangWaktu,
          tanggalMulai: (data['tanggalMulai'] as Timestamp).toDate(),
          tanggalSelesai: (data['tanggalSelesai'] as Timestamp).toDate(),
          namaGuruAsli: data['namaGuruAsli'] ?? 'N/A',
          namaGuruPengganti: data['namaGuruPengganti'] ?? 'N/A',
          detailSesi: "Semua jadwal mengajar",
        ));
      }
      daftarRentang.assignAll(result);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penggantian terencana: $e");
    } finally {
      isLoadingRentang.value = false;
    }
  }
}