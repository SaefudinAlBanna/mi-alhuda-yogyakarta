// lib/app/models/jadwal_tugas_item_model.dart (VERSI MODIFIKASI)

enum StatusJurnal { BelumDiisi, SudahDiisi, TugasPengganti, Dibatalkan }

class JadwalTugasItem {
  final String jamKe;
  final String idMapel;
  final String namaMapel;
  final String idKelas;
  final String tingkatanKelas;
  final String idGuru;
  final String namaGuru;

  // Status dan data jurnal
  final StatusJurnal status;
  final String? materiDiisi;
  final String? catatanDiisi;

  // --- [TAMBAHAN BARU UNTUK MISI 1.1] ---
  // Properti untuk menyimpan info pengganti jika ada
  final String? namaGuruPengganti;
  final String? idSesiPengganti; // ID dokumen dari koleksi sesi_pengganti_kbm

  JadwalTugasItem({
    required this.jamKe, required this.idMapel, required this.namaMapel,
    required this.idKelas, required this.tingkatanKelas,
    required this.idGuru, required this.namaGuru,
    required this.status, this.materiDiisi, this.catatanDiisi,
    // Tambahkan di constructor
    this.namaGuruPengganti, this.idSesiPengganti,
  });

  JadwalTugasItem copyWith({
    String? namaGuruPengganti,
    String? idSesiPengganti,
    bool clearPengganti = false, // Flag untuk membatalkan
  }) {
    return JadwalTugasItem(
      jamKe: this.jamKe,
      idMapel: this.idMapel,
      namaMapel: this.namaMapel,
      idKelas: this.idKelas,
      tingkatanKelas: this.tingkatanKelas,
      idGuru: this.idGuru,
      namaGuru: this.namaGuru,
      status: this.status,
      materiDiisi: this.materiDiisi,
      catatanDiisi: this.catatanDiisi,
      // Logika pembaruan
      namaGuruPengganti: clearPengganti ? null : namaGuruPengganti ?? this.namaGuruPengganti,
      idSesiPengganti: clearPengganti ? null : idSesiPengganti ?? this.idSesiPengganti,
    );
  }
}