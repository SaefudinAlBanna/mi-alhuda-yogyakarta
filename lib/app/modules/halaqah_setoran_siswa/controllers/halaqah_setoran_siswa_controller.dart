// lib/app/modules/halaqah_setoran_siswa/controllers/halaqah_setoran_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_setoran_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

import '../../halaqah_grading/controllers/halaqah_grading_controller.dart';

enum PageMode { BeriTugas, BeriNilai }

class HalaqahSetoranSiswaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  // State Halaman
  late SiswaSimpleModel siswa;
  late bool isPengganti;
  late Map<String, dynamic> pengampuUtama;
  final Rx<PageMode> pageMode = PageMode.BeriTugas.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  String? docIdToUpdate;
  final RxString catatanOrangTuaTerakhir = "".obs;

  // Form Controllers
  final tugasControllers = <String, TextEditingController>{};
  final nilaiControllers = <String, TextEditingController>{};
  final catatanPengampuC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    siswa = args['siswa'] as SiswaSimpleModel;
    isPengganti = args['isPengganti'] as bool? ?? false;
    pengampuUtama = args['pengampuUtama'] as Map<String, dynamic>;
    
    _initializeFormControllers();
    loadInitialData();
  }

  void _initializeFormControllers() {
    ['sabak', 'sabqi', 'manzil', 'tambahan'].forEach((key) {
      tugasControllers[key] = TextEditingController();
      nilaiControllers[key] = TextEditingController();
    });
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      final setoranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(siswa.uid).collection('halaqah_nilai');
      
      final snapshot = await setoranRef.orderBy('tanggalTugas', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        final lastSetoran = HalaqahSetoranModel.fromFirestore(snapshot.docs.first);
        if (lastSetoran.status == 'Tugas Diberikan') {
          pageMode.value = PageMode.BeriNilai;
          docIdToUpdate = lastSetoran.id;
          tugasControllers.forEach((key, controller) {
            controller.text = lastSetoran.tugas[key] ?? '';
          });
          catatanOrangTuaTerakhir.value = lastSetoran.catatanOrangTua;
        }
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat data: $e"); } 
    finally { isLoading.value = false; }
  }
  
  Future<void> saveData() async {
    isSaving.value = true;
    try {
      final tugasData = {
        'sabak': tugasControllers['sabak']!.text.trim(),
        'sabqi': tugasControllers['sabqi']!.text.trim(),
        'manzil': tugasControllers['manzil']!.text.trim(),
        'tambahan': tugasControllers['tambahan']!.text.trim(),
      };
      final nilaiData = {
        'sabak': nilaiControllers['sabak']!.text.trim(),
        'sabqi': nilaiControllers['sabqi']!.text.trim(),
        'manzil': nilaiControllers['manzil']!.text.trim(),
        'tambahan': nilaiControllers['tambahan']!.text.trim(),
      };

      if (!_validateInputs(tugasData, nilaiData)) {
        isSaving.value = false; return;
      }
      
      final WriteBatch batch = _firestore.batch();
      final penilaiId = authC.auth.currentUser!.uid;
      final penilaiNama = configC.infoUser['nama'];
      final grupId = Get.find<HalaqahGradingController>().group.id; // Ambil ID Grup
      
      if (pageMode.value == PageMode.BeriTugas) {
        final newDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid).collection('halaqah_nilai').doc();
        batch.set(newDocRef, {
          'tanggalTugas': FieldValue.serverTimestamp(),
          'status': 'Tugas Diberikan',
          'tugas': tugasData,
          'nilai': {},
          'catatanPengampu': '', 'catatanOrangTua': '',
          'idPengampu': pengampuUtama['id'],
          'namaPengampu': pengampuUtama['nama'],
          'tahunAjaran': configC.tahunAjaranAktif.value,
          'semester': configC.semesterAktif.value,
          'idGrup': grupId, // <-- PENTING: Menyimpan ID grup
        });
        
        final notifIsi = _buildNotificationMessage(tugasData, "Tugas baru");
        _addNotificationToBatch(batch, siswa.uid, "Tugas Halaqah Baru", notifIsi);
      } else {
        if (docIdToUpdate == null) throw Exception("ID Dokumen untuk update tidak ditemukan!");
        final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid).collection('halaqah_nilai').doc(docIdToUpdate);
        batch.update(docRef, {
          'tanggalDinilai': FieldValue.serverTimestamp(),
          'status': 'Sudah Dinilai',
          'nilai': nilaiData,
          'catatanPengampu': catatanPengampuC.text.trim(),
          'tugas': tugasData,
          'idPenilai': penilaiId,
          'namaPenilai': penilaiNama,
          'isDinilaiPengganti': isPengganti,
        });
        
        final notifIsi = _buildNotificationMessage(nilaiData, "Nilai baru");
        _addNotificationToBatch(batch, siswa.uid, "Nilai Halaqah", notifIsi);
      }
      
      await batch.commit();
      
      Get.defaultDialog(
        title: "Berhasil!", middleText: "Penilaian untuk ${siswa.nama} telah berhasil disimpan.",
        textConfirm: "OK", onConfirm: () { Get.back(); Get.back(); },
      );
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan: ${e.toString()}"); } 
    finally { isSaving.value = false; }
  }

  bool _validateInputs(Map<String, String> tugasData, Map<String, String> nilaiData) {
    final List<String> errors = [];
    final kategori = ['sabak', 'sabqi', 'manzil', 'tambahan'];

    if (pageMode.value == PageMode.BeriNilai) {
      bool isAnyNilaiFilled = false;
      for (var key in kategori) {
        if (tugasData[key]!.isNotEmpty && nilaiData[key]!.isEmpty) {
          errors.add("-> Nilai untuk tugas ${key.capitalizeFirst} masih kosong.");
        }
        if (tugasData[key]!.isEmpty && nilaiData[key]!.isNotEmpty) {
          errors.add("-> Tidak bisa memberi nilai ${key.capitalizeFirst} karena tidak ada tugasnya.");
        }
        if (nilaiData[key]!.isNotEmpty) isAnyNilaiFilled = true;
      }
      if (!isAnyNilaiFilled) errors.add("-> Harap isi minimal satu nilai.");
    } else { // Mode BeriTugas
      if (tugasData.values.every((val) => val.isEmpty)) {
        errors.add("-> Harap isi minimal satu tugas setoran.");
      }
    }

    if (errors.isNotEmpty) {
      Get.snackbar("Validasi Gagal", errors.join("\n"),
          backgroundColor: Colors.red, colorText: Colors.white,
          duration: const Duration(seconds: 5), snackPosition: SnackPosition.TOP);
      return false;
    }
    return true;
  }

  void _addNotificationToBatch(WriteBatch batch, String siswaUid, String judul, String isi) {
    final siswaNotifRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(siswaUid).collection('notifikasi').doc();
    final metaRef = siswaNotifRef.parent.parent!.collection('notifikasi_meta').doc('metadata');

    batch.set(siswaNotifRef, {
      'judul': judul, 
      'isi': isi, 
      'tipe': 'HALAQAH',
      'tanggal': FieldValue.serverTimestamp(), 
      'isRead': false,
    });
    batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  String _buildNotificationMessage(Map<String, String> data, String prefix) {
    List<String> parts = [];
    data.forEach((key, value) {
      if (value.isNotEmpty) {
        parts.add("${key.capitalizeFirst}: ${value}");
      }
    });
    return "$prefix: ${parts.join(', ')}.";
  }

  @override
  void onClose() {
    tugasControllers.forEach((_, controller) => controller.dispose());
    nilaiControllers.forEach((_, controller) => controller.dispose());
    catatanPengampuC.dispose();
    super.onClose();
  }
}