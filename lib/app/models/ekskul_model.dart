// lib/app/models/ekskul_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EkskulModel {
  final String id;
  final String namaEkskul;
  final String deskripsi;
  final String tujuan;
  final String jadwalTeks;
  final int biaya;
  // --- [DIUBAH] Ganti 'pembina' menjadi 'listPembina' ---
  final List<dynamic> listPembina;
  final Map<String, dynamic> penanggungJawab;
  final String tahunAjaran;
  final String semester;

  EkskulModel({
    required this.id, required this.namaEkskul, required this.deskripsi,
    required this.tujuan, required this.jadwalTeks, required this.biaya,
    required this.listPembina, // <-- [DIUBAH]
    required this.penanggungJawab, required this.tahunAjaran,
    required this.semester,
  });

  factory EkskulModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EkskulModel(
      id: doc.id,
      namaEkskul: data['namaEkskul'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      tujuan: data['tujuan'] ?? '',
      jadwalTeks: data['jadwalTeks'] ?? '',
      biaya: data['biaya'] ?? 0,
      // --- [DIUBAH] Ambil data dari field 'listPembina' ---
      listPembina: List<dynamic>.from(data['listPembina'] ?? []),
      penanggungJawab: Map<String, dynamic>.from(data['penanggungJawab'] ?? {}),
      tahunAjaran: data['tahunAjaran'] ?? '',
      semester: data['semester'] ?? '',
    );
  }
}