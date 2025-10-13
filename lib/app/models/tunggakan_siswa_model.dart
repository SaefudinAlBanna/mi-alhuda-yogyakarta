// lib/app/models/tunggakan_siswa_model.dart

class TunggakanSiswaModel {
  final String uid;
  final String namaSiswa;
  final String? kelasId;
  int totalTunggakan; // Dibuat non-final agar bisa diakumulasi

  TunggakanSiswaModel({
    required this.uid,
    required this.namaSiswa,
    this.kelasId,
    this.totalTunggakan = 0,
  });

  String get namaKelasSimple => kelasId?.split('-').first ?? 'N/A';
}