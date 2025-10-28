import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanBkModel {
  final String id;
  final String judul;
  final String isi;
  final String pembuatId;
  final String pembuatNama;
  final DateTime tanggalDibuat;
  final String status;

  CatatanBkModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.pembuatId,
    required this.pembuatNama,
    required this.tanggalDibuat,
    required this.status,
  });

  factory CatatanBkModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CatatanBkModel(
      id: doc.id,
      judul: data['judul'] ?? 'Tanpa Judul',
      isi: data['isi'] ?? '',
      pembuatId: data['pembuatId'] ?? '',
      pembuatNama: data['pembuatNama'] ?? 'Anonim',
      tanggalDibuat: (data['tanggalDibuat'] as Timestamp).toDate(),
      status: data['status'] ?? 'Dibuka',
    );
  }
}