import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class BuatSarprasController extends GetxController {
  // Firestore instance
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // // Observables
  // final isLoading = false.obs;
  // final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // // TextEditingControllers
  // late TextEditingController namaBarangC;
  // late TextEditingController jumlahC;
  // late TextEditingController lokasiC;
  // late TextEditingController keteranganC;
  // late TextEditingController tanggalPengadaanC; // Untuk menampilkan tanggal terpilih

  // // Rx Variables untuk Dropdown dan DatePicker
  // final RxString selectedKondisi = "Baik".obs; // Nilai default
  // final Rx<DateTime?> selectedTanggalPengadaan = Rx<DateTime?>(null);

  // final List<String> kondisiOptions = ["Baik", "Rusak Ringan", "Rusak Berat"];

  // // Hardcode NPSN dan Tahun Ajaran untuk contoh ini
  // // Idealnya, ini didapatkan dari state global atau parameter rute
  // final String idSekolah = "P9984539";
  // // final String tahunAjaran = "2024-2025";

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
  //   namaBarangC = TextEditingController();
  //   jumlahC = TextEditingController();
  //   lokasiC = TextEditingController();
  //   keteranganC = TextEditingController();
  //   tanggalPengadaanC = TextEditingController();
  // }

  // @override
  // void onClose() {
  //   namaBarangC.dispose();
  //   jumlahC.dispose();
  //   lokasiC.dispose();
  //   keteranganC.dispose();
  //   tanggalPengadaanC.dispose();
  //   super.onClose();
  // }

  // void setSelectedKondisi(String? newValue) {
  //   if (newValue != null) {
  //     selectedKondisi.value = newValue;
  //   }
  // }

  // Future<void> pilihTanggal(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedTanggalPengadaan.value ?? DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2101),
  //   );
  //   if (picked != null && picked != selectedTanggalPengadaan.value) {
  //     selectedTanggalPengadaan.value = picked;
  //     tanggalPengadaanC.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
  //   }
  // }

  // Future<void> simpanSarpras() async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   if (formKey.currentState!.validate()) {
  //     isLoading.value = true;
  //     try {
  //       // Persiapkan data untuk Firestore
  //       Map<String, dynamic> dataSarpras = {
  //         'namaBarang': namaBarangC.text.trim(),
  //         'jumlah': int.tryParse(jumlahC.text.trim()) ?? 0,
  //         'kondisi': selectedKondisi.value,
  //         'lokasi': lokasiC.text.trim(),
  //         'tanggalPengadaan': selectedTanggalPengadaan.value != null
  //             ? Timestamp.fromDate(selectedTanggalPengadaan.value!)
  //             : null,
  //         'keterangan': keteranganC.text.trim(),
  //         'timestamp': FieldValue.serverTimestamp(), // Waktu server saat data dibuat
  //       };

  //       // Path ke koleksi sarprassekolah
  //       CollectionReference sarprasCollection = _firestore
  //           .collection('Sekolah')
  //           .doc(idSekolah)
  //           .collection('tahunajaran')
  //           .doc(idTahunAjaran)
  //           .collection('sarprassekolah');

  //       await sarprasCollection.add(dataSarpras);

  //       Get.snackbar(
  //         "Berhasil",
  //         "Data sarpras berhasil disimpan.",
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.green,
  //         colorText: Colors.white,
  //       );

  //       // Reset form atau navigasi ke halaman lain
  //       _resetForm();
  //       // Jika ingin kembali ke halaman sebelumnya: Get.back();

  //     } catch (e) {
  //       Get.snackbar(
  //         "Error",
  //         "Gagal menyimpan data: ${e.toString()}",
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     } finally {
  //       isLoading.value = false;
  //     }
  //   } else {
  //     Get.snackbar(
  //       "Perhatian",
  //       "Mohon lengkapi semua field yang wajib diisi.",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.orange,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  // void _resetForm() {
  //   namaBarangC.clear();
  //   jumlahC.clear();
  //   lokasiC.clear();
  //   keteranganC.clear();
  //   tanggalPengadaanC.clear();
  //   selectedTanggalPengadaan.value = null;
  //   selectedKondisi.value = "Baik"; // Reset ke nilai default
  //   formKey.currentState?.reset();
  // }
}