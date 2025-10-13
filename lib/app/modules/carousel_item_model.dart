// lib/app/models/carousel_item_model.dart

enum CarouselContentType { SedangBerlangsung, Berikutnya, RekapAbsensi, PesanDefault }

class CarouselItemModel {
  final String namaKelas;
  final CarouselContentType tipeKonten;
  final String judul; // Contoh: "Saat ini:", "Kehadiran Hari Ini:"
  final String isi;   // Contoh: "Matematika oleh Ustadz Budi", "H:20, S:1, I:1, A:0"
  final String? subJudul; // Contoh: "07:30 - 08:00"

  CarouselItemModel({
    required this.namaKelas,
    required this.tipeKonten,
    required this.judul,
    required this.isi,
    this.subJudul,
  });
}