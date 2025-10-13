import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

class HalaqahRiwayatPengampuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  late SiswaSimpleModel siswa;

  @override
  void onInit() {
    super.onInit();
    siswa = Get.arguments as SiswaSimpleModel;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayat() {
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(siswa.uid)
        .collection('halaqah_nilai')
        .orderBy('tanggalTugas', descending: true)
        .snapshots();
  }

  void editCatatanPengampu(String setoranId, String catatanAwal) {
    // Pisahkan catatan asli dari footnote lama (jika ada) untuk diedit
    final footnoteMarker = "\n\n(Diubah oleh";
    String catatanAsli = catatanAwal;
    if (catatanAwal.contains(footnoteMarker)) {
      catatanAsli = catatanAwal.substring(0, catatanAwal.indexOf(footnoteMarker));
    }

    final catatanC = TextEditingController(text: catatanAsli);
    
    Get.defaultDialog(
      title: "Edit Catatan Pengampu",
      content: TextField(
        controller: catatanC,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Tulis catatan...",
        ),
      ),
      textCancel: "Batal",
      textConfirm: "Simpan",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); // Tutup dialog

        // Buat footnote baru
        final namaPengedit = configC.infoUser['alias'] ?? 'Admin';
        final tanggalEdit = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
        final footnote = "$footnoteMarker $namaPengedit pada $tanggalEdit)";

        // Gabungkan catatan baru dengan footnote
        final catatanFinal = "${catatanC.text.trim()}$footnote";

        try {
          // Update field di Firestore
          await _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('siswa').doc(siswa.uid)
              .collection('halaqah_nilai').doc(setoranId)
              .update({'catatanPengampu': catatanFinal});
          
          Get.snackbar("Berhasil", "Catatan telah diperbarui.");
        } catch (e) {
          Get.snackbar("Error", "Gagal memperbarui catatan: $e");
        }
      },
    );
  }
}