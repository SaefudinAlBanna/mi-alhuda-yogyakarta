// lib/app/modules/financial_dashboard_pimpinan/controllers/financial_dashboard_pimpinan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/komite_log_transaksi_model.dart';
import '../../../routes/app_pages.dart';

class FinancialDashboardPimpinanController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  String get taAktif => configC.tahunAjaranAktif.value;

  // --- State Keuangan Sekolah ---
  final RxInt totalTagihanSekolah = 0.obs;
  final RxInt totalTerbayarSekolah = 0.obs;
  int get totalTunggakanSekolah => totalTagihanSekolah.value - totalTerbayarSekolah.value;

  // --- State Keuangan Komite (Sudah Disempurnakan) ---
  final RxInt saldoKasKomite = 0.obs;
  final RxList<KomiteLogTransaksiModel> logTransaksiKomiteTerbaru = <KomiteLogTransaksiModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Gunakan listener agar data selalu update jika tahun ajaran berubah
    ever(configC.tahunAjaranAktif, (_) => fetchFinancialData());
    fetchFinancialData();
  }

  Future<void> fetchFinancialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchDataKeuanganSekolah(),
        _fetchDataKeuanganKomite(), // Sekarang fungsi ini sudah berisi logika nyata
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data ringkasan keuangan: ${e.toString()}");
      print("Error fetching financial data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDataKeuanganSekolah() async {
    int tagihan = 0;
    int terbayar = 0;

    // Ambil semua tagihan tahunan
    final tagihanTahunanSnap = await _firestore.collectionGroup('tagihan')
        .where('idTahunAjaran', isEqualTo: taAktif)
        .get();

    final now = DateTime.now();
    for (var doc in tagihanTahunanSnap.docs) {
      final data = doc.data();
      bool isDueAndCountable = true;
      if (data['jenisPembayaran'] == 'SPP') {
        final tglJatuhTempo = (data['tanggalJatuhTempo'] as Timestamp?)?.toDate();
        if (tglJatuhTempo != null && tglJatuhTempo.isAfter(now)) {
          isDueAndCountable = false;
        }
      }
      if (isDueAndCountable) {
        tagihan += (data['jumlahTagihan'] as num?)?.toInt() ?? 0;
        terbayar += (data['jumlahTerbayar'] as num?)?.toInt() ?? 0;
      }
    }

    // Ambil semua tagihan Uang Pangkal
    final uangPangkalSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('keuangan_sekolah').doc('tagihan_uang_pangkal')
        .collection('tagihan').get();
    
    for (var doc in uangPangkalSnap.docs) {
      final data = doc.data();
      tagihan += (data['totalTagihan'] as num?)?.toInt() ?? 0;
      terbayar += (data['totalTerbayar'] as num?)?.toInt() ?? 0;
    }

    totalTagihanSekolah.value = tagihan;
    totalTerbayarSekolah.value = terbayar;
  }

  // [PEROMBAKAN UTAMA DI SINI]
  Future<void> _fetchDataKeuanganKomite() async {
    if (taAktif.isEmpty || taAktif.contains("TIDAK")) return;

    final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(taAktif)
      .collection('komite').doc('sekolah')
      .collection('log_transaksi').orderBy('timestamp', descending: true).get();
      
    final semuaLog = snap.docs.map((d) => KomiteLogTransaksiModel.fromFirestore(d)).toList();

    int saldo = 0;
    for (var trx in semuaLog) {
      if (trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK') {
        saldo += trx.nominal;
      } else if (trx.jenis == 'Pengeluaran' || trx.jenis == 'KELUAR') {
        if (trx.status == 'disetujui' || trx.jenis == 'KELUAR') {
          saldo -= trx.nominal;
        }
      }
    }
    saldoKasKomite.value = saldo;
    // Ambil 3 transaksi terbaru untuk ditampilkan di ringkasan
    logTransaksiKomiteTerbaru.assignAll(semuaLog.take(3).toList());
  }

  void goToLaporanKeuangan() {
    Get.toNamed(Routes.LAPORAN_KEUANGAN);
  }

  void goToLaporanKomite() {
    Get.toNamed(Routes.LAPORAN_KOMITE_PIMPINAN);
  }
}