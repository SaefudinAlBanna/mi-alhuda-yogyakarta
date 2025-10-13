// lib/app/models/halaqah_setoran_ummi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class untuk data materi yang disetor.
class HalaqahUmmiMateri {
  final String tingkat;
  final String detailTingkat;
  final int halaman;

  HalaqahUmmiMateri({
    required this.tingkat,
    required this.detailTingkat,
    required this.halaman,
  });

  factory HalaqahUmmiMateri.fromJson(Map<String, dynamic> json) {
    return HalaqahUmmiMateri(
      tingkat: json['tingkat'] ?? 'Jilid',
      detailTingkat: json['detailTingkat'] ?? '1',
      halaman: json['halaman'] ?? 0,
    );
  }
}

/// Helper class untuk data penilaian.
class HalaqahUmmiPenilaian {
  final String status;
  final int nilaiAngka;
  final String nilaiHuruf;

  HalaqahUmmiPenilaian({
    required this.status,
    required this.nilaiAngka,
    required this.nilaiHuruf,
  });

  factory HalaqahUmmiPenilaian.fromJson(Map<String, dynamic> json) {
    return HalaqahUmmiPenilaian(
      status: json['status'] ?? 'Belum Dinilai',
      nilaiAngka: json['nilaiAngka'] ?? 0,
      nilaiHuruf: json['nilaiHuruf'] ?? '-',
    );
  }
}

/// Model utama untuk merepresentasikan satu entri riwayat setoran harian.
class HalaqahSetoranUmmiModel {
  final String id;
  final DateTime tanggalSetor;
  final String idGrup;
  final String idPengampu;
  final String namaPengampu;
  final bool isDinilaiPengganti;
  final String idPenilai;
  final String namaPenilai;
  final String lokasiAktual;
  final HalaqahUmmiMateri materi;
  final HalaqahUmmiPenilaian penilaian;
  final String catatanPengampu;
  final String catatanOrangTua;

  HalaqahSetoranUmmiModel({
    required this.id,
    required this.tanggalSetor,
    required this.idGrup,
    required this.idPengampu,
    required this.namaPengampu,
    required this.isDinilaiPengganti,
    required this.idPenilai,
    required this.namaPenilai,
    required this.lokasiAktual,
    required this.materi,
    required this.penilaian,
    required this.catatanPengampu,
    required this.catatanOrangTua,
  });

  factory HalaqahSetoranUmmiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahSetoranUmmiModel(
      id: doc.id,
      tanggalSetor: (data['tanggalSetor'] as Timestamp?)?.toDate() ?? DateTime.now(),
      idGrup: data['idGrup'] ?? '',
      idPengampu: data['idPengampu'] ?? '',
      namaPengampu: data['namaPengampu'] ?? '',
      isDinilaiPengganti: data['isDinilaiPengganti'] ?? false,
      idPenilai: data['idPenilai'] ?? '',
      namaPenilai: data['namaPenilai'] ?? '',
      lokasiAktual: data['lokasiAktual'] ?? '',
      materi: HalaqahUmmiMateri.fromJson(data['materi'] as Map<String, dynamic>? ?? {}),
      penilaian: HalaqahUmmiPenilaian.fromJson(data['penilaian'] as Map<String, dynamic>? ?? {}),
      catatanPengampu: data['catatanPengampu'] ?? '',
      catatanOrangTua: data['catatanOrangTua'] ?? '',
    );
  }
}