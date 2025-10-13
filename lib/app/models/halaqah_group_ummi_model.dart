// lib/app/models/halaqah_group_ummi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk merepresentasikan sebuah grup Halaqah Ummi.
/// Digunakan di halaman manajemen grup dan dashboard pengampu.
class HalaqahGroupUmmiModel {
  final String id;
  final String namaGrup;
  final String fase;
  final String idPengampu;
  final String namaPengampu;
  final String lokasiDefault;

  // Properti ini hanya untuk UI, di-set secara manual di controller
  bool isPengganti; 

  HalaqahGroupUmmiModel({
    required this.id,
    required this.namaGrup,
    required this.fase,
    required this.idPengampu,
    required this.namaPengampu,
    required this.lokasiDefault,
    this.isPengganti = false,
  });

  factory HalaqahGroupUmmiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahGroupUmmiModel(
      id: doc.id,
      namaGrup: data['namaGrup'] ?? 'Tanpa Nama Grup',
      fase: data['fase'] ?? 'N/A',
      idPengampu: data['idPengampu'] ?? '',
      namaPengampu: data['namaPengampu'] ?? 'Belum Ditentukan',
      lokasiDefault: data['lokasiDefault'] ?? 'Belum Ditentukan',
    );
  }
}