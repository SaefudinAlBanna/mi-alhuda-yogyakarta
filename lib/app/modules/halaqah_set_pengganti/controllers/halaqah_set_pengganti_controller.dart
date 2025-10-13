// lib/app/modules/halaqah_set_pengganti/controllers/halaqah_set_pengganti_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';

class HalaqahSetPenggantiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State
  late HalaqahGroupModel group;
  final isLoading = true.obs;
  final isSaving = false.obs;
  
  // Form State
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<PegawaiSimpleModel> selectedPengganti = Rxn<PegawaiSimpleModel>();
  final RxList<PegawaiSimpleModel> daftarPengganti = <PegawaiSimpleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    group = Get.arguments as HalaqahGroupModel;
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
          .collection('halaqah_grup').doc(group.id);

      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      
      await groupRef.set({
        'penggantiHarian': {
          dateKey: {
            'idPengganti': selectedPengganti.value!.uid,
            'namaPengganti': selectedPengganti.value!.nama,
            'aliasPengganti': selectedPengganti.value!.alias,
          }
        }
      }, SetOptions(merge: true)); // Gunakan merge:true agar tidak menimpa data lain

      Get.back();
      Get.snackbar("Berhasil", "Pengganti untuk tanggal $dateKey telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) { Get.snackbar("Error", "Gagal menyimpan: $e"); } 
    finally { isSaving.value = false; }
  }
}