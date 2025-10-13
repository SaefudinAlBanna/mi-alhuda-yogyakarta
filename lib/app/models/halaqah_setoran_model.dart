// lib/app/models/halaqah_setoran_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HalaqahSetoranModel {
  final String id;
  final String status;
  final Timestamp tanggalTugas;
  final Timestamp? tanggalDinilai;
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> nilai;
  final String catatanPengampu;
  final String catatanOrangTua;

  HalaqahSetoranModel({
    required this.id, required this.status, required this.tanggalTugas,
    this.tanggalDinilai, required this.tugas, required this.nilai,
    required this.catatanPengampu, required this.catatanOrangTua,
  });

  factory HalaqahSetoranModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahSetoranModel(
      id: doc.id,
      status: data['status'] ?? 'Selesai',
      tanggalTugas: data['tanggalTugas'] ?? Timestamp.now(),
      tanggalDinilai: data['tanggalDinilai'],
      tugas: Map<String, dynamic>.from(data['tugas'] ?? {}),
      nilai: Map<String, dynamic>.from(data['nilai'] ?? {}),
      catatanPengampu: data['catatanPengampu'] ?? '',
      catatanOrangTua: data['catatanOrangTua'] ?? '',
    );
  }
}