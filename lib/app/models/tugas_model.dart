import 'package:cloud_firestore/cloud_firestore.dart';

class TugasModel {
  final String id;
  final String judul;
  final String deskripsi;
  final String kategori; // "PR" atau "Ulangan"
  final DateTime tanggalDibuat;
  final String idMapel;
  final String idGuru;

  TugasModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.tanggalDibuat,
    required this.idMapel,
    required this.idGuru,
  });

  factory TugasModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TugasModel(
      id: doc.id,
      judul: data['judul'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      kategori: data['kategori'] ?? 'PR',
      tanggalDibuat: (data['tanggal_dibuat'] as Timestamp? ?? Timestamp.now()).toDate(),
      idMapel: data['idMapel'] ?? '',
      idGuru: data['idGuru'] ?? '',
    );
  }
}