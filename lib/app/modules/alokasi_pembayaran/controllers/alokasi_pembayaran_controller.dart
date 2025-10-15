// lib/app/modules/alokasi_pembayaran/controllers/alokasi_pembayaran_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/tagihan_model.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../controllers/config_controller.dart';
import '../../../services/notifikasi_service.dart';
// [PENTING] Kita butuh akses ke controller utama untuk refresh data dan mendapatkan nama pencatat
import '../../detail_keuangan_siswa/controllers/detail_keuangan_siswa_controller.dart';

class AlokasiItem {
  final TagihanModel tagihan;
  final TextEditingController controller = TextEditingController();
  final RxInt jumlahAlokasi = 0.obs;
  final RxnString sppValidationError = RxnString();

  AlokasiItem(this.tagihan) {
    controller.addListener(() {
      jumlahAlokasi.value = int.tryParse(controller.text.replaceAll('.', '')) ?? 0;
      if (tagihan.jenisPembayaran == 'SPP') {
        validateSpp();
      }
    });
  }
  
  void validateSpp() {
    if (jumlahAlokasi.value > 0 && jumlahAlokasi.value != tagihan.sisaTagihan) {
      sppValidationError.value = "SPP harus dibayar lunas (Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.sisaTagihan)}).";
    } else {
      sppValidationError.value = null;
    }
  }

  void dispose() {
    controller.dispose();
  }
}

class AlokasiPembayaranController extends GetxController {
  // --- [REVISI KUNCI #1] ---
  // Terima data melalui constructor, bukan dari Get.arguments
  final SiswaKeuanganModel siswa;
  final List<TagihanModel> tagihanBelumLunas;
  AlokasiPembayaranController({required this.siswa, required this.tagihanBelumLunas});

  final ConfigController _configC = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxInt currentPage = 0.obs;
  final PageController pageController = PageController();
  final TextEditingController totalDiterimaC = TextEditingController();

  final RxInt totalDiterima = 0.obs;
  final RxList<AlokasiItem> itemsToAllocate = <AlokasiItem>[].obs;
  
  final RxInt totalDialokasikan = 0.obs;
  RxInt get sisaUntukAlokasi => (totalDiterima.value - totalDialokasikan.value).obs;

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    // [REVISI KUNCI #2]
    // onInit sekarang menjadi sangat bersih. 'siswa' sudah dijamin ada.
    tagihanBelumLunas.sort((a, b) {
        if (a.isTunggakan && !b.isTunggakan) return -1;
        if (!a.isTunggakan && b.isTunggakan) return 1;
        return (a.tanggalJatuhTempo?.toDate() ?? DateTime.now())
            .compareTo(b.tanggalJatuhTempo?.toDate() ?? DateTime.now());
      });

      itemsToAllocate.assignAll(tagihanBelumLunas.map((t) => AlokasiItem(t)).toList());
    
    for (var item in itemsToAllocate) {
      ever(item.jumlahAlokasi, (_) => _calculateTotalAllocated());
    }
  }

  @override
  void onClose() {
    for (var item in itemsToAllocate) {
      item.dispose();
    }
    totalDiterimaC.dispose();
    pageController.dispose();
    super.onClose();
  }

  void _calculateTotalAllocated() {
    totalDialokasikan.value = itemsToAllocate.fold(0, (sum, item) => sum + item.jumlahAlokasi.value);
  }

  void goToAllocationPage() {
    final total = int.tryParse(totalDiterimaC.text.replaceAll('.', '')) ?? 0;
    if (total <= 0) {
      Get.snackbar("Error", "Jumlah uang diterima tidak valid.");
      return;
    }
    totalDiterima.value = total;
    currentPage.value = 1;
    pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void backToNominalPage() {
    currentPage.value = 0;
    pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  // GANTI SELURUH FUNGSI ANDA DENGAN INI
// lib/app/modules/alokasi_pembayaran/controllers/alokasi_pembayaran_controller.dart

Future<void> prosesAlokasiPembayaran() async {
  // Blok validasi tidak berubah
  for (var item in itemsToAllocate) {
    if (item.sppValidationError.value != null) {
      Get.snackbar("Validasi Gagal", "Ada kesalahan pada alokasi SPP: ${item.tagihan.deskripsi}. Harap perbaiki.");
      return;
    }
  }
  if (totalDialokasikan.value <= 0) {
    Get.snackbar("Peringatan", "Anda belum mengalokasikan dana apapun.");
    return;
  }
  if (totalDialokasikan.value > totalDiterima.value) {
    Get.snackbar("Error", "Total alokasi tidak boleh melebihi dana yang diterima.");
    return;
  }

  isSaving.value = true;
  try {
    // Persiapan variabel tidak berubah
    if (siswa.uid == null || siswa.uid!.isEmpty) {
      throw Exception("ID Siswa tidak valid. Transaksi dibatalkan.");
    }
    final taAktif = _configC.tahunAjaranAktif.value;
    final String uidSiswa = siswa.uid!;
    final List<AlokasiItem> itemsBeingPaid = itemsToAllocate.where((item) => item.jumlahAlokasi.value > 0).toList();
    
    String pencatatNama = "Petugas";
    if (Get.isRegistered<DetailKeuanganSiswaController>()) {
      pencatatNama = Get.find<DetailKeuanganSiswaController>().getPencatatNama();
    }

    // --- [STRATEGI BARU: MENGGUNAKAN WRITE BATCH] ---
    // 1. Buat instance WriteBatch
    final WriteBatch batch = _firestore.batch();

    final List<String> idTagihanTerkait = [];
    String keteranganTransaksi = "Pembayaran lumpsum untuk: ";

    // 2. Loop melalui item yang akan dibayar untuk MEMBACA data terlebih dahulu
    for (var item in itemsBeingPaid) {
      final jumlahBayar = item.jumlahAlokasi.value;
      idTagihanTerkait.add(item.tagihan.id);
      keteranganTransaksi += "${item.tagihan.deskripsi} (Rp ${NumberFormat.decimalPattern('id_ID').format(jumlahBayar)}), ";

      DocumentReference tagihanRef;
      if(item.tagihan.jenisPembayaran == 'Uang Pangkal') {
        tagihanRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(uidSiswa);
      } else {
        final realTagihanId = item.tagihan.id.startsWith("TUNGGAKAN-") 
                              ? item.tagihan.id.split("TUNGGAKAN-").last 
                              : item.tagihan.id;
        
        tagihanRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa).collection('tagihan').doc(realTagihanId);
      }
      
      // Lakukan pembacaan dokumen di luar batch
      final tagihanDoc = await tagihanRef.get();
      if (!tagihanDoc.exists) throw Exception("Tagihan ${item.tagihan.deskripsi} tidak ditemukan!");

      final tagihanData = tagihanDoc.data() as Map<String, dynamic>;
      final jumlahTerbayarLama = (tagihanData['jumlahTerbayar'] as num?)?.toInt() ?? 0;
      final jumlahTagihan = (tagihanData['totalTagihan'] ?? tagihanData['jumlahTagihan']) as int;
      
      final jumlahTerbayarBaru = jumlahTerbayarLama + jumlahBayar;
      final statusBaru = jumlahTerbayarBaru >= jumlahTagihan ? 'Lunas' : 'Belum Lunas';

      // 3. Tambahkan operasi TULIS (update) ke dalam batch
      batch.update(tagihanRef, {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru});
      
      if(item.tagihan.jenisPembayaran == 'Uang Pangkal') {
        final siswaRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('siswa').doc(uidSiswa);
        batch.update(siswaRef, {'uangPangkal.jumlahTerbayar': jumlahTerbayarBaru, 'uangPangkal.status': statusBaru});
      }
    }

    // 4. Tambahkan operasi TULIS (set) untuk log transaksi ke dalam batch
    final transaksiRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa).collection('transaksi').doc();
    batch.set(transaksiRef, {
      'jumlahBayar': totalDialokasikan.value,
      'tanggalBayar': Timestamp.now(),
      'metodePembayaran': "Tunai (Lumpsum)",
      'keterangan': keteranganTransaksi.substring(0, keteranganTransaksi.length - 2),
      'idTagihanTerkait': idTagihanTerkait,
      'dicatatOlehUid': _configC.infoUser['uid'],
      'dicatatOlehNama': pencatatNama,
    });
    
    // 5. Eksekusi semua operasi tulis dalam satu panggilan atomik
    await batch.commit();

    // Sisa kode setelah transaksi berhasil tidak berubah
    await NotifikasiService.kirimNotifikasi(
      uidPenerima: siswa.uid!, 
      judul: "Pembayaran Diterima", 
      isi: "Kami telah menerima pembayaran sebesar Rp ${NumberFormat.decimalPattern('id_ID').format(totalDialokasikan.value)} yang telah dialokasikan ke beberapa tagihan. Terima kasih.",
      tipe: 'keuangan',
    );
    
    Get.back();
    Get.snackbar("Berhasil", "Pembayaran lumpsum berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
    
    if (Get.isRegistered<DetailKeuanganSiswaController>()) {
      Get.find<DetailKeuanganSiswaController>().loadInitialData();
    }

  } catch (e) {
    Get.snackbar("Error Transaksi", "Gagal menyimpan: ${e.toString()}", duration: const Duration(seconds: 8));
  } finally {
    isSaving.value = false;
  }
}
}

  // Future<void> prosesAlokasiPembayaran() async {
  //   print("--- DEBUG: 1. Memulai prosesAlokasiPembayaran ---");

  //   // Validasi SPP
  //   for (var item in itemsToAllocate) {
  //     if (item.sppValidationError.value != null) {
  //       Get.snackbar("Validasi Gagal", "Ada kesalahan pada alokasi SPP: ${item.tagihan.deskripsi}. Harap perbaiki.");
  //       print("--- DEBUG: GAGAL, validasi SPP tidak terpenuhi.");
  //       return;
  //     }
  //   }

  //   // Validasi Alokasi
  //   if (totalDialokasikan.value <= 0) {
  //     Get.snackbar("Peringatan", "Anda belum mengalokasikan dana apapun.");
  //     print("--- DEBUG: GAGAL, total dialokasikan adalah 0.");
  //     return;
  //   }
  //   if (totalDialokasikan.value > totalDiterima.value) {
  //     Get.snackbar("Error", "Total alokasi tidak boleh melebihi dana yang diterima.");
  //     print("--- DEBUG: GAGAL, alokasi melebihi dana.");
  //     return;
  //   }

  //   isSaving.value = true;

  //   try {
  //     print("--- DEBUG: 2. Validasi berhasil, masuk ke blok try-catch.");

  //     // Guard Clause
  //     if (siswa.uid == null || siswa.uid!.isEmpty) {
  //       Get.snackbar("Error Kritis", "ID Siswa tidak valid. Transaksi dibatalkan.");
  //       print("--- DEBUG: GAGAL, siswa.uid null atau kosong.");
  //       isSaving.value = false;
  //       return;
  //     }

  //     final taAktif = _configC.tahunAjaranAktif.value;
  //     final String uidSiswa = siswa.uid!;
  //     final List<AlokasiItem> itemsBeingPaid = itemsToAllocate.where((item) => item.jumlahAlokasi.value > 0).toList();

  //     print("--- DEBUG: 3. Variabel siap. TA: $taAktif, UID: $uidSiswa, Item dibayar: ${itemsBeingPaid.length}");

  //     String pencatatNama = "Petugas";
  //     if (Get.isRegistered<DetailKeuanganSiswaController>()) {
  //       pencatatNama = Get.find<DetailKeuanganSiswaController>().getPencatatNama();
  //     }
  //     print("--- DEBUG: 4. Nama pencatat didapatkan: $pencatatNama");
  //     print("--- DEBUG: 5. Akan memulai Firestore Transaction.");

  //     await _firestore.runTransaction((transaction) async {
  //       print("--- DEBUG: 6. [TX] Firestore Transaction dimulai.");

  //       final List<String> idTagihanTerkait = [];
  //       String keteranganTransaksi = "Pembayaran lumpsum untuk: ";

  //       for (var item in itemsBeingPaid) {
  //         print("--- DEBUG: 7. [TX] Memproses item: ${item.tagihan.deskripsi}");
  //         final jumlahBayar = item.jumlahAlokasi.value;
  //         idTagihanTerkait.add(item.tagihan.id);
  //         keteranganTransaksi += "${item.tagihan.deskripsi} (Rp ${NumberFormat.decimalPattern('id_ID').format(jumlahBayar)}), ";

  //         DocumentReference tagihanRef;
  //         if(item.tagihan.jenisPembayaran == 'Uang Pangkal') {
  //           tagihanRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(uidSiswa);
  //         } else {
  //           final realTagihanId = item.tagihan.id.startsWith("TUNGGAKAN-") 
  //                                 ? item.tagihan.id.split("TUNGGAKAN-").last 
  //                                 : item.tagihan.id;

  //           tagihanRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa).collection('tagihan').doc(realTagihanId);
  //         }

  //         print("--- DEBUG: 8. [TX] Path referensi tagihan: ${tagihanRef.path}");
  //         print("--- DEBUG: 9. [TX] Akan memanggil transaction.get()...");

  //         // KEMUNGKINAN CRASH ADA DI SEKITAR SINI
  //         final tagihanDoc = await transaction.get(tagihanRef);
  //         print("--- DEBUG: 10. [TX] transaction.get() berhasil. Dokumen ada: ${tagihanDoc.exists}");

  //         if (!tagihanDoc.exists) throw Exception("Tagihan ${item.tagihan.deskripsi} tidak ditemukan!");

  //         final tagihanData = tagihanDoc.data() as Map<String, dynamic>;
  //         final jumlahTerbayarLama = (tagihanData['jumlahTerbayar'] as num?)?.toInt() ?? 0;
  //         final jumlahTagihan = (tagihanData['totalTagihan'] ?? tagihanData['jumlahTagihan']) as int;

  //         final jumlahTerbayarBaru = jumlahTerbayarLama + jumlahBayar;
  //         final statusBaru = jumlahTerbayarBaru >= jumlahTagihan ? 'Lunas' : 'Belum Lunas';

  //         print("--- DEBUG: 11. [TX] Akan memanggil transaction.update()...");
  //         transaction.update(tagihanRef, {'jumlahTerbayar': jumlahTerbayarBaru, 'status': statusBaru});
  //         print("--- DEBUG: 12. [TX] transaction.update() untuk tagihan berhasil.");

  //          if(item.tagihan.jenisPembayaran == 'Uang Pangkal') {
  //            final siswaRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('siswa').doc(uidSiswa);
  //            print("--- DEBUG: 13. [TX] Akan update dokumen siswa untuk Uang Pangkal...");
  //            transaction.update(siswaRef, {'uangPangkal.jumlahTerbayar': jumlahTerbayarBaru, 'uangPangkal.status': statusBaru});
  //            print("--- DEBUG: 14. [TX] Update dokumen siswa berhasil.");
  //          }
  //       }

  //       print("--- DEBUG: 15. [TX] Loop selesai. Akan membuat dokumen transaksi baru.");
  //       final transaksiRef = _firestore.collection('Sekolah').doc(_configC.idSekolah).collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa).collection('transaksi').doc();
  //       transaction.set(transaksiRef, {
  //         'jumlahBayar': totalDialokasikan.value,
  //         'tanggalBayar': Timestamp.now(),
  //         'metodePembayaran': "Tunai (Lumpsum)",
  //         'keterangan': keteranganTransaksi.substring(0, keteranganTransaksi.length - 2),
  //         'idTagihanTerkait': idTagihanTerkait,
  //         'dicatatOlehUid': _configC.infoUser['uid'],
  //         'dicatatOlehNama': pencatatNama,
  //       });
  //       print("--- DEBUG: 16. [TX] Dokumen transaksi berhasil dibuat dalam transaction.set().");
  //     }); // Akhir dari runTransaction

  //     print("--- DEBUG: 17. Firestore Transaction selesai sepenuhnya.");

  //       await NotifikasiService.kirimNotifikasi(
  //       uidPenerima: siswa.uid!, 
  //       judul: "Pembayaran Diterima", 
  //       isi: "Kami telah menerima pembayaran sebesar Rp ${NumberFormat.decimalPattern('id_ID').format(totalDialokasikan.value)} yang telah dialokasikan ke beberapa tagihan. Terima kasih.",
  //       tipe: 'keuangan',
  //     );

  //     Get.back();
  //     Get.snackbar("Berhasil", "Pembayaran lumpsum berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);

  //     if (Get.isRegistered<DetailKeuanganSiswaController>()) {
  //       Get.find<DetailKeuanganSiswaController>().loadInitialData();
  //     }

  //   } catch (e) {
  //     print("--- DEBUG: ERROR BLOK CATCH: ${e.toString()}");
  //     Get.snackbar("Error Transaksi", "Gagal menyimpan: ${e.toString()}", duration: const Duration(seconds: 8));
  //   } finally {
  //     isSaving.value = false;
  //     print("--- DEBUG: 18. Blok finally dieksekusi.");
  //   }
  // }
// }