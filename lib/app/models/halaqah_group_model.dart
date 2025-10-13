// lib/app/models/halaqah_group_model.dart



import 'package:cloud_firestore/cloud_firestore.dart';

class HalaqahGroupModel {
  final String id;
  final String namaGrup;
  final String idPengampu;
  final String namaPengampu;
  final String aliasPengampu;
  final String semester;
  final String? profileImageUrl;
  bool isPengganti; 

  HalaqahGroupModel({
    required this.id,
    required this.namaGrup,
    required this.idPengampu,
    required this.namaPengampu,
    required this.aliasPengampu,
    required this.semester,
    this.profileImageUrl,
    this.isPengganti = false, 
  });

  factory HalaqahGroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahGroupModel(
      id: doc.id,
      namaGrup: data['namaGrup'] ?? 'Tanpa Nama Grup',
      idPengampu: data['idPengampu'] ?? '',
      namaPengampu: data['namaPengampu'] ?? 'Belum ada pengampu',
      aliasPengampu: data['aliasPengampu'] ?? 'N/A',
      semester: data['semester'] ?? 'N/A',
      profileImageUrl: data['profileImageUrl'],
    );
  }
}