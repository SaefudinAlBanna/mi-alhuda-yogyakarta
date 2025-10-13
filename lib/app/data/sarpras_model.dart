import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SarprasModel {
  final String id; // Document ID
  final String namaBarang;
  final int jumlah;
  final String kondisi;
  final String lokasi;
  final DateTime? tanggalPengadaan; // Menggunakan DateTime agar mudah diformat
  final String? keterangan;
  final DateTime? timestamp; // Kapan data dibuat/diupdate

  SarprasModel({
    required this.id,
    required this.namaBarang,
    required this.jumlah,
    required this.kondisi,
    required this.lokasi,
    this.tanggalPengadaan,
    this.keterangan,
    this.timestamp,
  });

  // Factory constructor untuk membuat instance dari Firestore document
  factory SarprasModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return SarprasModel(
      id: doc.id,
      namaBarang: data['namaBarang'] ?? 'N/A',
      jumlah: (data['jumlah'] ?? 0).toInt(),
      kondisi: data['kondisi'] ?? 'N/A',
      lokasi: data['lokasi'] ?? 'N/A',
      tanggalPengadaan: data['tanggalPengadaan'] != null
          ? (data['tanggalPengadaan'] as Timestamp).toDate()
          : null,
      keterangan: data['keterangan'],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  // Helper untuk format tanggal agar mudah dibaca
  String get tanggalPengadaanFormatted {
    if (tanggalPengadaan == null) return 'Tidak ada data';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalPengadaan!);
  }
}