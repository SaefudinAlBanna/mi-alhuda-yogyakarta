import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart';

class JadwalPelajaranController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  late TabController tabController;

  final isLoading = true.obs;
  final isLoadingJadwal = false.obs;

  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();
  
  // Struktur data untuk menampung jadwal per hari
  final RxMap<String, List<Map<String, dynamic>>> jadwalPelajaran = <String, List<Map<String, dynamic>>>{}.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: daftarHari.length, vsync: this);
    _initializeData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchDaftarKelas();
    // Jika ada kelas, otomatis pilih dan muat jadwal kelas pertama
    if (daftarKelas.isNotEmpty) {
      await onKelasChanged(daftarKelas.first['id']);
    }
    isLoading.value = false;
  }

  Future<void> _fetchDaftarKelas() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return;

    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('kelas')
          .where('tahunAjaran', isEqualTo: tahunAjaran)
          .orderBy('namaKelas')
          .get();
      daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namaKelas'] ?? doc.id}).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas: $e");
    }
  }

  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId == selectedKelasId.value) return;
    
    selectedKelasId.value = kelasId;
    isLoadingJadwal.value = true;
    jadwalPelajaran.clear(); // Kosongkan jadwal lama

    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final docSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('jadwalkelas').doc(kelasId)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data()!;
        for (var hari in daftarHari) {
          // Ambil data untuk hari ini, urutkan berdasarkan jam
          var pelajaranHari = List<Map<String, dynamic>>.from(dataJadwal[hari] ?? []);
          pelajaranHari.sort((a, b) => (a['jam'] as String).compareTo(b['jam'] as String));
          jadwalPelajaran[hari] = pelajaranHari;
        }
      } else {
        // Jika dokumen tidak ada, pastikan semua hari diisi list kosong
        for (var hari in daftarHari) {
          jadwalPelajaran[hari] = [];
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}');
    } finally {
      isLoadingJadwal.value = false;
    }
  }
}