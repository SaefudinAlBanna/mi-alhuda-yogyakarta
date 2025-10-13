// lib/app/services/notifikasi_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';

class NotifikasiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Ambil idSekolah dari ConfigController yang sudah permanent
  static final String _idSekolah = Get.find<ConfigController>().idSekolah;

  static Future<void> kirimNotifikasi({
    required String uidPenerima,
    required String judul,
    required String isi,
    required String tipe, // 'keuangan', 'komite', 'akademik', 'info', dll.
  }) async {
    try {
      final siswaDocRef = _firestore
          .collection('Sekolah').doc(_idSekolah)
          .collection('siswa').doc(uidPenerima);

      final notifRef = siswaDocRef.collection('notifikasi').doc();
      final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');

      final batch = _firestore.batch();

      // Buat dokumen notifikasi baru
      batch.set(notifRef, {
        'judul': judul,
        'isi': isi,
        'tipe': tipe,
        'isDibaca': false,
        'tanggal': FieldValue.serverTimestamp(),
      });

      // Tambah counter notifikasi yang belum dibaca
      batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));

      await batch.commit();
      print("✅ Notifikasi terkirim ke $uidPenerima: $judul");

    } catch (e) {
      print("❌ Gagal mengirim notifikasi ke $uidPenerima: $e");
    }
  }
}