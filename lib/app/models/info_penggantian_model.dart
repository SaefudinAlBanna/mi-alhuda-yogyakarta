// lib/app/models/info_penggantian_model.dart

enum TipePenggantian { Insidental, RentangWaktu }

class InfoPenggantianModel {
  final TipePenggantian tipe;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai; // Nullable untuk tipe insidental
  final String namaGuruAsli;
  final String namaGuruPengganti;
  final String detailSesi; // Contoh: "Matematika - 4A (Jam ke-1)" atau "Semua Jadwal"

  InfoPenggantianModel({
    required this.tipe,
    required this.tanggalMulai,
    this.tanggalSelesai,
    required this.namaGuruAsli,
    required this.namaGuruPengganti,
    required this.detailSesi,
  });
}