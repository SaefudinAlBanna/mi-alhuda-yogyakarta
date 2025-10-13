// lib/app/models/tugas_simple_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TugasSimpleModel {
  final String id;
  final String judul;
  final String kategori;
  final DateTime tanggalDibuat;

  TugasSimpleModel({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.tanggalDibuat,
  });

  factory TugasSimpleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TugasSimpleModel(
      id: doc.id,
      judul: data['judul'] ?? 'Tanpa Judul',
      kategori: data['kategori'] ?? 'Lainnya',
      tanggalDibuat: (data['tanggal_dibuat'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}