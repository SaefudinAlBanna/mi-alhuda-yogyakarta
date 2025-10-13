// lib/app/models/nilai_harian_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NilaiHarianModel {
  final String id;
  final String kategori;
  final int nilai;
  final String catatan;
  final DateTime tanggal;
  
  // [TAMBAHAN BARU] Field-field ini krusial untuk query dan filtering
  final String? idMapel;
  final String? kelasId;
  final int? semester;

  NilaiHarianModel({
    required this.id,
    required this.kategori,
    required this.nilai,
    required this.catatan,
    required this.tanggal,
    this.idMapel,
    this.kelasId,
    this.semester,
  });

  factory NilaiHarianModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NilaiHarianModel(
      id: doc.id,
      kategori: data['kategori'] ?? 'Lainnya',
      nilai: (data['nilai'] as num?)?.toInt() ?? 0,
      catatan: data['catatan'] ?? '',
      tanggal: (data['tanggal'] as Timestamp? ?? Timestamp.now()).toDate(),
      // Baca data baru dari Firestore
      idMapel: data['idMapel'] as String?,
      kelasId: data['kelasId'] as String?,
      semester: (data['semester'] as num?)?.toInt(),
    );
  }
}