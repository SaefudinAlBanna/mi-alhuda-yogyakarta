class RekapJenisTagihan {
  final String jenis;
  int totalTagihan;
  int totalTerbayar;

  RekapJenisTagihan({
    required this.jenis,
    this.totalTagihan = 0,
    this.totalTerbayar = 0,
  });

  int get sisa => totalTagihan - totalTerbayar;
}