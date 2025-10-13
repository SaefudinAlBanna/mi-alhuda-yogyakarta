import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart';

class PengaturanBobotNilaiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late DocumentReference<Map<String, dynamic>> _bobotRef;

  // State untuk UI
  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxBool isAuthorized = false.obs;

  // State untuk nilai bobot (menggunakan double untuk Slider)
  final RxDouble bobotTugasHarian = 20.0.obs;
  final RxDouble bobotUlanganHarian = 20.0.obs;
  final RxDouble bobotNilaiTambahan = 20.0.obs;
  final RxDouble bobotPts = 20.0.obs;
  final RxDouble bobotPas = 20.0.obs;

  // Computed property untuk menghitung total
  double get totalBobot =>
      bobotTugasHarian.value +
      bobotUlanganHarian.value +
      bobotNilaiTambahan.value +
      bobotPts.value +
      bobotPas.value;

  @override
  void onInit() {
    super.onInit();
    _checkAuthorization();
    if (isAuthorized.value) {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      _bobotRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('pengaturan').doc('bobot_nilai');
      _fetchBobotNilai();
    } else {
      isLoading.value = false;
    }
  }

  void _checkAuthorization() {
    // Gunakan logika yang sama dari DashboardController
    final dashboardC = Get.find<DashboardController>();
    isAuthorized.value = dashboardC.isPimpinan; 
  }

  Future<void> _fetchBobotNilai() async {
    isLoading.value = true;
    try {
      final doc = await _bobotRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        bobotTugasHarian.value = (data['bobotTugasHarian'] ?? 20).toDouble();
        bobotUlanganHarian.value = (data['bobotUlanganHarian'] ?? 20).toDouble();
        bobotNilaiTambahan.value = (data['bobotNilaiTambahan'] ?? 20).toDouble();
        bobotPts.value = (data['bobotPts'] ?? 20).toDouble();
        bobotPas.value = (data['bobotPas'] ?? 20).toDouble();
      } else {
        // Jika dokumen tidak ada, state default sudah 20, jadi tidak perlu aksi
        print("Dokumen bobot nilai belum ada, menggunakan default 20%.");
      }
    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal memuat data bobot nilai: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simpanBobot() async {
    if (totalBobot.round() != 100) {
      Get.snackbar("Validasi Gagal", "Total bobot harus tepat 100%.",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isSaving.value = true;
    try {
      final user = configC.infoUser;
      final dataToSave = {
        'bobotTugasHarian': bobotTugasHarian.value.toInt(),
        'bobotUlanganHarian': bobotUlanganHarian.value.toInt(),
        'bobotNilaiTambahan': bobotNilaiTambahan.value.toInt(),
        'bobotPts': bobotPts.value.toInt(),
        'bobotPas': bobotPas.value.toInt(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'updatedById': user['uid'],
        'updatedByNama': user['nama'],
        'updatedByAlias': user['alias'],
      };

      await _bobotRef.set(dataToSave);
      Get.back(); // Kembali ke halaman sebelumnya
      Get.snackbar("Berhasil", "Pengaturan bobot nilai telah disimpan.",
          backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: $e");
    } finally {
      isSaving.value = false;
    }
  }
}