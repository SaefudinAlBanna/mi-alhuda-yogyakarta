import 'package:cloud_firestore/cloud_firestore.dart';

class BukuModel {
  final String id;
  final String namaItem;
  final String deskripsi;
  final int harga;
  final bool isPaket;
  final List<dynamic> daftarBukuDiPaket;
  final String tahunAjaran;

  BukuModel({
    required this.id,
    required this.namaItem,
    required this.deskripsi,
    required this.harga,
    required this.isPaket,
    required this.daftarBukuDiPaket,
    required this.tahunAjaran,
  });

  factory BukuModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BukuModel(
      id: doc.id,
      namaItem: data['namaItem'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      harga: (data['harga'] as num?)?.toInt() ?? 0,
      isPaket: data['isPaket'] ?? false,
      daftarBukuDiPaket: List<dynamic>.from(data['daftarBukuDiPaket'] ?? []),
      tahunAjaran: data['tahunAjaran'] ?? '',
    );
  }
}