// lib/app/modules/laporan_keuangan/controllers/laporan_keuangan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/rekap_jenis_tagihan_model.dart';
import '../../../models/tagihan_model.dart';
import '../../../routes/app_pages.dart';

class LaporanKeuanganController extends GetxController with GetSingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController;
  final isLoading = true.obs;
  String get taAktif => configC.tahunAjaranAktif.value;

  final List<TagihanModel> _semuaTagihanTahunan = [];
  final List<TagihanModel> _semuaTagihanUangPangkal = [];

  final RxInt totalTagihanTahunan = 0.obs;
  final RxInt totalTerbayarTahunan = 0.obs;
  final RxList<RekapJenisTagihan> rekapPerJenisTahunan = <RekapJenisTagihan>[].obs;
  
  final RxInt totalTagihanUP = 0.obs;
  final RxInt totalTerbayarUP = 0.obs;
  final RxList<TagihanModel> rincianUangPangkal = <TagihanModel>[].obs;

  final RxList<String> daftarKelasFilter = <String>['Semua Kelas'].obs;
  final RxString kelasTerpilih = 'Semua Kelas'.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    ever(kelasTerpilih, _filterDataTahunanForView);
    _loadAllFinancialData();
  }

  Future<void> _loadAllFinancialData() async {
    isLoading.value = true;
    // [PERBAIKAN KUNCI] Tambahkan guard clause
    if (taAktif.isEmpty || taAktif.contains("TIDAK")) {
      isLoading.value = false;
      return;
    }
    try {
      final tagihanTahunanSnap = await _firestore.collectionGroup('tagihan')
          .where('idTahunAjaran', isEqualTo: taAktif)
          .get();
      _semuaTagihanTahunan.assignAll(tagihanTahunanSnap.docs.map((d) => TagihanModel.fromFirestore(d)).toList());
      
      final uangPangkalSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('keuangan_sekolah').doc('tagihan_uang_pangkal')
          .collection('tagihan').get();
      _semuaTagihanUangPangkal.assignAll(uangPangkalSnap.docs.map((d) => TagihanModel.fromFirestore(d)).toList());
  
      _generateKelasFilter();
      _filterDataTahunanForView('Semua Kelas');
      _prosesDataUangPangkal();
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data laporan: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void _generateKelasFilter() {
    final Set<String> kelasSet = {};
    for (var tagihan in _semuaTagihanTahunan) {
      final kelasIdLengkap = tagihan.kelasSaatDitagih;
      if (kelasIdLengkap != null && kelasIdLengkap.isNotEmpty) {
        final namaKelasPendek = kelasIdLengkap.split('-').first;
        kelasSet.add(namaKelasPendek);
      }
    }
    final kelasList = kelasSet.toList()..sort();
    daftarKelasFilter.assignAll(['Semua Kelas', ...kelasList]);
  }

  void _filterDataTahunanForView(String kelas) {
    List<TagihanModel> filteredList;

    if (kelas == 'Semua Kelas') {
      filteredList = _semuaTagihanTahunan;
    } else {
      filteredList = _semuaTagihanTahunan.where((t) {
        final kelasIdLengkap = t.kelasSaatDitagih;
        return kelasIdLengkap != null && kelasIdLengkap.startsWith(kelas);
      }).toList();
    }
    
    final Map<String, RekapJenisTagihan> rekapMap = {};
    int totalTagihan = 0;
    int totalTerbayar = 0;
    final now = DateTime.now();

    for (var tagihan in filteredList) {
      // [PERBAIKAN DIMULAI DI SINI]
      bool isBillDueAndCountable = true; // Anggap semua tagihan valid secara default

      // Terapkan aturan khusus HANYA untuk SPP
      if (tagihan.jenisPembayaran == 'SPP') {
        // Jika SPP belum jatuh tempo, jangan hitung
        if (tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isAfter(now)) {
          isBillDueAndCountable = false;
        }
      }
      
      // Hanya proses tagihan yang lolos filter (semua non-SPP dan SPP yang sudah jatuh tempo)
      if (isBillDueAndCountable) {
        if (rekapMap[tagihan.jenisPembayaran] == null) {
          rekapMap[tagihan.jenisPembayaran] = RekapJenisTagihan(jenis: tagihan.jenisPembayaran);
        }
        rekapMap[tagihan.jenisPembayaran]!.totalTagihan += tagihan.jumlahTagihan;
        rekapMap[tagihan.jenisPembayaran]!.totalTerbayar += tagihan.jumlahTerbayar;
        totalTagihan += tagihan.jumlahTagihan;
        totalTerbayar += tagihan.jumlahTerbayar;
      }
      // [PERBAIKAN SELESAI DI SINI]
    }
    
    totalTagihanTahunan.value = totalTagihan;
    totalTerbayarTahunan.value = totalTerbayar;
    rekapPerJenisTahunan.value = rekapMap.values.toList()..sort((a, b) => a.jenis.compareTo(b.jenis));
  }
  
  void _prosesDataUangPangkal() {
    int totalTagihan = 0;
    int totalTerbayar = 0;
    for (var tagihan in _semuaTagihanUangPangkal) {
      totalTagihan += tagihan.jumlahTagihan;
      totalTerbayar += tagihan.jumlahTerbayar;
    }
    totalTagihanUP.value = totalTagihan;
    totalTerbayarUP.value = totalTerbayar;
    rincianUangPangkal.value = _semuaTagihanUangPangkal;
  }
  
  void goToRincianTunggakan(RekapJenisTagihan rekap) {
    if (rekap.sisa <= 0) {
      Get.snackbar("Informasi", "Tidak ada tunggakan untuk ${rekap.jenis}.",
        backgroundColor: Colors.green, colorText: Colors.white);
      return;
    }
    Get.toNamed(Routes.RINCIAN_TUNGGAKAN, arguments: {
      'jenisPembayaran': rekap.jenis,
      'filterKelas': kelasTerpilih.value,
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}