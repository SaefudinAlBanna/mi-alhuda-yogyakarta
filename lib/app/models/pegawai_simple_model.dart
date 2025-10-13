// lib/app/models/pegawai_simple_model.dart (VERSI DENGAN DISPLAYNAME)
import 'package:cloud_firestore/cloud_firestore.dart';

class PegawaiSimpleModel {
  final String uid;
  final String nama;
  final String alias;
  final String? profileImageUrl;

  // --- [TAMBAHAN BARU] Getter untuk nama tampilan ---
  String get displayName => (alias.isNotEmpty && alias != 'N/A') ? alias : nama;
  // Logika: Jika alias ada isinya DAN bukan 'N/A', gunakan alias. Jika tidak, gunakan nama.

  PegawaiSimpleModel({
    required this.uid, 
    required this.nama, 
    required this.alias,
    this.profileImageUrl,
  });

  factory PegawaiSimpleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PegawaiSimpleModel(
      uid: doc.id,
      nama: data['nama'] ?? 'Tanpa Nama',
      // Pastikan alias adalah string kosong jika null, untuk keamanan getter.
      alias: data['alias'] ?? '',
      profileImageUrl: data['profileImageUrl'],
    );
  }
}