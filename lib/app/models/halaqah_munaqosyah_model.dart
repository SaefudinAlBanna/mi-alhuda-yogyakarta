// lib/app/models/halaqah_munaqosyah_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk merepresentasikan satu entri riwayat ujian/munaqosyah.
class HalaqahMunaqosyahModel {
  final String id;
  final DateTime tanggalUjian;
  final String materiUjian;
  final String idPenguji;
  final String namaPenguji;
  final String hasil; // "Lulus", "Belum Lulus", "Dijadwalkan"
  final int nilai;
  final String catatanPenguji;

  HalaqahMunaqosyahModel({
    required this.id,
    required this.tanggalUjian,
    required this.materiUjian,
    required this.idPenguji,
    required this.namaPenguji,
    required this.hasil,
    required this.nilai,
    required this.catatanPenguji,
  });

  factory HalaqahMunaqosyahModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahMunaqosyahModel(
      id: doc.id,
      tanggalUjian: (data['tanggalUjian'] as Timestamp?)?.toDate() ?? DateTime.now(),
      materiUjian: data['materiUjian'] ?? 'Tanpa Keterangan',
      idPenguji: data['idPenguji'] ?? '',
      namaPenguji: data['namaPenguji'] ?? '',
      hasil: data['hasil'] ?? 'Dijadwalkan',
      nilai: data['nilai'] ?? 0,
      catatanPenguji: data['catatanPenguji'] ?? '',
    );
  }
}