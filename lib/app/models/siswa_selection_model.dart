// lib/app/models/siswa_selection_model.dart

class SiswaSelectionModel {
  final String uid;
  final String nama;
  final String? namaOrangTua;
  final String kelasId;

  SiswaSelectionModel({
    required this.uid,
    required this.nama,
    this.namaOrangTua,
    required this.kelasId,
  });
}