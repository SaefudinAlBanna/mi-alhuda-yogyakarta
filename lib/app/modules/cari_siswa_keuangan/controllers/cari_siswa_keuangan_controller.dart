// lib/app/modules/cari_siswa_keuangan/controllers/cari_siswa_keuangan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../routes/app_pages.dart';

class CariSiswaKeuanganController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  
  final RxList<SiswaKeuanganModel> _daftarSiswaMaster = <SiswaKeuanganModel>[].obs;
  final RxList<SiswaKeuanganModel> daftarSiswaTampil = <SiswaKeuanganModel>[].obs;
  
  final searchC = TextEditingController();
  final RxList<String> daftarKelasFilter = <String>['Semua Kelas'].obs;
  final RxString kelasTerpilih = 'Semua Kelas'.obs;

  // [BARU] Properti untuk menangani mode halaman
  final RxString mode = 'lihat'.obs; // 'lihat' atau 'pilih'
  final RxList<String> excludeUIDs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // [BARU] Cek argumen saat inisialisasi
    if (Get.arguments is Map) {
      final args = Get.arguments as Map<String, dynamic>;
      mode.value = args['mode'] ?? 'lihat';
      if (args['excludeUIDs'] != null) {
        excludeUIDs.assignAll(List<String>.from(args['excludeUIDs']));
      }
    }

    _fetchInitialData();
    searchC.addListener(() => _filterDataTampil());
    ever(kelasTerpilih, (_) => _filterDataTampil());
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').where('statusSiswa', isEqualTo: 'Aktif').orderBy('namaLengkap').get(),
        _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('kelas').where('tahunAjaran', isEqualTo: configC.tahunAjaranAktif.value).get(),
      ]);

      final siswaSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final kelasSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

      var siswaList = siswaSnap.docs.map((d) => SiswaKeuanganModel.fromFirestore(d)).toList();
      
      // [BARU] Filter siswa yang dikecualikan
      if (excludeUIDs.isNotEmpty) {
        siswaList.removeWhere((siswa) => excludeUIDs.contains(siswa.uid));
      }

      _daftarSiswaMaster.assignAll(siswaList);
      daftarSiswaTampil.assignAll(siswaList);
      
      final kelasSet = kelasSnap.docs.map((d) => d.data()['namaKelas'] as String).toSet();
      final kelasList = kelasSet.toList()..sort();
      daftarKelasFilter.addAll(kelasList);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void _filterDataTampil() {
    List<SiswaKeuanganModel> hasilFilter = _daftarSiswaMaster;

    if (kelasTerpilih.value != 'Semua Kelas') {
      hasilFilter = hasilFilter.where((siswa) {
        return siswa.kelasId != null && siswa.kelasId!.startsWith(kelasTerpilih.value);
      }).toList();
    }

    final query = searchC.text.toLowerCase();
    if (query.isNotEmpty) {
      hasilFilter = hasilFilter.where((siswa) {
        return siswa.namaLengkap.toLowerCase().contains(query);
      }).toList();
    }

    daftarSiswaTampil.assignAll(hasilFilter);
  }

  // [FUNGSI DIPERBARUI] Menangani aksi saat item siswa di-tap
  void handleSiswaTap(SiswaKeuanganModel siswa) {
    if (mode.value == 'pilih') {
      // Jika dalam mode pilih, kembalikan data siswa dan tutup halaman
      Get.back(result: siswa);
    } else {
      // Jika dalam mode lihat, navigasi ke halaman detail
      Get.toNamed(Routes.DETAIL_KEUANGAN_SISWA, arguments: siswa);
    }
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}