// lib/app/modules/detail_keuangan_siswa/controllers/detail_keuangan_siswa_controller.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android_printer;

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart'; // [BARU] Untuk cek hak akses
import '../../../models/printer_model.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../models/tagihan_model.dart';
import '../../../models/transaksi_model.dart';
import '../../../services/notifikasi_service.dart';
import '../../../routes/app_pages.dart';
import '../../../services/pdf_helper_service.dart';
import '../../../widgets/number_input_formatter.dart';

class DetailKeuanganSiswaController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();
  final DashboardController dashboardC = Get.find<DashboardController>(); // [BARU] Instance DashboardController

  late SiswaKeuanganModel siswa;
  late TabController tabController;

  // --- State UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isProcessingPdf = false.obs;

  // --- State Data Keuangan ---
  final RxList<TagihanModel> tagihanSPP = <TagihanModel>[].obs;
  final RxList<TagihanModel> tagihanLainnya = <TagihanModel>[].obs;
  final RxList<TransaksiModel> riwayatTransaksi = <TransaksiModel>[].obs;
  final Rxn<TagihanModel> tagihanUangPangkal = Rxn<TagihanModel>();
  final RxInt totalTunggakan = 0.obs;

  // --- State Pembayaran ---
  final RxList<String> tabTitles = <String>[].obs;
  final RxList<String> sppBulanTerpilih = <String>[].obs;
  final RxInt totalSppAkanDibayar = 0.obs;
  final jumlahBayarC = TextEditingController();
  final metodePembayaran = "Tunai".obs;
  final keteranganC = TextEditingController();
  
  // --- State Info Sekolah & Konfigurasi Keuangan ---
  final RxMap<String, dynamic> infoSekolah = <String, dynamic>{}.obs;
  final RxList<String> alasanEditUP = <String>[].obs; // [BARU] Untuk menampung alasan dari Firestore

  final RxString namaWaliKelas = ''.obs;

  // [BARU] Getter untuk memeriksa otorisasi
  bool get isAllowedToModify => dashboardC.isBendaharaOrPimpinan;

  @override
  void onInit() {
    super.onInit();
    siswa = Get.arguments as SiswaKeuanganModel;
    tabController = TabController(length: 0, vsync: this);
    ever(sppBulanTerpilih, _hitungTotalSppAkanDibayar);
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadDataKeuangan(),
        _fetchInfoSekolah(),
        _fetchInfoWaliKelas(), // <-- TAMBAHKAN BARIS INI
        if (isAllowedToModify) _fetchKonfigurasiKeuangan(),
      ]);
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchInfoWaliKelas() async {
  if (siswa.kelasId == null || siswa.kelasId!.isEmpty) {
    namaWaliKelas.value = "N/A";
    return;
  }
  try {
    final kelasDoc = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').doc(siswa.kelasId)
        .get();

    if (kelasDoc.exists && kelasDoc.data() != null) {
      namaWaliKelas.value = kelasDoc.data()!['namaWaliKelas'] ?? 'Belum Diatur';
    } else {
      namaWaliKelas.value = 'Data Kelas Tidak Ditemukan';
    }
  } catch (e) {
    namaWaliKelas.value = 'Gagal Memuat';
    print("### Error fetch wali kelas: $e");
  }
}

/// Menampilkan bottom sheet dengan rincian tunggakan.
void showDetailTunggakan() {
  final List<TagihanModel> daftarTunggakan = [];
  final semuaTagihan = [...tagihanSPP, ...tagihanLainnya];
  if (tagihanUangPangkal.value != null) {
    semuaTagihan.add(tagihanUangPangkal.value!);
  }
  
  // [PERBAIKAN #1] Dapatkan waktu saat ini untuk perbandingan
  final now = DateTime.now();

  for (var tagihan in semuaTagihan) {
    if (tagihan.status != 'Lunas') {
      
      // [PERBAIKAN #2] Asumsikan semua adalah tunggakan, kecuali terbukti tidak
      bool isTunggakan = true; 

      // [PERBAIKAN #3] Tambahkan logika khusus untuk SPP
      if (tagihan.jenisPembayaran == 'SPP') {
        // Jika SPP belum memiliki tanggal jatuh tempo ATAU tanggalnya masih di masa depan,
        // maka itu BUKAN tunggakan.
        if (tagihan.tanggalJatuhTempo == null || tagihan.tanggalJatuhTempo!.toDate().isAfter(now)) {
          isTunggakan = false;
        }
      }

      // [PERBAIKAN #4] Hanya tambahkan ke daftar jika itu benar-benar tunggakan
      if (isTunggakan) {
        daftarTunggakan.add(tagihan);
      }
    }
  }

  // 2. Tampilkan Bottom Sheet
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text("Detail Tunggakan", style: Get.textTheme.titleLarge),
          const Divider(),

          // Info Siswa
          _buildDetailRow("Nama Siswa", siswa.namaLengkap),
          _buildDetailRow("Kelas", siswa.kelasId?.split('-').first ?? "N/A"),
          Obx(() => _buildDetailRow("Wali Kelas", namaWaliKelas.value)),
          const SizedBox(height: 16),
          
          // Daftar Tunggakan
          Text("Rincian:", style: Get.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Gunakan Flexible agar ListView tidak overflow jika tunggakan banyak
          Flexible(
            child: daftarTunggakan.isEmpty
                ? const Text("Tidak ada tunggakan saat ini.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: daftarTunggakan.length,
                    itemBuilder: (context, index) {
                      final tunggakan = daftarTunggakan[index];
                      return ListTile(
                        dense: true,
                        title: Text(tunggakan.deskripsi),
                        trailing: Text(
                          "Rp ${NumberFormat.decimalPattern('id_ID').format(tunggakan.sisaTagihan)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    isScrollControlled: true, // Penting agar tinggi bottom sheet bisa menyesuaikan
  );
}

  // Helper widget untuk baris detail (mungkin sudah Anda miliki)
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // [FUNGSI BARU] Mengambil daftar alasan edit Uang Pangkal dari Firestore
  Future<void> _fetchKonfigurasiKeuangan() async {
    try {
      final doc = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_keuangan')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['alasanEditUangPangkal'] is List) {
          alasanEditUP.assignAll(List<String>.from(data['alasanEditUangPangkal']));
        }
      }
      // Jika tidak ada atau kosong, tambahkan default
      if (alasanEditUP.isEmpty) {
        alasanEditUP.assignAll(['Koreksi Input', 'Keringanan/Beasiswa', 'Perubahan Kebijakan', 'Lainnya']);
      }
    } catch (e) {
      print("### Gagal mengambil konfigurasi keuangan: $e");
      // Fallback ke default jika error
      alasanEditUP.assignAll(['Koreksi Input', 'Keringanan/Beasiswa', 'Perubahan Kebijakan', 'Lainnya']);
    }
  }

  // ... (fungsi _fetchInfoSekolah, _loadDataKeuangan, _hitungTotalTunggakan, _prosesDataTagihan, _prosesDataTransaksi, _buatTabDinamis tetap sama)
   Future<void> _fetchInfoSekolah() async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      if (doc.exists) {
        infoSekolah.value = doc.data() ?? {};
      }
    } catch (e) {
      print("### Gagal mengambil info sekolah: $e");
    }
  }

  Future<void> _loadDataKeuangan() async {
    isLoading.value = true;
    try {
      final uidSiswa = siswa.uid;
      final taAktif = configC.tahunAjaranAktif.value;
      final tahun = int.parse(taAktif.split('-').first);
      final taLama = "${tahun - 1}-${tahun}";

      final keuanganAktifRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa);
      final keuanganLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taLama).collection('keuangan_siswa').doc(uidSiswa);
      final tagihanPangkalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(uidSiswa);
      final tunggakanAwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tunggakanAwal').doc(uidSiswa);

      final results = await Future.wait([
        keuanganAktifRef.collection('tagihan').get(),
        keuanganAktifRef.collection('transaksi').orderBy('tanggalBayar', descending: true).get(),
        tagihanPangkalRef.get(),
        keuanganLamaRef.collection('tagihan').where('status', isNotEqualTo: 'Lunas').get(),
        tunggakanAwalRef.get()
      ]);

      _prosesDataTagihan(
        results[0] as QuerySnapshot<Map<String, dynamic>>,
        results[2] as DocumentSnapshot<Map<String, dynamic>>,
        results[3] as QuerySnapshot<Map<String, dynamic>>,
        results[4] as DocumentSnapshot<Map<String, dynamic>>,
      );
      _prosesDataTransaksi(results[1] as QuerySnapshot<Map<String, dynamic>>);
      _buatTabDinamis();
      _hitungTotalTunggakan(); // Pastikan ini dipanggil
      
    } catch(e) {
      Get.snackbar("Error", "Gagal memuat data keuangan: ${e.toString()}");
      print("### Error load data keuangan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _hitungTotalTunggakan() {
    int total = 0;
    final semuaTagihan = [...tagihanSPP, ...tagihanLainnya];
    if (tagihanUangPangkal.value != null) {
      semuaTagihan.add(tagihanUangPangkal.value!);
    }
    
    final now = DateTime.now();
    for (var tagihan in semuaTagihan) {
      if (tagihan.status != 'Lunas') {
        bool isDue = true;
        if (tagihan.jenisPembayaran == 'SPP') {
          if (tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isAfter(now)) {
            isDue = false;
          }
        }
        if (isDue) {
          total += tagihan.sisaTagihan;
        }
      }
    }
    totalTunggakan.value = total;
  }


  void _prosesDataTagihan(
    QuerySnapshot<Map<String, dynamic>> snapTahunan,
    DocumentSnapshot<Map<String, dynamic>> snapPangkal,
    QuerySnapshot<Map<String, dynamic>> snapTunggakanLama,
    // [MODIFIKASI 4] Tambahkan parameter baru
    DocumentSnapshot<Map<String, dynamic>> snapTunggakanAwal) {
        
    tagihanSPP.clear();
    tagihanLainnya.clear();
    tagihanUangPangkal.value = null;

    if (snapTunggakanAwal.exists && (snapTunggakanAwal.data()?['lunas'] ?? false) == false) {
    final data = snapTunggakanAwal.data()!;
    final sisa = (data['sisaTunggakan'] as num?)?.toInt() ?? 0;

    if (sisa > 0) { // Hanya proses jika masih ada sisa
      final tagihanAwal = TagihanModel(
        id: "TUNGGAKAN-AWAL-${snapTunggakanAwal.id}",
        deskripsi: data['keterangan'] ?? "Tunggakan awal sistem",
        jenisPembayaran: "Tunggakan Lama", // Kelompokkan dengan tunggakan lain
        jumlahTagihan: (data['totalTunggakan'] as num?)?.toInt() ?? 0,
        jumlahTerbayar: ((data['totalTunggakan'] as num?)?.toInt() ?? 0) - sisa,
        status: 'Jatuh Tempo',
        isTunggakan: true,
        metadata: {'sumber': 'tunggakanAwal'},
      );
      tagihanLainnya.add(tagihanAwal);
    }
  }

    for (var doc in snapTunggakanLama.docs) {
      final tagihan = TagihanModel.fromFirestore(doc);
      final tagihanTunggakan = TagihanModel(
        id: "TUNGGAKAN-${tagihan.id}", 
        deskripsi: "Tunggakan ${tagihan.deskripsi}",
        isTunggakan: true,
        jenisPembayaran: tagihan.jenisPembayaran,
        jumlahTagihan: tagihan.sisaTagihan,
        jumlahTerbayar: 0,
        status: 'Jatuh Tempo',
        tanggalJatuhTempo: tagihan.tanggalJatuhTempo,
        metadata: tagihan.metadata
      );
      
      if (tagihanTunggakan.jenisPembayaran == 'SPP') {
        tagihanSPP.add(tagihanTunggakan);
      } else {
        tagihanLainnya.add(tagihanTunggakan);
      }
    }

    for (var doc in snapTahunan.docs) {
      final tagihan = TagihanModel.fromFirestore(doc);
      if (tagihan.jenisPembayaran == 'SPP') {
        tagihanSPP.add(tagihan);
      } else {
        tagihanLainnya.add(tagihan);
      }
    }

    tagihanSPP.sort((a, b) {
      if (a.isTunggakan && !b.isTunggakan) return -1;
      if (!a.isTunggakan && b.isTunggakan) return 1;
      return a.tanggalJatuhTempo!.compareTo(b.tanggalJatuhTempo!);
    });

    if (snapPangkal.exists) {
      tagihanUangPangkal.value = TagihanModel.fromFirestore(snapPangkal);
    }
  }

  void _prosesDataTransaksi(QuerySnapshot<Map<String, dynamic>> snapshot) {
    riwayatTransaksi.assignAll(snapshot.docs.map((doc) => TransaksiModel.fromFirestore(doc)).toList());
  }

  void _buatTabDinamis() {
    final Set<String> jenisTagihan = {};
    if (tagihanUangPangkal.value != null) jenisTagihan.add("Uang Pangkal");
    if (tagihanSPP.isNotEmpty) jenisTagihan.add("SPP");
    for (var tagihan in tagihanLainnya) {
      jenisTagihan.add(tagihan.jenisPembayaran);
    }
    
    final titles = jenisTagihan.toList()..sort();
    titles.add("Riwayat");
    
    tabTitles.assignAll(titles);
    tabController = TabController(length: tabTitles.length, vsync: this);
    tabController.addListener(() {
      update(['fab']);
    });
  }

    void toggleBulanSpp(String idTagihan) {
      if (sppBulanTerpilih.contains(idTagihan)) sppBulanTerpilih.remove(idTagihan);
      else sppBulanTerpilih.add(idTagihan);
    }

  void _hitungTotalSppAkanDibayar(List<String> listId) {
    int total = 0;
    for (var id in listId) {
      final tagihan = tagihanSPP.firstWhereOrNull((t) => t.id == id);
      if (tagihan != null) total += tagihan.sisaTagihan;
    }
    totalSppAkanDibayar.value = total;

    // [KUNCI REVISI] Beri tahu GetBuilder 'fab' untuk me-render ulang dirinya
    update(['fab']); 
  }

  void showDialogPembayaranSpp() {
    // [REVISI KUNCI #2] Tambahkan 'Guard Clause' di sini
    if (totalSppAkanDibayar.value <= 0) {
      Get.snackbar(
        "Informasi", 
        "Silakan centang satu atau lebih tagihan SPP yang akan dibayar.",
        snackPosition: SnackPosition.TOP, // Lebih terlihat
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.amber.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4)
      );
      return; // Hentikan fungsi agar dialog konfirmasi tidak muncul
    }
  
    // Jika total > 0, kode di bawah ini akan berjalan seperti biasa
    Get.defaultDialog(
      title: "Konfirmasi Pembayaran SPP",
      middleText: "Anda akan mencatat pembayaran SPP sebesar Rp ${NumberFormat.decimalPattern('id_ID').format(totalSppAkanDibayar.value)} untuk ${sppBulanTerpilih.length} bulan yang terpilih. Lanjutkan?",
      confirm: ElevatedButton(onPressed: prosesPembayaranSpp, child: const Text("Ya, Simpan")),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  // Future<void> prosesPembayaranSpp() async {
  //   isSaving.value = true;
  //   Get.back();

  //   TransaksiModel? newTransaksi;

  //   try {
  //     final taAktif = configC.tahunAjaranAktif.value;
  //     final keuanganSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
  //         .collection('tahunajaran').doc(taAktif)
  //         .collection('keuangan_siswa').doc(siswa.uid);

  //     await _firestore.runTransaction((transaction) async {
  //       final pencatatUid = configC.infoUser['uid'] ?? 'unknown';
  //       final pencatatNama = getPencatatNama();

  //       final List<DocumentSnapshot> tagihanDocsToUpdate = [];
  //       for (var idTagihan in sppBulanTerpilih) {
  //         final tagihanRef = keuanganSiswaRef.collection('tagihan').doc(idTagihan);
  //         final tagihanDoc = await transaction.get(tagihanRef);
  //         if (!tagihanDoc.exists) throw Exception("Tagihan $idTagihan tidak ditemukan!");
  //         tagihanDocsToUpdate.add(tagihanDoc);
  //       }

  //       for (var tagihanDoc in tagihanDocsToUpdate) {
  //         final tagihanData = tagihanDoc.data() as Map<String, dynamic>;
  //         transaction.update(tagihanDoc.reference, {
  //           'status': 'Lunas', 
  //           'jumlahTerbayar': tagihanData['jumlahTagihan']
  //         });
  //       }

  //       final deskripsiPertama = tagihanSPP.firstWhere((t) => t.id == sppBulanTerpilih.first).deskripsi;

  //       final transaksiRef = keuanganSiswaRef.collection('transaksi').doc();
  //       transaction.set(transaksiRef, {
  //         'jumlahBayar': totalSppAkanDibayar.value,
  //         'tanggalBayar': Timestamp.now(),
  //         'metodePembayaran': "Tunai",
  //         'keterangan': "Pembayaran ${sppBulanTerpilih.length} bulan SPP (mulai dari $deskripsiPertama)",
  //         'idTagihanTerkait': sppBulanTerpilih.toList(),
  //         'dicatatOlehUid': pencatatUid,
  //         'dicatatOlehNama': pencatatNama,
  //       });
  //     });

  //     final String formattedAmountSpp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalSppAkanDibayar.value);
  //     await NotifikasiService.kirimNotifikasi(
  //       uidPenerima: siswa.uid,
  //       judul: "Pembayaran SPP Diterima",
  //       isi: "Pembayaran ${sppBulanTerpilih.length} bulan SPP sebesar $formattedAmountSpp telah berhasil kami catat. Terima kasih.",
  //       tipe: 'keuangan',
  //     );

  //     newTransaksi = TransaksiModel(
  //         id: 'temp_id', 
  //         jumlahBayar: totalSppAkanDibayar.value,
  //         tanggalBayar: DateTime.now(),
  //         metodePembayaran: "Tunai",
  //         keterangan: "Pembayaran ${sppBulanTerpilih.length} bulan SPP...",
  //         dicatatOlehNama: getPencatatNama(), idTagihanTerkait: sppBulanTerpilih.toList()
  //     );

  //     sppBulanTerpilih.clear();
  //     Get.snackbar("Berhasil", "Pembayaran SPP telah berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
  //     _loadDataKeuangan();

  //   } catch (e) { 
  //     Get.snackbar("Error", "Transaksi Gagal: ${e.toString()}", 
  //     duration: const Duration(seconds: 5));
  //   } finally { 
  //     isSaving.value = false; 
  //   }

  //   if (newTransaksi != null) {
  //     showPrinterChoiceDialog(newTransaksi);
  //   }
  // }

  Future<void> prosesPembayaranSpp() async {
    isSaving.value = true;
    Get.back(); // Tutup dialog konfirmasi

    TransaksiModel? newTransaksi;

    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final keuanganSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('keuangan_siswa').doc(siswa.uid);

      await _firestore.runTransaction((transaction) async {
        final pencatatUid = configC.infoUser['uid'] ?? 'unknown';
        final pencatatNama = getPencatatNama();

        // --- Bagian 1: Logika Update Tagihan Siswa (Tidak berubah) ---
        final List<DocumentSnapshot> tagihanDocsToUpdate = [];
        for (var idTagihan in sppBulanTerpilih) {
          final tagihanRef = keuanganSiswaRef.collection('tagihan').doc(idTagihan);
          final tagihanDoc = await transaction.get(tagihanRef);
          if (!tagihanDoc.exists) throw Exception("Tagihan $idTagihan tidak ditemukan!");
          tagihanDocsToUpdate.add(tagihanDoc);
        }

        for (var tagihanDoc in tagihanDocsToUpdate) {
          final tagihanData = tagihanDoc.data() as Map<String, dynamic>;
          transaction.update(tagihanDoc.reference, {
            'status': 'Lunas',
            'jumlahTerbayar': tagihanData['jumlahTagihan']
          });
        }

        // --- Bagian 2: Logika Pencatatan Transaksi Siswa (Tidak berubah) ---
        final deskripsiPertama = tagihanSPP.firstWhere((t) => t.id == sppBulanTerpilih.first).deskripsi;
        final transaksiSiswaRef = keuanganSiswaRef.collection('transaksi').doc();
        transaction.set(transaksiSiswaRef, {
          'jumlahBayar': totalSppAkanDibayar.value,
          'tanggalBayar': Timestamp.now(),
          'metodePembayaran': "Tunai",
          'keterangan': "Pembayaran ${sppBulanTerpilih.length} bulan SPP (mulai dari $deskripsiPertama)",
          'idTagihanTerkait': sppBulanTerpilih.toList(),
          'dicatatOlehUid': pencatatUid,
          'dicatatOlehNama': pencatatNama,
        });

        // --- [MODIFIKASI LAPORAN KEUANGAN] Bagian 3: Pencatatan Ganda ke Buku Besar ---
        final tahunAnggaran = DateTime.now().year.toString();
        final summaryAnggaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunAnggaran').doc(tahunAnggaran);
        final transaksiAnggaranRef = summaryAnggaranRef.collection('transaksi').doc();

        final dataTransaksiAnggaran = {
          'tanggal': Timestamp.now(),
          'jenis': 'Pemasukan',
          'sumberDana': 'Kas Tunai', // Asumsi SPP selalu tunai di fungsi ini
          'jumlah': totalSppAkanDibayar.value,
          'kategori': 'Pembayaran SPP',
          'keterangan': "Pembayaran ${sppBulanTerpilih.length} bulan SPP dari ${siswa.namaLengkap}",
          'noReferensi': "TRX-SPP-${transaksiSiswaRef.id.substring(0, 6)}",
          'refIdDokumenSiswa': transaksiSiswaRef.id,
          'diinputOleh': pencatatUid,
          'diinputOlehNama': pencatatNama,
          'idSiswa': siswa.uid,
          'namaSiswa': siswa.namaLengkap,
        };

        transaction.set(transaksiAnggaranRef, dataTransaksiAnggaran);
        transaction.set(summaryAnggaranRef, {
          'tahun': int.parse(tahunAnggaran),
          'totalPemasukan': FieldValue.increment(totalSppAkanDibayar.value),
          'saldoAkhir': FieldValue.increment(totalSppAkanDibayar.value),
          'saldoKasTunai': FieldValue.increment(totalSppAkanDibayar.value),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // --- Bagian 4: Notifikasi & Refresh UI (Tidak berubah) ---
      final String formattedAmountSpp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalSppAkanDibayar.value);
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: siswa.uid,
        judul: "Pembayaran SPP Diterima",
        isi: "Pembayaran ${sppBulanTerpilih.length} bulan SPP sebesar $formattedAmountSpp telah berhasil kami catat. Terima kasih.",
        tipe: 'keuangan',
      );

      newTransaksi = TransaksiModel(
          id: 'temp_id',
          jumlahBayar: totalSppAkanDibayar.value,
          tanggalBayar: DateTime.now(),
          metodePembayaran: "Tunai",
          keterangan: "Pembayaran ${sppBulanTerpilih.length} bulan SPP...",
          dicatatOlehNama: getPencatatNama(), idTagihanTerkait: sppBulanTerpilih.toList()
      );

      sppBulanTerpilih.clear();
      Get.snackbar("Berhasil", "Pembayaran SPP telah berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
      _loadDataKeuangan();

    } catch (e) {
      Get.snackbar("Error", "Transaksi Gagal: ${e.toString()}",
      duration: const Duration(seconds: 5));
      print("### Error during prosesPembayaranSPP: $e");
    } finally {
      isSaving.value = false;
    }

    if (newTransaksi != null) {
      showPrinterChoiceDialog(newTransaksi);
    }
  }

  void showDialogPembayaranUmum(TagihanModel tagihan) {
    jumlahBayarC.text = tagihan.sisaTagihan.toString();
    metodePembayaran.value = "Tunai";
    keteranganC.clear();

    Get.defaultDialog(
      title: "Catat Pembayaran",
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tagihan.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: jumlahBayarC, 
          keyboardType: TextInputType.number,
          inputFormatters: [NumberInputFormatter()],
          decoration: const InputDecoration(labelText: "Jumlah Bayar", 
          prefixText: "Rp ", 
          border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Obx(() => DropdownButtonFormField<String>(
            value: metodePembayaran.value,
            items: ["Tunai", "Transfer Bank", "Lainnya"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) { if (v != null) metodePembayaran.value = v; },
            decoration: const InputDecoration(labelText: "Metode Pembayaran", border: OutlineInputBorder()),
          )),
          const SizedBox(height: 16),
          TextField(controller: keteranganC, decoration: const InputDecoration(labelText: "Keterangan (Opsional)", border: OutlineInputBorder())),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isSaving.value ? null : () => prosesPembayaranUmum(tagihan),
        child: isSaving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text("Simpan Transaksi"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  // Future<void> prosesPembayaranUmum(TagihanModel tagihan) async {
  //   isSaving.value = true;
  //   int jumlahBayar = int.tryParse(jumlahBayarC.text) ?? 0;
  //   if (jumlahBayar <= 0) {
  //     Get.snackbar("Peringatan", "Jumlah bayar tidak valid.");
  //     isSaving.value = false; return;
  //   }

  //   TransaksiModel? newTransaksi;

  //   try {
  //     DocumentReference tagihanRef;
  //     CollectionReference transaksiRef;
  //     final bool isUangPangkal = tagihan.jenisPembayaran == 'Uang Pangkal';

  //     if (isUangPangkal) {
  //       tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(siswa.uid);
  //     } else {
  //       tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(configC.tahunAjaranAktif.value).collection('keuangan_siswa').doc(siswa.uid).collection('tagihan').doc(tagihan.id);
  //     }
  //     transaksiRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(configC.tahunAjaranAktif.value).collection('keuangan_siswa').doc(siswa.uid).collection('transaksi');

  //     await _firestore.runTransaction((transaction) async {
  //       final tagihanDoc = await transaction.get(tagihanRef);
  //       if (!tagihanDoc.exists) throw Exception("Tagihan tidak ditemukan!");
  //       final tagihanData = tagihanDoc.data() as Map<String, dynamic>;
  //       final jumlahTerbayarLama = (tagihanData['jumlahTerbayar'] as num?)?.toInt() ?? 0;
  //       final jumlahTagihan = (tagihanData['totalTagihan'] ?? tagihanData['jumlahTagihan']) as int;
  //       final jumlahTerbayarBaru = jumlahTerbayarLama + jumlahBayar;
  //       final statusBaru = jumlahTerbayarBaru >= jumlahTagihan ? 'Lunas' : 'Belum Lunas';
  //       transaction.update(tagihanRef, {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru});
  //       if (isUangPangkal) {
  //         final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
  //         transaction.set(siswaRef, {'uangPangkal': {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru}}, SetOptions(merge: true));
  //       }
  //       final pencatatUid = configC.infoUser['uid'] ?? 'unknown';
  //       final pencatatNama = getPencatatNama();
  //       transaction.set(transaksiRef.doc(), {
  //         'jumlahBayar': jumlahBayar,
  //         'tanggalBayar': Timestamp.now(),
  //         'metodePembayaran': metodePembayaran.value,
  //         'keterangan': "Pembayaran untuk ${tagihan.deskripsi}. ${keteranganC.text.trim()}",
  //         'idTagihanTerkait': [tagihan.id],
  //         'dicatatOlehUid': pencatatUid,
  //         'dicatatOlehNama': pencatatNama,
  //       });

  //     });

  //     Get.back();

  //     final String formattedAmount = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(jumlahBayar);
  //     await NotifikasiService.kirimNotifikasi(
  //       uidPenerima: siswa.uid,
  //       judul: "Pembayaran Diterima",
  //       isi: "Pembayaran sebesar $formattedAmount untuk ${tagihan.deskripsi} telah berhasil kami catat.",
  //       tipe: 'keuangan',
  //     );

  //     newTransaksi = TransaksiModel(
  //       id: 'temp_id',
  //       jumlahBayar: int.tryParse(jumlahBayarC.text) ?? 0,
  //       tanggalBayar: DateTime.now(),
  //       metodePembayaran: metodePembayaran.value,
  //       keterangan: "Pembayaran untuk ${tagihan.deskripsi}. ${keteranganC.text.trim()}",
  //       dicatatOlehNama: getPencatatNama(), idTagihanTerkait: [tagihan.id]
  //     );

  //     Get.back(); 

  //     Get.snackbar("Berhasil", "Pembayaran telah berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
  //     _loadDataKeuangan();
  //   } catch (e) { Get.snackbar("Error", "Transaksi Gagal: ${e.toString()}");
  //   } finally { isSaving.value = false; }

  //   if (newTransaksi != null) {
  //     showPrinterChoiceDialog(newTransaksi);
  //   }
  // }

  Future<void> prosesPembayaranUmum(TagihanModel tagihan) async {
    isSaving.value = true;
    int jumlahBayar = int.tryParse(jumlahBayarC.text.replaceAll('.', '')) ?? 0;
    if (jumlahBayar <= 0) {
      Get.snackbar("Peringatan", "Jumlah bayar tidak valid.");
      isSaving.value = false;
      return;
    }

    TransaksiModel? newTransaksi;

    try {
      // [MODIFIKASI KUNCI] Variabel referensi dideklarasikan di sini
      DocumentReference tagihanRef;
      final bool isUangPangkal = tagihan.jenisPembayaran == 'Uang Pangkal';
      final bool isTunggakanAwal = tagihan.id.startsWith("TUNGGAKAN-AWAL-");

      // Path ke koleksi transaksi siswa tetap sama
      final transaksiSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('keuangan_siswa').doc(siswa.uid)
          .collection('transaksi');

      await _firestore.runTransaction((transaction) async {
        // --- Bagian 1: Logika Update Tagihan Siswa ---
        if (isUangPangkal) {
          tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('keuangan_sekolah').doc('tagihan_uang_pangkal')
              .collection('tagihan').doc(siswa.uid);
        } else if (isTunggakanAwal) {
          // [MODIFIKASI KUNCI] Logika baru untuk menangani Tunggakan Awal
          tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('tunggakanAwal').doc(siswa.uid);
        } else {
          tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
              .collection('keuangan_siswa').doc(siswa.uid)
              .collection('tagihan').doc(tagihan.id);
        }

        final tagihanDoc = await transaction.get(tagihanRef);
        if (!tagihanDoc.exists) throw Exception("Tagihan tidak ditemukan!");

        final tagihanData = tagihanDoc.data() as Map<String, dynamic>;

        if (isTunggakanAwal) {
          // [MODIFIKASI KUNCI] Logika update spesifik untuk koleksi tunggakanAwal
          final sisaLama = (tagihanData['sisaTunggakan'] as num?)?.toInt() ?? 0;
          final sisaBaru = sisaLama - jumlahBayar;
          transaction.update(tagihanRef, {
            'sisaTunggakan': sisaBaru,
            'lunas': sisaBaru <= 0,
          });
        } else {
          // Logika update untuk tagihan reguler dan uang pangkal (tidak berubah)
          final jumlahTerbayarLama = (tagihanData['jumlahTerbayar'] as num?)?.toInt() ?? 0;
          final jumlahTagihan = (tagihanData['totalTagihan'] ?? tagihanData['jumlahTagihan']) as int;
          final jumlahTerbayarBaru = jumlahTerbayarLama + jumlahBayar;
          final statusBaru = jumlahTerbayarBaru >= jumlahTagihan ? 'Lunas' : 'Belum Lunas';
          transaction.update(tagihanRef, {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru});

          if (isUangPangkal) {
            final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
            transaction.set(siswaRef, {'uangPangkal': {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru}}, SetOptions(merge: true));
          }
        }

        // --- Bagian 2: Logika Pencatatan Transaksi Siswa (Tidak berubah) ---
        final pencatatUid = configC.infoUser['uid'] ?? 'unknown';
        final pencatatNama = getPencatatNama();
        final newTransaksiSiswaRef = transaksiSiswaRef.doc(); // Buat referensi doc baru

        transaction.set(newTransaksiSiswaRef, {
          'jumlahBayar': jumlahBayar,
          'tanggalBayar': Timestamp.now(),
          'metodePembayaran': metodePembayaran.value,
          'keterangan': "Pembayaran untuk ${tagihan.deskripsi}. ${keteranganC.text.trim()}",
          'idTagihanTerkait': [tagihan.id],
          'dicatatOlehUid': pencatatUid,
          'dicatatOlehNama': pencatatNama,
        });

        // --- [MODIFIKASI LAPORAN KEUANGAN] Bagian 3: Pencatatan Ganda ke Buku Besar ---
        final tahunAnggaran = DateTime.now().year.toString();
        final summaryAnggaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunAnggaran').doc(tahunAnggaran);
        final transaksiAnggaranRef = summaryAnggaranRef.collection('transaksi').doc();

        final dataTransaksiAnggaran = {
          'tanggal': Timestamp.now(),
          'jenis': 'Pemasukan',
          'sumberDana': metodePembayaran.value == "Tunai" ? 'Kas Tunai' : 'Bank',
          'jumlah': jumlahBayar,
          'kategori': 'Pembayaran ${tagihan.jenisPembayaran}',
          'keterangan': "Pembayaran dari ${siswa.namaLengkap} untuk ${tagihan.deskripsi}",
          'noReferensi': "TRX-${newTransaksiSiswaRef.id.substring(0, 8)}",
          'refIdDokumenSiswa': newTransaksiSiswaRef.id,
          'diinputOleh': pencatatUid,
          'diinputOlehNama': pencatatNama,
          'idSiswa': siswa.uid,
          'namaSiswa': siswa.namaLengkap,
        };

        transaction.set(transaksiAnggaranRef, dataTransaksiAnggaran);
        transaction.set(summaryAnggaranRef, {
          'tahun': int.parse(tahunAnggaran),
          'totalPemasukan': FieldValue.increment(jumlahBayar),
          'saldoAkhir': FieldValue.increment(jumlahBayar),
          (metodePembayaran.value == "Tunai" ? 'saldoKasTunai' : 'saldoBank'): FieldValue.increment(jumlahBayar),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      Get.back(); // Tutup dialog pembayaran

      // --- Bagian 4: Notifikasi & Refresh UI (Tidak berubah) ---
      final String formattedAmount = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(jumlahBayar);
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: siswa.uid,
        judul: "Pembayaran Diterima",
        isi: "Pembayaran sebesar $formattedAmount untuk ${tagihan.deskripsi} telah berhasil kami catat.",
        tipe: 'keuangan',
      );

      newTransaksi = TransaksiModel(
        id: 'temp_id',
        jumlahBayar: jumlahBayar,
        tanggalBayar: DateTime.now(),
        metodePembayaran: metodePembayaran.value,
        keterangan: "Pembayaran untuk ${tagihan.deskripsi}. ${keteranganC.text.trim()}",
        dicatatOlehNama: getPencatatNama(),
        idTagihanTerkait: [tagihan.id]
      );

      Get.snackbar("Berhasil", "Pembayaran telah berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
      _loadDataKeuangan();
    } catch (e) {
      Get.snackbar("Error", "Transaksi Gagal: ${e.toString()}");
      print("Error during prosesPembayaranUmum: $e");
    } finally {
      isSaving.value = false;
    }

    if (newTransaksi != null) {
      showPrinterChoiceDialog(newTransaksi);
    }
  }

  String getPencatatNama() {
    final alias = configC.infoUser['alias'] as String?;
    if (alias != null && alias.isNotEmpty && alias != 'N/A') return alias;
    return configC.infoUser['nama'] ?? 'User';
  }

  
  // [FUNGSI BARU] Menampilkan dialog untuk edit nominal Uang Pangkal
  void showDialogEditUangPangkal(TagihanModel tagihan) {
    // [PERBAIKAN #1] Buat GlobalKey di sini
    final formKey = GlobalKey<FormState>(); 
    final nominalBaruC = TextEditingController(text: tagihan.jumlahTagihan.toString());
    final catatanC = TextEditingController(); // [PERBAIKAN] Ubah nama controller
    final RxnString alasanTerpilih = RxnString();

    Get.defaultDialog(
      title: "Edit Nominal Uang Pangkal",
      content: Form( // [PERBAIKAN #2] Bungkus dengan widget Form
        key: formKey, // Gunakan GlobalKey
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Siswa: ${siswa.namaLengkap}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Terbayar: Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTerbayar)}"),
            const SizedBox(height: 16),
            TextFormField(
              controller: nominalBaruC,
              keyboardType: TextInputType.number,
              inputFormatters: [NumberInputFormatter()],
              decoration: const InputDecoration(labelText: "Nominal Tagihan Baru", prefixText: "Rp ", border: OutlineInputBorder()),
              validator: (val) => (int.tryParse(val ?? '0') ?? 0) <= 0 ? "Nominal tidak valid" : null,
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: alasanTerpilih.value,
              hint: const Text("Pilih Alasan Perubahan"),
              items: alasanEditUP.map((alasan) => DropdownMenuItem(value: alasan, child: Text(alasan))).toList(),
              onChanged: (val) => alasanTerpilih.value = val,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? "Alasan wajib dipilih" : null,
            )),
            const SizedBox(height: 16),
            TextFormField(
              controller: catatanC, // [PERBAIKAN] Gunakan controller yang benar
              decoration: const InputDecoration(labelText: "Catatan Tambahan (Opsional)", border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isSaving.value ? null : () {
          // [PERBAIKAN #3] Panggil validasi form
          if (formKey.currentState?.validate() ?? false) {
             prosesEditUangPangkal(
              tagihan: tagihan,
              nominalBaru: int.parse(nominalBaruC.text),
              alasan: alasanTerpilih.value!,
              catatan: catatanC.text, // [PERBAIKAN] Gunakan controller yang benar
            );
          }
        },
        child: isSaving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Simpan Perubahan"),
      )),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  // [FUNGSI BARU] Logika utama untuk memproses perubahan nominal Uang Pangkal
  Future<void> prosesEditUangPangkal({
    required TagihanModel tagihan,
    required int nominalBaru,
    required String alasan,
    String? catatan,
  }) async {
    isSaving.value = true;

    try {
      final WriteBatch batch = _firestore.batch();
      
      // --- Logika Validasi Anti-Minus ---
      int finalJumlahTerbayar = tagihan.jumlahTerbayar;
      if (nominalBaru < tagihan.jumlahTerbayar) {
        finalJumlahTerbayar = nominalBaru;
      }
      final String finalStatus = (nominalBaru <= finalJumlahTerbayar) ? 'Lunas' : 'Belum Lunas';
      
      final pencatat = {'uid': configC.infoUser['uid'], 'nama': getPencatatNama()};
      
      // [PERBAIKAN KUNCI] Buat timestamp di sisi klien SEBELUM membangun log.
      final Timestamp logTimestamp = Timestamp.now();

      // Log object untuk arrayUnion dan dokumen baru
      final logData = {
        'timestamp': logTimestamp, // Gunakan timestamp klien yang sudah jadi
        'diubahOleh': pencatat,
        'nominalLama': tagihan.jumlahTagihan,
        'nominalBaru': nominalBaru,
        'alasan': alasan,
        'catatan': catatan?.trim().isNotEmpty == true ? catatan?.trim() : null,
        'idSiswa': siswa.uid,
        'namaSiswa': siswa.namaLengkap,
      };

      // 1. Update dokumen tagihan spesifik
      final tagihanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(siswa.uid);
      batch.update(tagihanRef, {
        'jumlahTagihan': nominalBaru,
        'jumlahTerbayar': finalJumlahTerbayar,
        'status': finalStatus,
        'logPerubahan': FieldValue.arrayUnion([logData]), // Sekarang logData adalah data murni
      });

      // 2. Update dokumen siswa utama (sinkronisasi)
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      batch.update(siswaRef, {
        'uangPangkal.jumlahTagihan': nominalBaru,
        'uangPangkal.jumlahTerbayar': finalJumlahTerbayar,
        'uangPangkal.status': finalStatus,
      });

      // 3. Buat dokumen log di koleksi terpusat
      final logRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('log_perubahan_keuangan').doc();
      batch.set(logRef, logData);

      await batch.commit();

      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Nominal Uang Pangkal telah berhasil diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);
      _loadDataKeuangan(); // Refresh data

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: ${e.toString()}");
      print("### Error prosesEditUangPangkal: $e"); // Log error untuk debug
    } finally {
      isSaving.value = false;
    }
  }

  // ... (sisa kode untuk PDF) ...
  void showDetailTransaksiDialog(TransaksiModel trx) {
    Get.defaultDialog(
      title: "Rincian Transaksi",
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowDialog("Jumlah Bayar", "Rp ${NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar)}"),
          _buildDetailRowDialog("Tanggal", DateFormat('EEEE, dd MMM yyyy, HH:mm', 'id_ID').format(trx.tanggalBayar)),
          _buildDetailRowDialog("Metode", trx.metodePembayaran),
          _buildDetailRowDialog("Pencatat", trx.dicatatOlehNama),
          const Divider(height: 24),
          const Text("Keterangan/Alokasi:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trx.keterangan.isNotEmpty ? trx.keterangan : "Tidak ada keterangan."),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Tutup")),
        ElevatedButton(
          onPressed: () {
            Get.back();
            showPrinterChoiceDialog(trx);
          },
          child: const Text("Cetak Nota"),
        )
      ],
    );
  }

  Widget _buildDetailRowDialog(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> exportPdfLaporanSiswa() async {
    if (tagihanSPP.isEmpty && tagihanLainnya.isEmpty && tagihanUangPangkal.value == null) {
      Get.snackbar("Tidak Ada Data", "Siswa ini belum memiliki data tagihan untuk diekspor.");
      return;
    }
    isProcessingPdf.value = true;
    try {
      // --- LANGKAH 1: PERSIAPAN ASET & DATA (STANDARISASI) ---
      final infoSekolah = await _firestore.collection('Sekolah').doc(configC.idSekolah).get().then((d) {
        final data = d.data();
        if (data == null) return <String, dynamic>{};
        return Map<String, dynamic>.from(data);
      });
      final logoBytes = await rootBundle.load('assets/png/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final regularFont = await PdfGoogleFonts.poppinsRegular();
      final italicFont = await PdfGoogleFonts.poppinsItalic();
      final numberFormat = NumberFormat.decimalPattern('id_ID');
  
      // --- LANGKAH 2: PENGUMPULAN DATA (TIDAK BERUBAH) ---
      
      final List<TagihanModel> tagihanUntukPdf = [];
      final now = DateTime.now();

      final List<TagihanModel> semuaTagihanMentah = [...tagihanSPP, ...tagihanLainnya];
      if (tagihanUangPangkal.value != null) {
        semuaTagihanMentah.add(tagihanUangPangkal.value!);
      }
      // Terapkan logika filter
        for (var tagihan in semuaTagihanMentah) {
          if (tagihan.jenisPembayaran == 'SPP') {
            // Untuk SPP: hanya masukkan jika sudah lunas ATAU sudah jatuh tempo
            if (tagihan.status == 'Lunas' || (tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isBefore(now))) {
              tagihanUntukPdf.add(tagihan);
            }
          } else {
            // Untuk semua jenis tagihan lain, masukkan semuanya
            tagihanUntukPdf.add(tagihan);
          }
        }
      tagihanUntukPdf.sort((a, b) {
        if (a.status != 'Lunas' && b.status == 'Lunas') return -1;
        if (a.status == 'Lunas' && b.status != 'Lunas') return 1;
        final tglA = a.tanggalJatuhTempo?.toDate() ?? DateTime.now();
        final tglB = b.tanggalJatuhTempo?.toDate() ?? DateTime.now();
        return tglA.compareTo(tglB);
      });
  
      // --- LANGKAH 3: RAKIT DOKUMEN PDF ---
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          // [STANDARISASI] Gunakan Header dan Footer dari Service
          header: (context) => PdfHelperService.buildHeaderA4(
            infoSekolah: infoSekolah,
            logoImage: logoImage,
            boldFont: boldFont,
            regularFont: regularFont,
          ),
          footer: (context) => PdfHelperService.buildFooter(context, regularFont),
          build: (context) {
            // --- KONTEN DIBANGUN DI SINI ---
            
            // Bagian Ringkasan
            final ringkasan = pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Laporan Keuangan Siswa", style: pw.TextStyle(font: boldFont, fontSize: 14)),
                  pw.Divider(height: 5, thickness: 0.5),
                  pw.SizedBox(height: 10),
                  pw.Row(children: [
                    pw.SizedBox(width: 100, child: pw.Text("Nama Lengkap", style: pw.TextStyle(font: regularFont))),
                    pw.Text(": ${siswa.namaLengkap}", style: pw.TextStyle(font: boldFont)),
                  ]),
                  pw.Row(children: [
                    pw.SizedBox(width: 100, child: pw.Text("Kelas", style: pw.TextStyle(font: regularFont))),
                    pw.Text(": ${siswa.kelasId?.split('-').first ?? 'N/A'}", style: pw.TextStyle(font: boldFont)),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red)),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Tunggakan Saat Ini", style: pw.TextStyle(font: boldFont, color: PdfColors.red)),
                        pw.Text(
                          "Rp ${numberFormat.format(totalTunggakan.value)}",
                          style: pw.TextStyle(font: boldFont, color: PdfColors.red),
                        ),
                      ],
                    ),
                  )
                ],
              )
            );
  
            // [PERBAIKAN] Bagian Tabel Tagihan (menggunakan pw.Table manual)
            final tabelTagihan = pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey500),
              columnWidths: const {
                0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: ['Keterangan', 'Jumlah Tagihan', 'Sisa Tagihan', 'Status'].map((h) => 
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(h, style: pw.TextStyle(font: boldFont, fontSize: 9), textAlign: pw.TextAlign.center))
                  ).toList(),
                ),
                ...tagihanUntukPdf.map((trx) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(trx.deskripsi, style: pw.TextStyle(font: regularFont, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(numberFormat.format(trx.jumlahTagihan), style: pw.TextStyle(font: regularFont, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(numberFormat.format(trx.sisaTagihan), style: pw.TextStyle(font: regularFont, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(trx.status, style: pw.TextStyle(font: regularFont, fontSize: 8), textAlign: pw.TextAlign.center)),
                  ]
                ))
              ],
            );
            
            // [PERBAIKAN] Bagian Tabel Riwayat Transaksi (menggunakan pw.Table manual)
            pw.Widget tabelTransaksi = pw.SizedBox.shrink();
            if (riwayatTransaksi.isNotEmpty) {
              tabelTransaksi = pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 20),
                  pw.Text("Riwayat Pembayaran", style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey500),
                    columnWidths: const { 0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(5), 2: pw.FlexColumnWidth(2.5), 3: pw.FlexColumnWidth(2), },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: ['Tanggal', 'Keterangan Transaksi', 'Jumlah Bayar', 'Pencatat'].map((h) => 
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(h, style: pw.TextStyle(font: boldFont, fontSize: 9), textAlign: pw.TextAlign.center))
                        ).toList(),
                      ),
                      ...riwayatTransaksi.map((trx) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(DateFormat('dd/MM/yy HH:mm').format(trx.tanggalBayar), style: pw.TextStyle(font: regularFont, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(trx.keterangan, style: pw.TextStyle(font: regularFont, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(numberFormat.format(trx.jumlahBayar), style: pw.TextStyle(font: regularFont, fontSize: 8), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(trx.dicatatOlehNama, style: pw.TextStyle(font: regularFont, fontSize: 8), textAlign: pw.TextAlign.center)),
                        ]
                      ))
                    ],
                  ),
                ]
              );
            }
  
            return [
              ringkasan,
              tabelTagihan,
              tabelTransaksi,
            ];
          },
        ),
      );
  
      // --- LANGKAH 4: SIMPAN & BAGIKAN (TIDAK BERUBAH) ---
      final String fileName = 'laporan_keuangan_${siswa.namaLengkap.replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
      print("### PDF Siswa Export Error: $e"); // Tambahkan log untuk debug
    } finally {
      isProcessingPdf.value = false;
    }
  }

  // pw.Widget _buildPdfHeader(pw.MemoryImage logo, pw.Font boldFont) {
  //   return pw.Row(
  //       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //       children: [
  //         pw.Row(children: [
  //           pw.Image(logo, width: 40, height: 40),
  //           pw.SizedBox(width: 10),
  //           pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
  //             pw.Text("Laporan Keuangan Siswa", style: pw.TextStyle(font: boldFont, fontSize: 14)),
  //             pw.Text("MI Al-Huda Yogyakarta", style: const pw.TextStyle(fontSize: 12)),
  //           ]),
  //         ]),
  //         pw.Text("T.A: ${configC.tahunAjaranAktif.value}", style: const pw.TextStyle(fontSize: 10)),
  //       ],
  //     );
  // }

  // pw.Widget _buildPdfRingkasan(pw.Font boldFont, pw.Font font) {
  //   return pw.Padding(
  //     padding: const pw.EdgeInsets.symmetric(vertical: 20),
  //     child: pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         pw.Text("Detail Siswa", style: pw.TextStyle(font: boldFont)),
  //         pw.Divider(height: 5),
  //         pw.SizedBox(height: 5),
  //         pw.Row(children: [
  //           pw.SizedBox(width: 100, child: pw.Text("Nama Lengkap", style: pw.TextStyle(font: font))),
  //           pw.Text(": ${siswa.namaLengkap}", style: pw.TextStyle(font: boldFont)),
  //         ]),
  //         pw.Row(children: [
  //           pw.SizedBox(width: 100, child: pw.Text("Kelas", style: pw.TextStyle(font: font))),
  //           pw.Text(": ${siswa.kelasId ?? 'N/A'}", style: pw.TextStyle(font: boldFont)),
  //         ]),
  //         pw.SizedBox(height: 10),
  //         pw.Container(
  //           padding: const pw.EdgeInsets.all(8),
  //           decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red)),
  //           child: pw.Row(
  //             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //             children: [
  //               pw.Text("Total Tunggakan Saat Ini", style: pw.TextStyle(font: boldFont, color: PdfColors.red)),
  //               pw.Text(
  //                 NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalTunggakan.value),
  //                 style: pw.TextStyle(font: boldFont, color: PdfColors.red),
  //               ),
  //             ],
  //           ),
  //         )
  //       ],
  //     )
  //   );
  // }

  // pw.Widget _buildPdfTabelTagihan(List<TagihanModel> semuaTagihan, pw.Font font, pw.Font boldFont) {
  //   final headers = ['Keterangan', 'Jumlah Tagihan', 'Sisa Tagihan', 'Status'];
  //   final data = semuaTagihan.map((trx) => [
  //     trx.deskripsi,
  //     NumberFormat.decimalPattern('id_ID').format(trx.jumlahTagihan),
  //     NumberFormat.decimalPattern('id_ID').format(trx.sisaTagihan),
  //     trx.status,
  //   ]).toList();

  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Text("Rincian Semua Tagihan", style: pw.TextStyle(font: boldFont, fontSize: 12)),
  //       pw.SizedBox(height: 8),
  //       pw.Table.fromTextArray(
  //         headers: headers,
  //         data: data,
  //         headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
  //         cellStyle: pw.TextStyle(font: font, fontSize: 9),
  //         cellAlignments: {
  //           1: pw.Alignment.centerRight,
  //           2: pw.Alignment.centerRight,
  //           3: pw.Alignment.center,
  //         },
  //       ),
  //     ]
  //   );
  // }
  
  // pw.Widget _buildPdfTabelTransaksi(pw.Font font, pw.Font boldFont) {
  //   final headers = ['Tanggal', 'Keterangan Transaksi', 'Jumlah Bayar', 'Pencatat'];
  //   final data = riwayatTransaksi.map((trx) => [
  //     DateFormat('dd/MM/yy HH:mm').format(trx.tanggalBayar),
  //     trx.keterangan,
  //     NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar),
  //     trx.dicatatOlehNama,
  //   ]).toList();

  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Text("Riwayat Pembayaran", style: pw.TextStyle(font: boldFont, fontSize: 12)),
  //       pw.SizedBox(height: 8),
  //       pw.Table.fromTextArray(
  //         headers: headers,
  //         data: data,
  //         headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
  //         cellStyle: pw.TextStyle(font: font, fontSize: 9),
  //         cellAlignments: {
  //           0: pw.Alignment.center,
  //           2: pw.Alignment.centerRight,
  //           3: pw.Alignment.center,
  //         },
  //       ),
  //     ],
  //   );
  // }

  void showPrinterChoiceDialog(TransaksiModel trx) {
    Get.defaultDialog(
      title: "Cetak Nota",
      content: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text("Printer Biasa (A4 / Dot Matrix)"),
            onTap: () {
              Get.back();
              printReceipt(trx, "A4");
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Printer Thermal (Struk)"),
            onTap: () {
              Get.back();
              printReceipt(trx, "Thermal");
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Bagikan sebagai PDF"),
            onTap: () {
              Get.back();
              printReceipt(trx, "Share");
            },
          ),
        ],
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  Future<void> printReceipt(TransaksiModel trx, String format) async {
    // Jangan set isProcessingPdf di sini, biarkan fungsi di dalamnya yang mengatur

    try {
      // --- [LOGIKA KUNCI] ---
      if (format == "Thermal") {
        // Jika formatnya thermal, panggil fungsi pintar kita,
        // tidak peduli platformnya apa (fungsi pintar sudah menanganinya).
        Get.back(); // Tutup dialog pilihan
        await _cetakStrukThermalPintar(trx);

      } else {
        // Untuk semua format lain (A4, Dot Matrix, Share), gunakan alur PDF.
        isProcessingPdf.value = true;
        final Uint8List pdfBytes = await _generatePdfA4(trx);
        final String fileName = 'kwitansi_${siswa.namaLengkap.replaceAll(' ', '_')}.pdf';

        if (format == "Share") {
          await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        } else {
          await Printing.layoutPdf(onLayout: (pdfFormat) => pdfBytes);
        }
        isProcessingPdf.value = false; // Matikan loading setelah selesai
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memproses cetak: $e");
      // Pastikan loading selalu mati jika ada error
      if (isProcessingPdf.value) {
        isProcessingPdf.value = false;
      }
    }
  }

  Future<void> _cetakStrukThermalPintar(TransaksiModel trx) async {
    isProcessingPdf.value = true;
    final _storage = GetStorage();

    try {
      // [LANGKAH 1] Baca konfigurasi printer dari "Buku Catatan" yang benar.
      final printerJson = _storage.read('selected_thermal_printer');
      if (printerJson == null) {
        throw Exception("Printer struk belum diatur.");
      }
      final PrinterDevice selectedPrinter = PrinterDevice.fromJson(printerJson);

      // [LANGKAH 2] Siapkan data cetak (tidak ada perubahan di sini).
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      final yayasan = infoSekolah.value['yayasan'] ?? '';
      final namaSekolah = infoSekolah.value['namasekolah'] ?? 'MI Al-Huda YK';
      bytes += generator.text(yayasan.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(namaSekolah.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.hr();
      bytes += generator.text('BUKTI PEMBAYARAN', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.hr(ch: '-');
      bytes += generator.row([
        PosColumn(text: 'Tanggal', width: 4),
        PosColumn(text: DateFormat('dd/MM/yy HH:mm').format(trx.tanggalBayar), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Petugas', width: 4),
        PosColumn(text: trx.dicatatOlehNama, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
       bytes += generator.row([
        PosColumn(text: 'Siswa', width: 4),
        PosColumn(text: siswa.namaLengkap, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr(ch: '-');
      bytes += generator.text(trx.keterangan, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr(ch: '-');
      bytes += generator.row([
        PosColumn(text: 'TOTAL BAYAR:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: "Rp ${NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar)}",
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr();
      bytes += generator.text('Terima kasih', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();

      // [LANGKAH 3] Jalankan logika cetak sesuai platform.
    if (GetPlatform.isWindows) {
      // Logika Windows Anda sudah benar, menggunakan selectedPrinter
      if (selectedPrinter.type != PrinterType.usb || selectedPrinter.vendorId == null || selectedPrinter.productId == null) {
        throw Exception("Printer USB yang valid belum dipilih.");
      }

      String exePath = Platform.resolvedExecutable;
      String exeDir = path.dirname(exePath);
      String scriptPath = path.join(exeDir, 'data', 'helpers', 'print_helper.exe');

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'printjob.bin');
      await File(tempPath).writeAsBytes(bytes);

      // Kirim VID dan PID sebagai argumen ke helper.exe
      final result = await Process.run(scriptPath, [
        selectedPrinter.vendorId!.toRadixString(16), // Kirim sebagai Hex
        selectedPrinter.productId!.toRadixString(16),// Kirim sebagai Hex
        tempPath
      ]);

      if (result.exitCode != 0) throw Exception('Skrip helper gagal: ${result.stderr}');
      await File(tempPath).delete();

      } else if (GetPlatform.isAndroid) {
      // --- [PERBAIKAN KUNCI DI SINI] ---
      // Kita sekarang menggunakan objek 'selectedPrinter' yang sudah ada
      android_printer.BlueThermalPrinter bluetooth = android_printer.BlueThermalPrinter.instance;
      List<android_printer.BluetoothDevice> devices = await bluetooth.getBondedDevices();
      
      String targetName = selectedPrinter.name.replaceFirst('[Bluetooth] ', '');
      final targetDevice = devices.firstWhereOrNull((d) => d.name == targetName);
      
      if (targetDevice == null) {
        throw Exception("Perangkat Bluetooth '$targetName' tidak ditemukan atau belum di-pairing.");
      }

      await bluetooth.connect(targetDevice);
      bool? isConnected = await bluetooth.isConnected;

      if (isConnected == true) {
        await bluetooth.writeBytes(Uint8List.fromList(bytes));
        await bluetooth.disconnect();
      } else {
        throw Exception("Gagal terhubung ke printer Bluetooth.");
      }
      // --- [AKHIR PERBAIKAN] ---
    }
  
      Get.snackbar("Sukses", "Nota berhasil dikirim ke printer.", backgroundColor: Colors.green, colorText: Colors.white);
  
       } catch (e) {
      // --- [PENYEMPURNAAN BERDASARKAN IDE ANDA] ---
      final errorMessage = e.toString();
      if (errorMessage.contains("Printer struk belum diatur")) {
        // Jika errornya spesifik, tawarkan untuk langsung ke pengaturan
        Get.dialog(
          AlertDialog(
            title: const Text("Printer Belum Diatur"),
            content: const Text("Anda perlu mengatur printer struk terlebih dahulu. Buka halaman pengaturan sekarang?"),
            actions: [
              TextButton(onPressed: Get.back, child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Tutup dialog
                  Get.toNamed(Routes.PRINTER_SETTINGS); // Buka halaman pengaturan
                },
                child: const Text("Ya, Buka Pengaturan"),
              ),
            ],
          ),
        );
      } else {
        // Untuk semua error lainnya, tampilkan snackbar seperti biasa
        Get.snackbar("Error Cetak", "Proses cetak gagal: $errorMessage", duration: const Duration(seconds: 8));
      }
      // --- [AKHIR PENYEMPURNAAN] ---
    } finally {
      isProcessingPdf.value = false;
    }
  }

  Future<Uint8List> _generatePdfA4(TransaksiModel trx) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeaderA4(logoImage, boldFont),
              pw.SizedBox(height: 20),
              pw.Text("BUKTI PEMBAYARAN (KWITANSI)", style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildPdfDetailRow("Tanggal", DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(trx.tanggalBayar), font, boldFont),
              _buildPdfDetailRow("Telah Diterima Dari", "${siswa.namaLengkap} (Kelas: ${siswa.kelasId?.split('-').first ?? 'N/A'})", font, boldFont),
              _buildPdfDetailRow("Dicatat oleh", trx.dicatatOlehNama, font, boldFont),
              pw.SizedBox(height: 20),
              pw.Text("RINCIAN PEMBAYARAN:", style: pw.TextStyle(font: boldFont)),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(trx.keterangan, style: pw.TextStyle(font: font))),
                    pw.Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.jumlahBayar),
                      style: pw.TextStyle(font: boldFont, fontSize: 12)
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 150,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Petugas,", style: pw.TextStyle(font: font)),
                      pw.SizedBox(height: 40),
                      pw.Text(trx.dicatatOlehNama, style: pw.TextStyle(font: boldFont)),
                    ]
                  )
                )
              )
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> _generatePdfThermal(TransaksiModel trx) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    const pageFormat = PdfPageFormat(58 * PdfPageFormat.mm, 125 * PdfPageFormat.mm, marginAll: 5 * PdfPageFormat.mm);
  
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          final yayasan = infoSekolah.value['yayasan'] ?? '';
          final namaSekolah = infoSekolah.value['namasekolah'] ?? infoSekolah.value['nama'] ?? 'MI Al-Huda YK';
          final alamat = infoSekolah.value['alamatsekolah'] ?? '';
          final telp = infoSekolah.value['notelp'] ?? '';
  
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (yayasan.isNotEmpty)
                pw.Text(yayasan, style: pw.TextStyle(font: boldFont, fontSize: 8), textAlign: pw.TextAlign.center),
              if (namaSekolah.isNotEmpty)
                pw.Text(namaSekolah, style: pw.TextStyle(font: boldFont, fontSize: 10), textAlign: pw.TextAlign.center),
              if (alamat.isNotEmpty)
                pw.Text(alamat, style: pw.TextStyle(font: font, fontSize: 6), textAlign: pw.TextAlign.center),
              if (telp.isNotEmpty)
                pw.Text("Telp: $telp", style: pw.TextStyle(font: font, fontSize: 6), textAlign: pw.TextAlign.center),
              pw.Divider(height: 10, thickness: 1),
              pw.Text('BUKTI PEMBAYARAN', style: pw.TextStyle(font: boldFont, fontSize: 8)),
              pw.Divider(height: 10, thickness: 0.5),
              _buildThermalRow("Tanggal", DateFormat('dd/MM/yy HH:mm').format(trx.tanggalBayar), font),
              _buildThermalRow("Petugas", trx.dicatatOlehNama, font),
              _buildThermalRow("Siswa", siswa.namaLengkap, font),
              pw.Divider(height: 10, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.Text(trx.keterangan, style: pw.TextStyle(font: font, fontSize: 7), textAlign: pw.TextAlign.center),
              pw.Divider(height: 10, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL BAYAR:', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                  pw.Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(trx.jumlahBayar),
                    style: pw.TextStyle(font: boldFont, fontSize: 8)
                  ),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Text('Terima kasih', style: pw.TextStyle(font: font, fontSize: 7)),
            ]
          );
        },
      ),
    );
    return pdf.save();
  }


  pw.Widget _buildPdfHeaderA4(pw.MemoryImage logo, pw.Font boldFont) {
    final yayasan = infoSekolah.value['yayasan'] ?? 'Yayasan Pendidikan';
    final namaSekolah = infoSekolah.value['namasekolah'] ?? infoSekolah.value['nama'] ?? 'MI Al-Huda Yogyakarta';
    final akreditasi = infoSekolah.value['akreditasi'] ?? '';
    final npsn = infoSekolah.value['npsn'] ?? '';
    final alamat = infoSekolah.value['alamatsekolah'] ?? '';
    final telp = infoSekolah.value['notelp'] ?? '';
    final email = infoSekolah.value['email'] ?? '';

    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logo, width: 60, height: 60),
          pw.SizedBox(width: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(yayasan.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Text(namaSekolah.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 18)),
              if (akreditasi.isNotEmpty || npsn.isNotEmpty)
                pw.Text("Terakreditasi: $akreditasi | NPSN: $npsn", style: const pw.TextStyle(fontSize: 9)),
              if (alamat.isNotEmpty)
                pw.Text("Alamat: $alamat", style: const pw.TextStyle(fontSize: 9)),
              if (telp.isNotEmpty || email.isNotEmpty)
                pw.Text("Telp: $telp | Email: $email", style: const pw.TextStyle(fontSize: 9)),
            ]
          ),
        ],
      ),
      pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
      pw.Divider(height: 2, thickness: 2),
    ]);
  }

  pw.Widget _buildPdfDetailRow(String title, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(title, style: pw.TextStyle(font: font))),
          pw.Text(": ", style: pw.TextStyle(font: boldFont)),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: boldFont))),
        ],
      ),
    );
  }

  pw.Widget _buildThermalRow(String title, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 7)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 7)),
        ],
      ),
    );
  }

  void goToAlokasiPembayaran() {
    // 1. Kumpulkan semua tagihan yang belum lunas
    final List<TagihanModel> tagihanBelumLunas = [];
    final semuaTagihan = [...tagihanSPP, ...tagihanLainnya];
    if (tagihanUangPangkal.value != null) {
      semuaTagihan.add(tagihanUangPangkal.value!);
    }

    for (var tagihan in semuaTagihan) {
      if (tagihan.status != 'Lunas') {
        tagihanBelumLunas.add(tagihan);
      }
    }

    // 2. Kirim data siswa dan daftar tagihan sebagai argumen
    Get.toNamed(Routes.ALOKASI_PEMBAYARAN, arguments: {
      'siswa': siswa,
      'tagihan': tagihanBelumLunas,
    });
  }

  // void goToAlokasiPembayaran() {
  //   // Kita tidak perlu lagi mengirim 'arguments'
  //   Get.toNamed(Routes.ALOKASI_PEMBAYARAN);
  // }

  @override
  void onClose() {
    tabController.dispose();
    jumlahBayarC.dispose(); keteranganC.dispose();
    super.onClose();
  }
}