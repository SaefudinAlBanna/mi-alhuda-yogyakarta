// controllers/tampilkan_info_sekolah_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart'; // PENTING: Pastikan path ini benar

class TampilkanInfoSekolahController extends GetxController {
  // final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // // --- STATE BARU UNTUK FILTERING ---
  // late final TextEditingController searchC;
  // final RxList<DocumentSnapshot<Map<String, dynamic>>> _allInfoList = <DocumentSnapshot<Map<String, dynamic>>>[].obs;
  // final RxList<DocumentSnapshot<Map<String, dynamic>>> filteredInfoList = <DocumentSnapshot<Map<String, dynamic>>>[].obs;

  // // --- STATE LAMA ---
  // final RxBool isLoading = true.obs;
  // final String idSekolah = "P9984539";
  // String? idTahunAjaran;

  // @override
  // void onInit() {
  //   super.onInit();
  //   searchC = TextEditingController();
  //   // Tambahkan listener untuk memfilter secara otomatis saat user mengetik
  //   searchC.addListener(() {
  //     _filterInfo(searchC.text);
  //   });
  //   fetchInfoSekolah();
  // }

  // @override
  // void onClose() {
  //   searchC.dispose();
  //   super.onClose();
  // }

  // Future<void> _getTahunAjaranTerakhir() async {
  //   try {
  //     final snapshot = await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('tahunajaran')
  //         .orderBy('namatahunajaran', descending: true)
  //         .limit(1)
  //         .get();
      
  //     if (snapshot.docs.isNotEmpty) {
  //       String tahunAjaranTerakhir = snapshot.docs.first.data()['namatahunajaran'];
  //       idTahunAjaran = tahunAjaranTerakhir.replaceAll("/", "-");
  //     } else {
  //       // Handle jika tidak ada tahun ajaran sama sekali
  //       Get.snackbar("Error Kritis", "Data Tahun Ajaran tidak ditemukan.");
  //     }
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal mendapatkan data tahun ajaran: $e");
  //   }
  // }

  // Future<void> fetchInfoSekolah({bool isRefresh = false}) async {
  //   if (!isRefresh) isLoading.value = true;
    
  //   try {
  //     await _getTahunAjaranTerakhir();
  //     if (idTahunAjaran == null) throw Exception("Tahun ajaran tidak ditemukan.");

  //     final snapshot = await firestore
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('informasisekolah')
  //         .orderBy('tanggalinput', descending: true)
  //         .get();
      
  //     // Simpan data asli ke _allInfoList
  //     _allInfoList.value = snapshot.docs;
  //     // Salin semua data ke filteredInfoList untuk tampilan awal
  //     filteredInfoList.value = _allInfoList;

  //   } catch (e) {
  //     Get.snackbar('Error', 'Gagal memuat informasi: $e');
  //   } finally {
  //     if (!isRefresh) isLoading.value = false;
  //   }
  // }

  // /// FUNGSI BARU: Untuk memfilter daftar informasi
  // void _filterInfo(String query) {
  //   if (query.isEmpty) {
  //     // Jika search kosong, tampilkan semua data
  //     filteredInfoList.value = _allInfoList;
  //   } else {
  //     // Jika ada input, filter berdasarkan judul atau nama penginput
  //     final lowerCaseQuery = query.toLowerCase();
  //     filteredInfoList.value = _allInfoList.where((doc) {
  //       final data = doc.data()!;
  //       final judul = (data['judulinformasi'] as String? ?? '').toLowerCase();
  //       final penulis = (data['namapenginput'] as String? ?? '').toLowerCase();
        
  //       return judul.contains(lowerCaseQuery) || penulis.contains(lowerCaseQuery);
  //     }).toList();
  //   }
  // }

  // /// FUNGSI BARU: Untuk navigasi ke halaman detail
  // void goToDetail(DocumentSnapshot<Map<String, dynamic>> infoDoc) {
  //   Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: infoDoc.data());
  // }
}
