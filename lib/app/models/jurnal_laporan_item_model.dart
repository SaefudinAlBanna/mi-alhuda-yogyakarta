// lib/app/models/jurnal_laporan_item_model.dart

class JurnalLaporanItem {
  final DateTime tanggal;
  final String namaMapel;
  final String idKelas;
  final String materi;
  final String? catatan;
  final bool isPengganti;
  final String jamKe;
  final String namaGuru;
  final String? rekapAbsensi;

  JurnalLaporanItem({
    required this.tanggal,
    required this.namaMapel,
    required this.idKelas,
    required this.materi,
    this.catatan,
    required this.isPengganti,
    required this.jamKe,
    required this.namaGuru,
    this.rekapAbsensi,
  });
}