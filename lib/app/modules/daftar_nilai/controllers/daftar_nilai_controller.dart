import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// --- MODEL DATA BARU UNTUK MENAMPUNG SETIAP NILAI ---
// class NilaiHalaqoh {
//   final String pengampu;
//   final DateTime tanggalInput;
//   final String sabaq;
//   final String nilaiSabaq;
//   final String sabqi;
//   final String nilaiSabqi;
//   final String manzil;
//   final String nilaiManzil;
//   final String tugasTambahan;
//   final String nilaiTugasTambahan;
//   final String catatanPengampu;
//   final String catatanOrangTua;

//   NilaiHalaqoh({
//     required this.pengampu,
//     required this.tanggalInput,
//     required this.sabaq,
//     required this.nilaiSabaq,
//     required this.sabqi,
//     required this.nilaiSabqi,
//     required this.manzil,
//     required this.nilaiManzil,
//     required this.tugasTambahan,
//     required this.nilaiTugasTambahan,
//     required this.catatanPengampu,
//     required this.catatanOrangTua,
//   });

//   // Factory constructor untuk membuat objek dari data Firestore
//   factory NilaiHalaqoh.fromFirestore(Map<String, dynamic> data) {
//     return NilaiHalaqoh(
//       pengampu: data['namapengampu'] ?? '-',
//       tanggalInput: DateTime.parse(data['tanggalinput']),
//       sabaq: data['suratsabaq']?.isNotEmpty == true ? data['suratsabaq'] : data['sabaq'] ?? '-',
//       nilaiSabaq: data['nilaisabaq']?.toString() ?? '-',
//       sabqi: data['suratsabqi']?.isNotEmpty == true ? data['suratsabqi'] : data['sabqi'] ?? '-',
//       nilaiSabqi: data['nilaisabqi']?.toString() ?? '-',
//       manzil: data['suratmanzil']?.isNotEmpty == true ? data['suratmanzil'] : data['manzil'] ?? '-',
//       nilaiManzil: data['nilaimanzil']?.toString() ?? '-',
//       tugasTambahan: data['tugastambahan'] ?? '-',
//       nilaiTugasTambahan: data['nilaitugastambahan']?.toString() ?? '-',
//       catatanPengampu: data['keteranganpengampu'] ?? '-',
//       catatanOrangTua: (data['keteranganorangtua'] != null && data['keteranganorangtua'] != "0") ? data['keteranganorangtua'] : '-',
//     );
//   }
// }

class DaftarNilaiController extends GetxController {
  // final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // final String idSekolah = 'P9984539';
  // final Map<String, dynamic> dataSiswa = Get.arguments;

  // // State untuk menampung hasil
  // var isLoading = true.obs;
  // var daftarNilai = <NilaiHalaqoh>[].obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   fetchDataNilai();
  // }

  // Future<void> fetchDataNilai() async {
  //   try {
  //     isLoading.value = true;
  //     String tahunAjaran = await getTahunAjaranTerakhir();
  //     String idTahunAjaran = tahunAjaran.replaceAll("/", "-");
      
  //     String fase = dataSiswa['fase'];
  //     String pengampu = dataSiswa['namapengampu'];
  //     String nisn = dataSiswa['nisn'];

  //     // Path dasar ke koleksi semester siswa
  //     CollectionReference semesterRef = firestore
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('kelompokmengaji').doc(fase)
  //         .collection('pengampu').doc(pengampu)
  //         .collection('daftarsiswa').doc(nisn)
  //         .collection('semester');

  //     // Ambil nama semester pertama yang ditemukan
  //     QuerySnapshot semesterSnapshot = await semesterRef.limit(1).get();
  //     if (semesterSnapshot.docs.isEmpty) {
  //       print("Siswa belum memiliki data semester.");
  //       daftarNilai.clear();
  //       isLoading.value = false;
  //       return;
  //     }
  //     String idSemester = semesterSnapshot.docs.first.id;

  //     // Ambil semua data nilai dari semester tersebut
  //     QuerySnapshot<Map<String, dynamic>> nilaiSnapshot = await semesterRef
  //         .doc(idSemester)
  //         .collection('nilai')
  //         .orderBy('tanggalinput', descending: true)
  //         .get();
      
  //     // Ubah data Firestore menjadi daftar objek NilaiHalaqoh
  //     daftarNilai.value = nilaiSnapshot.docs.map((doc) => NilaiHalaqoh.fromFirestore(doc.data())).toList();

  //   } catch (e, s) {
  //     print("Error fetching nilai: $e");
  //     print(s);
  //     Get.snackbar("Error", "Gagal memuat data nilai: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Future<String> getTahunAjaranTerakhir() async {
  //   QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
  //       .collection('Sekolah').doc(idSekolah)
  //       .collection('tahunajaran')
  //       .orderBy('namatahunajaran', descending: true)
  //       .limit(1).get();
  //   if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
  //   return snapshot.docs.first.data()['namatahunajaran'] as String;
  // }

  // String formatTanggal(DateTime date) {
  //   return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
  // }
}