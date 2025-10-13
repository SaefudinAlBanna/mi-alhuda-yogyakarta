// lib/app/models/tagihan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TagihanModel {
  final String id;
  final String deskripsi;
  final String jenisPembayaran;
  final int jumlahTagihan;
  final int jumlahTerbayar;
  final String status;
  final Timestamp? tanggalJatuhTempo;
  final bool isTunggakan;
  final Map<String, dynamic> metadata;
  final String? kelasSaatDitagih;
  final String? namaSiswa; // [PENAMBAHAN] Properti untuk nama siswa

  TagihanModel({
    required this.id,
    required this.deskripsi,
    required this.jenisPembayaran,
    required this.jumlahTagihan,
    required this.jumlahTerbayar,
    required this.status,
    this.tanggalJatuhTempo,
    required this.isTunggakan,
    required this.metadata,
    this.kelasSaatDitagih,
    this.namaSiswa, // [PENAMBAHAN] Tambahkan ke constructor
  });

  factory TagihanModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TagihanModel(
      id: doc.id,
      deskripsi: data['deskripsi'] ?? 'Tanpa Deskripsi',
      jenisPembayaran: data['jenisPembayaran'] ?? 'Lainnya',
      
      // [PERBAIKAN KUNCI] Membuat model "pintar" untuk membaca field lama ('totalTagihan')
      // dan field baru yang sudah konsisten ('jumlahTagihan').
      // Ini memberikan ketahanan jika ada data yang terlewat saat migrasi manual.
      jumlahTagihan: (data['jumlahTagihan'] as num?)?.toInt() ?? (data['totalTagihan'] as num?)?.toInt() ?? 0,
      jumlahTerbayar: (data['jumlahTerbayar'] as num?)?.toInt() ?? (data['totalTerbayar'] as num?)?.toInt() ?? 0,
      
      status: data['status'] ?? 'Belum Lunas',
      tanggalJatuhTempo: data['tanggalJatuhTempo'],
      isTunggakan: data['isTunggakan'] ?? false,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      kelasSaatDitagih: data['kelasSaatDitagih'] as String?,
      
      // [PERBAIKAN KUNCI] Membaca 'namaSiswa' dari data.
      // Ini akan memperbaiki bug tampilan UID di Laporan Keuangan.
      namaSiswa: data['namaSiswa'] as String?,
    );
  }

  int get sisaTagihan => jumlahTagihan - jumlahTerbayar;

  String get bulanTahunSPP {
    if (jenisPembayaran == 'SPP' && metadata.containsKey('bulan') && metadata.containsKey('tahun')) {
      return DateFormat('MMMM yyyy', 'id_ID').format(DateTime(metadata['tahun'], metadata['bulan']));
    }
    return deskripsi;
  }
}