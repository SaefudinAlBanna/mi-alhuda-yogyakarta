// lib/app/models/jurnal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JurnalModel {
  final String id;
  final String materi;
  final String catatan;
  final String? jampelajaran;
  // ... tambahkan field lain jika diperlukan nanti
  
  JurnalModel({
    required this.id, required this.materi, 
    required this.catatan, this.jampelajaran});

  factory JurnalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return JurnalModel(
      id: doc.id,
      materi: data['materi'] ?? '',
      catatan: data['catatan'] ?? '',
      jampelajaran: data['jam'] as String?,
    );
  }
}