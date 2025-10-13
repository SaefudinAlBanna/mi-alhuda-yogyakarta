import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcaraKalender {
  final String id;
  final String judul;
  final String deskripsi;
  final DateTime mulai;
  final DateTime selesai;
  final bool isLibur;
  final Color warna;
  final String warnaHex;

  AcaraKalender({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.mulai,
    required this.selesai,
    required this.isLibur,
    required this.warna,
    required this.warnaHex,
  });

  factory AcaraKalender.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String warnaHex = data['warnaHex'] ?? '#2196F3'; // Default ke Biru
    return AcaraKalender(
      id: doc.id,
      judul: data['namaKegiatan'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      mulai: (data['tanggalMulai'] as Timestamp).toDate(),
      selesai: (data['tanggalSelesai'] as Timestamp).toDate(),
      isLibur: data['isLibur'] ?? false,
      warnaHex: warnaHex,
      warna: Color(int.parse(warnaHex.substring(1), radix: 16) + 0xFF000000),
    );
  }
}