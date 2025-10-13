import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  final String id;
  final int jumlahBayar;
  final DateTime tanggalBayar;
  final String metodePembayaran;
  final String keterangan;
  final List<dynamic> idTagihanTerkait;
  final String dicatatOlehNama;

  TransaksiModel({
    required this.id,
    required this.jumlahBayar,
    required this.tanggalBayar,
    required this.metodePembayaran,
    required this.keterangan,
    required this.idTagihanTerkait,
    required this.dicatatOlehNama,
  });

  factory TransaksiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TransaksiModel(
      id: doc.id,
      jumlahBayar: (data['jumlahBayar'] as num?)?.toInt() ?? 0,
      tanggalBayar: (data['tanggalBayar'] as Timestamp? ?? Timestamp.now()).toDate(),
      metodePembayaran: data['metodePembayaran'] ?? 'N/A',
      keterangan: data['keterangan'] ?? '',
      idTagihanTerkait: data['idTagihanTerkait'] as List<dynamic>? ?? [],
      dicatatOlehNama: data['dicatatOlehNama'] ?? 'N/A',
    );
  }
}