// lib/app/modules/pembayaran_spp/controllers/pembayaran_spp_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class PembayaranSppController extends GetxController {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final String idSekolah = "P9984539";
//   String? idTahunAjaran;

//   // --- State Utama ---
//  var isPageLoading = true.obs;
//   var isKelasLoading = false.obs;
//   Rxn<String> selectedKelasId = Rxn<String>();
//   var selectedKelasNama = ''.obs;
//   var daftarKelas = <Map<String, dynamic>>[].obs;
//   var daftarJenisPembayaran = <String>[].obs;
//   var jenisPembayaranTerpilih = ''.obs;
//   var riwayatPembayaran = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
//   var isRiwayatLoading = false.obs;
//   var nominalTagihanSiswa = 0.obs;
//   var sisaTagihanSiswa = 0.obs;
//   var selectedBulanList = <String>[].obs;
  
//   final nominalController = TextEditingController();
//   final keteranganController = TextEditingController();
//   final sppTotalController = TextEditingController();

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeData();
//   }

//   Future<void> _initializeData() async {
//     isPageLoading.value = true;
//     try {
//       await Future.wait([_initTahunAjaran(), _fetchJenisPembayaran()]);
//       await getDaftarKelas();
//     } catch (e) {
//       Get.snackbar("Error Kritis", "Gagal memuat data awal: ${e.toString().replaceAll("Exception: ", "")}");
//     } finally {
//       isPageLoading.value = false;
//     }
//   }

//   // FUNGSI HELPER BARU
// Future<String> _getNamaPetugas() async {
//   try {
//     // 1. Ambil email user yang sedang login
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       return 'Tanpa Nama'; // Fallback jika tidak ada user login
//     }

//     // 2. Ambil dokumen pegawai berdasarkan email
//     final docSnapshot = await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('pegawai')
//         .doc(uid)
//         .get();

//     // 3. Jika dokumen ada, format nama dan role
//     if (docSnapshot.exists && docSnapshot.data() != null) {
//       final data = docSnapshot.data()!;
//       final nama = data['alias'] as String?;
//       final role = data['role'] as String?;

//       if (nama != null && role != null) {
//         return '$nama ($role)'; // Hasil: "Budi Santoso (Admin Keuangan)"
//       } else if (nama != null) {
//         return nama; // Fallback jika hanya ada nama
//       }
//     }
    
//     // 4. Jika dokumen tidak ada, kembalikan email sebagai default
//     return uid;
//   } catch (e) {
//     // Jika terjadi error, kembalikan email agar proses tidak gagal
//     return FirebaseAuth.instance.currentUser?.email ?? 'Error Petugas';
//   }
// }

//   Future<void> _initTahunAjaran() async {
//     final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get();
//     if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
//     idTahunAjaran = snapshot.docs.first.id;
//   }
  
//   Future<void> _fetchJenisPembayaran() async {
//     final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('konfigurasi').doc('pembayaran').get();
//     if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('jenisPembayaranLain')) {
//       List<String> jenis = List<String>.from(snapshot.data()!['jenisPembayaranLain']);
//       jenis.add("SPP");
//       jenis.sort();
//       daftarJenisPembayaran.value = jenis;
//     } else {
//       daftarJenisPembayaran.value = ['SPP', 'Daftar Ulang', 'Iuran Pangkal', 'Kegiatan', 'Seragam', 'UPK ASPD'];
//     }
//   }

//   // --- LOGIKA BARU UNTUK BOTTOM SHEET ---
//    void resetBottomSheetState() {
//     jenisPembayaranTerpilih.value = '';
//     riwayatPembayaran.clear();
//     clearDetailPembayaranForm();
//   }


//   Future<void> onJenisPembayaranChanged(String? value, String idSiswa) async {
//     jenisPembayaranTerpilih.value = value ?? '';
//     if (value == null || value.isEmpty) {
//       riwayatPembayaran.clear();
//       return;
//     }

//     isRiwayatLoading.value = true;
//     try {
//       final snapshot = await _getDataPembayaran(idSiswa).first;
//       riwayatPembayaran.value = snapshot.docs;
//       await getTagihanSiswa(idSiswa);
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat riwayat: ${e.toString()}");
//     } finally {
//       isRiwayatLoading.value = false;
//     }
//   }

//   // --- FIX UTAMA DI CONTROLLER ---
//   Stream<QuerySnapshot<Map<String, dynamic>>> _getDataPembayaran(String idsiswa) {
//     final jenis = jenisPembayaranTerpilih.value;
//     if (jenis.isEmpty || idTahunAjaran == null || selectedKelasId.value == null) {
//       return Stream.empty();
//     }

//     final Query<Map<String, dynamic>> query;
//     final basePath = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(selectedKelasId.value).collection('daftarsiswa').doc(idsiswa);

//     if (jenis == "SPP") {
//       query = basePath.collection('SPP');
//     } else {
//       query = basePath.collection('PembayaranLain').where('jenis', isEqualTo: jenis);
//     }

//     // Gunakan withConverter untuk memastikan tipe data yang benar
//     return query.withConverter<Map<String, dynamic>>(
//       fromFirestore: (snapshot, _) => snapshot.data()!,
//       toFirestore: (map, _) => map,
//     ).snapshots();
//   }


//   Future<void> getTagihanSiswa(String idSiswa) async {
//     nominalTagihanSiswa.value = 0;
//     sisaTagihanSiswa.value = 0;
//     nominalController.clear();
    
//     final jenis = jenisPembayaranTerpilih.value;
//     if (jenis.isEmpty) return;

//     try {
//       if (jenis == "SPP") {
//         final doc = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(idSiswa).get();
//         nominalTagihanSiswa.value = (doc.data()?['SPP'] as num?)?.toInt() ?? 0;
//         sisaTagihanSiswa.value = nominalTagihanSiswa.value;
//       } else {
//         final doc = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('biaya').doc(jenis).get();
//         final nominalTagihan = (doc.data()?['nominal'] as num?)?.toInt() ?? 0;
//         nominalTagihanSiswa.value = nominalTagihan;

//         int totalSudahBayar = 0;
//         for (var trx in riwayatPembayaran) {
//             totalSudahBayar += (trx.data()['nominal'] as num?)?.toInt() ?? 0;
//         }
//         int sisa = nominalTagihan - totalSudahBayar;
//         sisaTagihanSiswa.value = sisa > 0 ? sisa : 0;
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal mengambil data tagihan: ${e.toString()}");
//     }
//   }
  
//   Future<void> simpanPembayaran(String idSiswa) async {
//     final jenis = jenisPembayaranTerpilih.value;
//     if (jenis.isEmpty) { Get.snackbar("Error", "Jenis pembayaran belum dipilih."); return; }
//     if (idTahunAjaran == null || selectedKelasId.value == null) { Get.snackbar("Error", "Kelas/Tahun Ajaran tidak valid."); return; }

//     // final String emailAdmin = auth.currentUser!.email!;
//     WriteBatch batch = firestore.batch();

//     try {
//       Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
//        // PANGGIL FUNGSI HELPER DI SINI
//     final String namaPetugas = await _getNamaPetugas();
      
//       final basePath = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(selectedKelasId.value).collection('daftarsiswa').doc(idSiswa);

//       if (jenis == "SPP") {
//         if (selectedBulanList.isEmpty) throw Exception("Bulan SPP belum dipilih.");
//         if (nominalTagihanSiswa.value <= 0) throw Exception("Nominal SPP untuk siswa ini belum diatur (Rp 0).");
        
//         final sppCollectionRef = basePath.collection('SPP');
//         for (String bulan in selectedBulanList) {
//           final docRef = sppCollectionRef.doc(bulan);
//           batch.set(docRef, { 'tglbayar': Timestamp.now(), 'petugas': namaPetugas, 'nominal': nominalTagihanSiswa.value });
//         }
//       } else {
//         final nominal = int.tryParse(nominalController.text);
//         if (nominal == null || nominal <= 0) throw Exception("Nominal tidak valid.");
//         if (keteranganController.text.isEmpty) throw Exception("Keterangan wajib diisi.");

//         final bayarLainCollectionRef = basePath.collection('PembayaranLain');
//         final docRef = bayarLainCollectionRef.doc();
//         batch.set(docRef, { 'jenis': jenis, 'tglbayar': Timestamp.now(), 'petugas': namaPetugas, 'nominal': nominal, 'keterangan': keteranganController.text });
//       }
      
//       await batch.commit();
//       Get.back(); // tutup loading
//       Get.back(); // tutup bottom sheet
//       Get.snackbar("Sukses", "Pembayaran $jenis berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
//     } catch (e) {
//       Get.back();
//       Get.snackbar("Error", "Gagal menyimpan: ${e.toString().replaceAll("Exception: ", "")}");
//     }
//   }

//   void clearDetailPembayaranForm() {
//     selectedBulanList.clear();
//     sppTotalController.clear();
//     keteranganController.clear();
//     nominalController.clear();
//   }

//   Future<void> getDaftarKelas() async {
//     try {
//       isKelasLoading.value = true;
//       if (idTahunAjaran == null) return;
//       var querySnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').orderBy('namakelas').get();
//       if (querySnapshot.docs.isNotEmpty) {
//         daftarKelas.value = querySnapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namakelas'] as String}).toList();
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat daftar kelas.");
//     } finally {
//       isKelasLoading.value = false;
//     }
//   }

//   Future<QuerySnapshot<Map<String, dynamic>>> getDataSiswa() async {
//     if (selectedKelasId.value == null || idTahunAjaran == null) return Future.error("Kelas atau Tahun Ajaran belum siap.");
//     return firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(selectedKelasId.value).collection('daftarsiswa').orderBy('namasiswa').get();
//   }
  
//   List<String> getListBulan() => ['Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni'];
//   String formatRupiah(int number) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
}