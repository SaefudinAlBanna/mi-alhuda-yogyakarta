// lib/app/models/siswa_keuangan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaKeuanganModel {
  final String uid;
  final String namaLengkap;
  final String? kelasId;
  final int spp;
  final int uangPangkalDitetapkan; // Tambahkan ini

  SiswaKeuanganModel({
    required this.uid,
    required this.namaLengkap,
    this.kelasId,
    required this.spp,
    required this.uangPangkalDitetapkan,
  });

  factory SiswaKeuanganModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    int pangkal = 0;
    if (data.containsKey('uangPangkal') && data['uangPangkal'] is Map) {
      pangkal = (data['uangPangkal']['totalTagihan'] as num?)?.toInt() ?? 0;
    }
    
    return SiswaKeuanganModel(
      uid: doc.id,
      namaLengkap: data['namaLengkap'] ?? 'Tanpa Nama',
      kelasId: data['kelasId'],
      spp: (data['spp'] as num?)?.toInt() ?? 0,
      uangPangkalDitetapkan: pangkal,
    );
  }
}