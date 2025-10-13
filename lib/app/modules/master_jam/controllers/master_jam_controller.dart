// lib/app/modules/master_jam/controllers/master_jam_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class MasterJamController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final TextEditingController namaC = TextEditingController();
  final Rx<TimeOfDay?> jamMulai = Rxn<TimeOfDay>();
  final Rx<TimeOfDay?> jamSelesai = Rxn<TimeOfDay>();
  
  Stream<QuerySnapshot<Map<String, dynamic>>> streamJamPelajaran() {
    return _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').orderBy('urutan').snapshots();
  }

  Future<void> _reorderAllJamPelajaran() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').get();
    if (snapshot.docs.isEmpty) return;

    var docs = snapshot.docs;
    // Perbaikan kecil: Pastikan data 'jamMulai' ada sebelum di-sort
    docs.sort((a, b) => (a.data()['jamMulai'] as String? ?? '00:00').compareTo(b.data()['jamMulai'] as String? ?? '00:00'));

    final batch = _firestore.batch();
    for (int i = 0; i < docs.length; i++) {
      batch.update(docs[i].reference, {'urutan': i + 1});
    }
    await batch.commit();
  }

  Future<void> pilihWaktu(BuildContext context, {required bool isMulai}) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      if (isMulai) { jamMulai.value = picked; } else { jamSelesai.value = picked; }
    }
  }

  // --- FUNGSI "PENJAGA" BARU UNTUK VALIDASI BENTROK ---
  Future<String?> _isWaktuBentrok(TimeOfDay mulaiBaru, TimeOfDay selesaiBaru, {String? docIdToIgnore}) async {
    final mulaiBaruInMinutes = mulaiBaru.hour * 60 + mulaiBaru.minute;
    final selesaiBaruInMinutes = selesaiBaru.hour * 60 + selesaiBaru.minute;

    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').get();

    for (final doc in snapshot.docs) {
      // Lewati dokumen ini jika kita sedang dalam mode edit dan ID-nya sama
      if (doc.id == docIdToIgnore) {
        continue;
      }

      final data = doc.data();
      final String jamMulaiStr = data['jamMulai'];
      final String jamSelesaiStr = data['jamSelesai'];

      final mulaiLamaInMinutes = int.parse(jamMulaiStr.split(':')[0]) * 60 + int.parse(jamMulaiStr.split(':')[1]);
      final selesaiLamaInMinutes = int.parse(jamSelesaiStr.split(':')[0]) * 60 + int.parse(jamSelesaiStr.split(':')[1]);

      // Formula pengecekan tumpang tindih (overlap)
      if (mulaiBaruInMinutes < selesaiLamaInMinutes && mulaiLamaInMinutes < selesaiBaruInMinutes) {
        return data['namaKegiatan'] as String?; // Bentrok ditemukan!
      }
    }

    return null; // Aman, tidak ada bentrok
  }

  // --- FUNGSI SIMPAN YANG TELAH DIPERKUAT ---
  Future<void> simpanJam({String? docId}) async {
    // 1. Validasi Input Dasar
    if (namaC.text.isEmpty || jamMulai.value == null || jamSelesai.value == null) {
      Get.snackbar("Input Tidak Lengkap", "Semua field wajib diisi.");
      return;
    }
    
    // 2. Validasi Logika Waktu
    final mulai = jamMulai.value!;
    final selesai = jamSelesai.value!;
    if ((selesai.hour * 60 + selesai.minute) <= (mulai.hour * 60 + mulai.minute)) {
      Get.snackbar("Logika Waktu Salah", "Jam Selesai harus setelah Jam Mulai.");
      return;
    }

    // 3. Validasi Anti-Bentrok (Memanggil "Penjaga" baru kita)
    final bentrokDengan = await _isWaktuBentrok(mulai, selesai, docIdToIgnore: docId);
    if (bentrokDengan != null) {
      Get.snackbar("Jadwal Bentrok", "Waktu yang Anda masukkan tumpang tindih dengan '$bentrokDengan'.",
        backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 4));
      return;
    }
    
    // --- Jika semua validasi lolos, lanjutkan proses simpan ---
    final formatWaktu = (TimeOfDay time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final dataToSave = {
      'namaKegiatan': namaC.text.trim(),
      'jamMulai': formatWaktu(mulai),
      'jamSelesai': formatWaktu(selesai),
      'jampelajaran': '${formatWaktu(mulai)} - ${formatWaktu(selesai)}',
    };

    try {
      if (docId == null) {
        await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').add(dataToSave);
      } else {
        await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').doc(docId).update(dataToSave);
      }
      await _reorderAllJamPelajaran(); // Urutkan kembali setelah ada perubahan
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Data jam pelajaran berhasil disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: $e");
    }
  }

  Future<void> hapusJam(String docId) async {
    try {
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').doc(docId).delete();
      await _reorderAllJamPelajaran(); // Urutkan kembali setelah ada yang dihapus
      Get.back(); // Tutup dialog konfirmasi
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus data: $e");
    }
  }
}