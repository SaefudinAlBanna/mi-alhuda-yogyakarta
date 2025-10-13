class SantriHalaqahLaporanModel {
  final String uid;
  final String nama;
  
  // Hasil kalkulasi
  final String setoranTerakhir; // Contoh: "An-Naba': 1-10"
  final DateTime? tanggalSetoranTerakhir;
  final int totalSetoranBulanIni;

  SantriHalaqahLaporanModel({
    required this.uid,
    required this.nama,
    required this.setoranTerakhir,
    this.tanggalSetoranTerakhir,
    required this.totalSetoranBulanIni,
  });
}