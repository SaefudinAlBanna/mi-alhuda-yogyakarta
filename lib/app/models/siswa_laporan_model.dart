// lib/app/models/siswa_laporan_model.dart

class SiswaLaporanModel {
  final String uid;
  final String nama;
  final String nisn;
  
  // Metrik-metrik baru yang lebih kaya sesuai blueprint
  double nilaiAkhirRapor;
  double rataRataAbsensiKelas;
  double rataRataAbsensiHalaqah;
  int jumlahJurnalBelumDiisi;

  SiswaLaporanModel({
    required this.uid,
    required this.nama,
    required this.nisn,
    // Inisialisasi dengan nilai default
    this.nilaiAkhirRapor = 0.0,
    this.rataRataAbsensiKelas = 0.0,
    this.rataRataAbsensiHalaqah = 0.0,
    this.jumlahJurnalBelumDiisi = 0,
  });
}