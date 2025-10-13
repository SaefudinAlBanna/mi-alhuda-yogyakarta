import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
// import 'package:intl/intl.dart'; // Untuk format tanggal di controller jika perlu
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale jika belum di main.dart
import '../../../data/sarpras_model.dart'; // Import model Sarpras

class DataSarprasController extends GetxController {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // // Observables
  // final isLoading = true.obs; // Mulai dengan loading true
  // final RxList<SarprasModel> sarprasList = <SarprasModel>[].obs;
  // final errorMessage = ''.obs; // Untuk menampilkan pesan error
  // final isAllowedToView = false.obs; // Flag untuk hak akses

  // // --- SIMULASI DATA USER & KONTEKS ---
  // // Idealnya, ini didapatkan dari service autentikasi atau state global
  // final String currentUserJabatan = "Kepala Sekolah"; // Contoh: "Kepala Sekolah", "Guru", "Admin TU"
  // final List<String> allowedJabatan = ["Kepala Sekolah", "Wakasek Sarpras", "Admin Sarpras"]; // Jabatan yang boleh melihat

  // // Hardcode NPSN dan Tahun Ajaran untuk contoh ini
  // // Idealnya, ini didapatkan dari state global atau parameter rute
  // final String idSekolah = "P9984539";
  // // final String tahunAjaran = "2024-2025";
  // // --- AKHIR SIMULASI ---

  // Future<String> getTahunAjaranTerakhir() async {
  //   CollectionReference<Map<String, dynamic>> colTahunAjaran = _firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran');
  //   QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
  //       await colTahunAjaran.get();
  //   List<Map<String, dynamic>> listTahunAjaran =
  //       snapshotTahunAjaran.docs.map((e) => e.data()).toList();
  //   String tahunAjaranTerakhir =
  //       listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
  //   return tahunAjaranTerakhir;
  // }

  // @override
  // void onInit() {
  //   super.onInit();
  //   initializeDateFormatting('id_ID', null); // Inisialisasi locale untuk DateFormat
  //   checkAccessAndFetchData();
  // }

  // void checkAccessAndFetchData() {
  //   if (allowedJabatan.contains(currentUserJabatan)) {
  //     isAllowedToView.value = true;
  //     fetchSarprasData();
  //   } else {
  //     isAllowedToView.value = false;
  //     isLoading.value = false; // Set loading false karena tidak ada data yang akan diambil
  //     errorMessage.value = "Anda tidak memiliki hak akses untuk melihat data ini.";
  //   }
  // }

  // Future<Stream<List<SarprasModel>>> streamSarprasData() async {
  //   // Path ke koleksi sarprassekolah
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   CollectionReference sarprasCollectionRef = _firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('sarprassekolah');

  //   return sarprasCollectionRef
  //       .orderBy('timestamp', descending: true) // Urutkan berdasarkan timestamp terbaru
  //       .snapshots()
  //       .map((querySnapshot) {
  //     if (querySnapshot.docs.isEmpty) {
  //       return <SarprasModel>[]; // Kembalikan list kosong jika tidak ada dokumen
  //     }
  //     return querySnapshot.docs
  //         .map((doc) =>
  //             SarprasModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
  //         .toList();
  //   }).handleError((error) {
  //     print("Error streaming data sarpras: $error");
  //     errorMessage.value = "Terjadi kesalahan saat mengambil data: ${error.toString()}";
  //     return <SarprasModel>[]; // Kembalikan list kosong jika error
  //   });
  // }


  // Future<void> fetchSarprasData() async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   isLoading.value = true;
  //   errorMessage.value = ''; // Reset error message

  //   // Path ke koleksi sarprassekolah
  //   CollectionReference sarprasCollectionRef = _firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('sarprassekolah');

  //   // Menggunakan stream untuk data real-time
  //   // Jika hanya ingin sekali fetch, gunakan .get()
  //   sarprasCollectionRef
  //       .orderBy('timestamp', descending: true) // Urutkan berdasarkan timestamp terbaru
  //       .snapshots() // Ini akan memberikan update real-time
  //       .listen((QuerySnapshot querySnapshot) {
  //     if (querySnapshot.docs.isEmpty) {
  //       sarprasList.clear(); // Kosongkan list jika tidak ada data
  //       // errorMessage.value = "Belum ada data sarpras."; // Opsional: pesan jika kosong
  //     } else {
  //       sarprasList.value = querySnapshot.docs
  //           .map((doc) =>
  //               SarprasModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
  //           .toList();
  //     }
  //     isLoading.value = false;
  //   }, onError: (error) {
  //     print("Error fetching data sarpras: $error");
  //     errorMessage.value = "Terjadi kesalahan saat mengambil data: ${error.toString()}";
  //     isLoading.value = false;
  //   });
  // }

  // // Fungsi untuk refresh data (jika diperlukan untuk pull-to-refresh)
  // Future<void> refreshData() async {
  //   if (isAllowedToView.value) {
  //     fetchSarprasData(); // Cukup panggil fetchSarprasData lagi
  //   }
  // }

  // // Jika Anda memiliki halaman BuatSarpras, bisa tambahkan navigasi ke sana
  // void goToBuatSarpras() {
  //   Get.toNamed('/buat-sarpras'); // Sesuaikan dengan nama rute Anda
  // }
}