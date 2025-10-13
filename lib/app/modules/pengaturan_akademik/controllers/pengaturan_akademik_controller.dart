import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../routes/app_pages.dart';

class PengaturanAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxBool isAuthorized = false.obs;

  final Rxn<DateTime> tanggalMulaiSemester2 = Rxn<DateTime>();
  final Rxn<DateTime> tanggalMulaiTahunAjaranBaru = Rxn<DateTime>();

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;
  String get semesterAktif => configC.semesterAktif.value;

  @override
  void onInit() {
    super.onInit();
    _checkAuthorization();
    if (isAuthorized.value) {
      _fetchKonfigurasiTanggal();
    } else {
      isLoading.value = false;
    }
  }

  void _checkAuthorization() {
    final dashboardC = Get.find<DashboardController>();
    isAuthorized.value = dashboardC.isPimpinan;
  }

  Future<void> _fetchKonfigurasiTanggal() async {
    isLoading.value = true;
    try {
      final doc = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_akademik').get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        tanggalMulaiSemester2.value = (data['tanggalMulaiSemester2'] as Timestamp?)?.toDate();
        tanggalMulaiTahunAjaranBaru.value = (data['tanggalMulaiTahunAjaranBaru'] as Timestamp?)?.toDate();
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat konfigurasi tanggal akademik: $e");
      print("[PengaturanAkademikController] Error fetching config dates: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void prosesLanjutkanKeSemesterBerikutnya() {
    if (tanggalMulaiSemester2.value != null && DateTime.now().isBefore(tanggalMulaiSemester2.value!)) {
      Get.snackbar("Belum Waktunya", "Pergantian semester baru bisa dilakukan setelah tanggal yang ditentukan.");
      return;
    }

    final RxString konfirmasiText = ''.obs; // [PERBAIKAN] Gunakan RxString untuk reaktivitas
    Get.defaultDialog(
      title: "Konfirmasi Lanjutkan Semester",
      barrierDismissible: false,
      content: SizedBox( // [PERBAIKAN] Tambahkan SizedBox untuk membatasi tinggi content
        width: Get.width * 0.8, // Sesuaikan lebar
        height: Get.height * 0.25, // Sesuaikan tinggi
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten di kolom
            children: [
              const Text("Anda akan mengubah semester aktif menjadi Semester 2.\n\nSemua data baru akan tercatat di semester 2. Aksi ini tidak dapat dibatalkan.\n\nKetik 'LANJUTKAN' untuk konfirmasi.", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => konfirmasiText.value = value, // [PERBAIKAN] Perbarui RxString
                decoration: const InputDecoration(hintText: "Ketik di sini...", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: (konfirmasiText.value == 'LANJUTKAN' && !isSaving.value) // [PERBAIKAN] Reaktif dengan RxString
            ? _updateSemester
            : null,
        child: isSaving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Konfirmasi"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> _updateSemester() async {
    isSaving.value = true;
    try {
      final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif);
      
      await ref.update({'semesterAktif': '2'});
      
      Get.back();
      Get.snackbar("Berhasil", "Semester aktif telah diubah menjadi Semester 2.",
          backgroundColor: Colors.green, colorText: Colors.white);
      
      await configC.forceSyncProfile();

    } catch (e) {
      Get.snackbar("Error", "Gagal mengubah semester: $e");
      print("[PengaturanAkademikController] Error updating semester: $e");
    } finally {
      isSaving.value = false;
    }
  }

  void goToProsesKenaikanKelas() {
    Get.defaultDialog(
      title: "Peringatan Awal",
      middleText: "Anda akan memasuki proses akhir tahun ajaran. Pastikan semua nilai dan data akademik siswa sudah final sebelum melanjutkan. Setelah proses ini, status tahun ajaran lama akan DITUTUP.",
      textConfirm: "Saya Mengerti, Lanjutkan",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.toNamed(Routes.PROSES_KENAIKAN_KELAS),
    );
  }

  Future<void> simpanKonfigurasiTanggal({DateTime? tglSem2, DateTime? tglTAbaru}) async {
    isSaving.value = true;
    try {
      final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_akademik');
      
      await docRef.set({
        'tanggalMulaiSemester2': tglSem2 != null ? Timestamp.fromDate(tglSem2) : FieldValue.delete(),
        'tanggalMulaiTahunAjaranBaru': tglTAbaru != null ? Timestamp.fromDate(tglTAbaru) : FieldValue.delete(),
      }, SetOptions(merge: true));

      await _fetchKonfigurasiTanggal();
      Get.snackbar("Berhasil", "Konfigurasi tanggal berhasil diperbarui.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan konfigurasi tanggal: $e");
      print("[PengaturanAkademikController] Error saving config dates: $e");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}