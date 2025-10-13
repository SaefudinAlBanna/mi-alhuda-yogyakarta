class SiswaHalaqoh {
  final String nisn;
  final String nama;
  final String kelas;
  final String alhusna;
  final String? profileImageUrl; // Tambahkan ini (nullable)
  final Map<String, dynamic> rawData;

  SiswaHalaqoh({
    required this.nisn,
    required this.nama,
    required this.kelas,
    required this.alhusna,
    this.profileImageUrl, // Jadikan opsional
    required this.rawData,
  });

  factory SiswaHalaqoh.fromFirestore(Map<String, dynamic> data) {
    return SiswaHalaqoh(
      nisn: data['nisn'] ?? 'No NISN',
      nama: data['namasiswa'] ?? 'No Name',
      kelas: data['kelas'] ?? 'No Class',
      alhusna: data['alhusna'] ?? '0',
      profileImageUrl: data['profileImageUrl'], // Ambil URL dari data
      rawData: data,
    );
  }
}