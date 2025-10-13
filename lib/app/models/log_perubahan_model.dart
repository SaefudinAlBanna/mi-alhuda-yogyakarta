// lib/app/models/log_perubahan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LogPerubahanModel {
  final String id;
  final DateTime timestamp;
  final String alasan;
  final String? catatan;
  final String idSiswa;
  final String namaSiswa;
  final int nominalLama;
  final int nominalBaru;
  final Map<String, dynamic> diubahOleh;

  LogPerubahanModel({
    required this.id,
    required this.timestamp,
    required this.alasan,
    this.catatan,
    required this.idSiswa,
    required this.namaSiswa,
    required this.nominalLama,
    required this.nominalBaru,
    required this.diubahOleh,
  });

  factory LogPerubahanModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LogPerubahanModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      alasan: data['alasan'] ?? 'Tanpa Alasan',
      catatan: data['catatan'],
      idSiswa: data['idSiswa'] ?? '',
      namaSiswa: data['namaSiswa'] ?? 'Tanpa Nama',
      nominalLama: (data['nominalLama'] as num?)?.toInt() ?? 0,
      nominalBaru: (data['nominalBaru'] as num?)?.toInt() ?? 0,
      diubahOleh: data['diubahOleh'] as Map<String, dynamic>? ?? {},
    );
  }
}