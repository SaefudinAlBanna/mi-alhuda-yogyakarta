// lib/app/models/absensi_rekap_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiRekapModel {
  final Timestamp tanggal;
  final Map<String, dynamic> rekap;
  final Map<String, dynamic> siswa;
  final String? namaWaliKelas; // [BARU] Tambahkan properti ini

  AbsensiRekapModel({
    required this.tanggal,
    required this.rekap,
    required this.siswa,
    this.namaWaliKelas, // [BARU] Tambahkan ke constructor
  });

  factory AbsensiRekapModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final tanggal = data['tanggal'] as Timestamp? ?? Timestamp.now();
    final rekap = data['rekap'] as Map<String, dynamic>? ?? {};
    final namaWaliKelas = data['namaWaliKelas'] as String?; // [BARU] Baca field ini

    final Map<String, dynamic> siswaMap = {};
    data.forEach((key, value) {
      if (value is Map && key != 'rekap') {
        siswaMap[key] = value as Map<String, dynamic>;
      }
    });

    return AbsensiRekapModel(
      tanggal: tanggal,
      rekap: rekap,
      siswa: siswaMap,
      namaWaliKelas: namaWaliKelas, // [BARU] Kirim data ke constructor
    );
  }
}