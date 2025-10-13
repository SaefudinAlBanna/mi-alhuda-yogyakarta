// lib/app/models/siswa_simple_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaSimpleModel {
  final String uid;
  final String nama;
  final String kelasId;
  final String? fotoProfilUrl;

  // [PENAMBAHAN] Properti untuk menampung data progresi
  // Dibuat non-final agar bisa diubah di controller
  String tingkat;
  String detailTingkat;

  SiswaSimpleModel({
    required this.uid,
    required this.nama,
    required this.kelasId,
    this.fotoProfilUrl,
    required this.tingkat,    // Tambahkan ke constructor
    required this.detailTingkat, // Tambahkan ke constructor
  });

  factory SiswaSimpleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Ambil data progres dari map 'halaqahUmmi'
    final progres = data['halaqahUmmi']?['progres'] as Map<String, dynamic>?;

    return SiswaSimpleModel(
      uid: doc.id,
      nama: data['namaLengkap'] ?? data['namasiswa'] ?? 'Tanpa Nama',
      kelasId: data['kelasId'] ?? 'N/A',
      fotoProfilUrl: data['fotoProfilUrl'],
      // Set nilai dari Firestore, atau berikan default jika tidak ada
      tingkat: progres?['tingkat']?.toString() ?? 'Jilid',
      detailTingkat: progres?['detailTingkat']?.toString() ?? '1',
    );
  }
}