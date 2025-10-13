import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';

class AturPenggantianRentangController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  final RxList<PegawaiSimpleModel> daftarGuru = <PegawaiSimpleModel>[].obs;
  final Rxn<PegawaiSimpleModel> guruAsli = Rxn<PegawaiSimpleModel>();
  final Rxn<PegawaiSimpleModel> guruPengganti = Rxn<PegawaiSimpleModel>();
  
  final Rx<DateTime> tanggalMulai = DateTime.now().obs;
  final Rx<DateTime> tanggalSelesai = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _fetchDaftarGuru();
  }

  Future<void> _fetchDaftarGuru() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
      daftarGuru.assignAll(snapshot.docs.map((d) => PegawaiSimpleModel.fromFirestore(d)).toList());
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar guru: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void pickDate(BuildContext context, {required bool isMulai}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? tanggalMulai.value : tanggalSelesai.value,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (isMulai) {
        tanggalMulai.value = picked;
        // Otomatis set tanggal selesai jika tanggal mulai melewatinya
        if (picked.isAfter(tanggalSelesai.value)) {
          tanggalSelesai.value = picked;
        }
      } else {
        tanggalSelesai.value = picked;
      }
    }
  }

  Future<void> simpanPenugasan() async {
    // Validasi
    if (guruAsli.value == null || guruPengganti.value == null) {
      Get.snackbar("Validasi Gagal", "Silakan pilih guru asli dan guru pengganti."); return;
    }
    if (guruAsli.value!.uid == guruPengganti.value!.uid) {
      Get.snackbar("Validasi Gagal", "Guru asli dan guru pengganti tidak boleh orang yang sama."); return;
    }
    if (tanggalSelesai.value.isBefore(tanggalMulai.value)) {
      Get.snackbar("Validasi Gagal", "Tanggal selesai tidak boleh sebelum tanggal mulai."); return;
    }

      isSaving.value = true;
    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final idGuruAsli = guruAsli.value!.uid;
  
      // --- [LANGKAH TAMBAHAN] Ambil jadwal guru asli ---
      final jadwalGuruAsliSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').doc(idGuruAsli)
          .collection('jadwal_mengajar').doc(tahunAjaran)
          .collection('mapel_diampu')
          .get();
      
      // Ubah QuerySnapshot menjadi List<Map>
      final List<Map<String, dynamic>> jadwalUntukDisalin = jadwalGuruAsliSnap.docs
          .map((doc) => doc.data())
          .toList();
  
      // Simpan data mandat beserta salinan jadwalnya
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('penggantianAkademik').add({
          'idGuruAsli': idGuruAsli,
          'namaGuruAsli': guruAsli.value!.displayName,
          'idGuruPengganti': guruPengganti.value!.uid,
          'namaGuruPengganti': guruPengganti.value!.displayName,
          'tanggalMulai': Timestamp.fromDate(tanggalMulai.value),
          'tanggalSelesai': Timestamp.fromDate(tanggalSelesai.value),
          'status': 'aktif',
          'dibuatOleh': Get.find<ConfigController>().infoUser['uid'],
          'timestamp': FieldValue.serverTimestamp(),
          // --- [SIMPAN DATA DENORMALISASI] ---
          'jadwalYangDigantikan': jadwalUntukDisalin,
        });
      
      Get.snackbar("Berhasil", "Penugasan guru pengganti berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
      guruAsli.value = null;
      guruPengganti.value = null;
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}