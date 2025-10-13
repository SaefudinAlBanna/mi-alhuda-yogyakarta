import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/pegawai_simple_model.dart';

class HalaqahUmmiSetPenggantiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late HalaqahGroupUmmiModel group;
  final isLoading = true.obs;
  final isSaving = false.obs;
  
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<PegawaiSimpleModel> selectedPengganti = Rxn<PegawaiSimpleModel>();
  final RxList<PegawaiSimpleModel> daftarPengganti = <PegawaiSimpleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    group = Get.arguments as HalaqahGroupUmmiModel;
    _fetchEligiblePengganti();
  }

  Future<void> _fetchEligiblePengganti() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
      final List<PegawaiSimpleModel> eligible = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? '';
        // [FIX] Menggunakan field 'tugas' sesuai koreksi Anda
        final tugas = List<String>.from(data['tugas'] ?? []); 

        // [FIX] Aturan baru: role adalah 'Pengampu' ATAU tugas berisi 'Pengampu'
        if (role == 'Pengampu' || tugas.contains('Pengampu')) {
          eligible.add(PegawaiSimpleModel.fromFirestore(doc));
        }
      }
      eligible.sort((a, b) => a.nama.compareTo(b.nama));
      daftarPengganti.assignAll(eligible);

    } catch (e) { Get.snackbar("Error", "Gagal memuat daftar pengganti: $e"); } 
    finally { isLoading.value = false; }
  }

  void pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
    }
  }

  Future<void> simpanPengganti() async {
    if (selectedPengganti.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih guru pengganti."); return;
    }
    isSaving.value = true;
    try {
      final groupRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('halaqah_grup_ummi').doc(group.id);
  
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      
      // --- [LOGIKA BARU] ---
      // Tentukan waktu kedaluwarsa otorisasi pengganti
      final tanggalTerpilih = selectedDate.value;
      final tanggalBerakhir = DateTime(tanggalTerpilih.year, tanggalTerpilih.month, tanggalTerpilih.day, 23, 59, 59);
  
      await groupRef.set({
        // Data lama untuk referensi UI
        'penggantiHarian': {
          dateKey: {
            'idPengganti': selectedPengganti.value!.uid,
            'namaPengganti': selectedPengganti.value!.nama,
            'aliasPengganti': selectedPengganti.value!.alias,
          }
        },
        // Data baru untuk otorisasi keamanan
        'pengampuHariIni': {
          'uid': selectedPengganti.value!.uid,
          'berlakuHingga': Timestamp.fromDate(tanggalBerakhir),
        }
      }, SetOptions(merge: true));
      // --- [AKHIR LOGIKA BARU] ---
  
      Get.back();
      Get.snackbar("Berhasil", "Pengganti untuk tanggal $dateKey telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
  
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan: $e"); } 
    finally { isSaving.value = false; }
  }
}