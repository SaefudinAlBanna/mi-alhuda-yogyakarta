// lib/app/models/komite_log_transaksi_model.dart (Aplikasi SEKOLAH)

import 'package:cloud_firestore/cloud_firestore.dart';

class KomiteLogTransaksiModel {
  final String id;
  final String jenis; // 'Pemasukan' | 'Pengeluaran' | 'MASUK' | 'KELUAR'
  final String? deskripsi;
  final int nominal;
  final DateTime timestamp;
  final String? sumber;
  final String? tujuan;
  final String? status;
  final String? pencatatNama;
  final String? alasanPenolakan;

  KomiteLogTransaksiModel({
    required this.id,
    required this.jenis,
    this.deskripsi,
    required this.nominal,
    required this.timestamp,
    this.sumber,
    this.tujuan,
    this.status,
    this.pencatatNama,
    this.alasanPenolakan,
  });

  factory KomiteLogTransaksiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final tanggalData = data['timestamp'] ?? data['tanggal'];

    return KomiteLogTransaksiModel(
      id: doc.id,
      jenis: data['jenis'] ?? 'Pemasukan',
      deskripsi: data['deskripsi'],
      nominal: (data['nominal'] as num?)?.toInt() ?? 0,
      timestamp: (tanggalData as Timestamp? ?? Timestamp.now()).toDate(),
      sumber: data['sumber'] as String?,
      tujuan: data['tujuan'] as String?,
      status: data['status'] as String?,
      pencatatNama: data['pencatatNama'] as String?,
      alasanPenolakan: data['alasanPenolakan'] as String?,
    );
  }
}