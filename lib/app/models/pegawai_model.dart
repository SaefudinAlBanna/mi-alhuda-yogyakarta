// lib/app/models/pegawai_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_alhuda_yogyakarta/app/enums/user_role_enum.dart';

class PegawaiModel {
  final String uid;
  final String nama;
  final String? alias; // <-- PASTIKAN INI ADA
  final UserRole role;
  final String? profileImageUrl;

  PegawaiModel({
    required this.uid,
    required this.nama,
    this.alias, // <-- PASTIKAN INI ADA
    required this.role,
    this.profileImageUrl,
  });

  factory PegawaiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PegawaiModel(
      uid: doc.id,
      nama: data['nama'] ?? 'Tanpa Nama',
      alias: data['alias'] as String?, // <-- PASTIKAN INI ADA
      role: UserRole.fromString(data['role'] as String?),
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }
}