class KenaikanSiswaModel {
  String uid;
  String nama;
  String nisn;
  String kelasAsalId;
  String kelasAsalNama;
  String status; // 'Naik', 'Tinggal', 'Lulus'
  String? targetKelasId; // ID kelas baru jika 'Naik' atau 'Tinggal'

  KenaikanSiswaModel({
    required this.uid,
    required this.nama,
    required this.nisn,
    required this.kelasAsalId,
    required this.kelasAsalNama,
    this.status = 'Naik', // Default
    this.targetKelasId,
  });
}