import 'package:cloud_firestore/cloud_firestore.dart';

class PengampuInfo {
  final String namaPengampu;
  final String fase;
  final String idPengampu;
  final String? profileImageUrl;
  final int jumlahSiswa;

  PengampuInfo({
    required this.namaPengampu,
    required this.fase,
    required this.idPengampu,
    this.profileImageUrl,
    required this.jumlahSiswa,
  });

  // Factory method tidak perlu diubah, karena kita akan mengisi profileImageUrl secara terpisah.
  factory PengampuInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PengampuInfo(
      namaPengampu: data['namapengampu'] ?? 'Tanpa Nama',
      fase: data['fase'] ?? '',
      idPengampu: data['idpengampu'] ?? '', 
      jumlahSiswa: data['jumlahsiswa'] ?? 0,
      // profileImageUrl akan diisi nanti, jadi biarkan null dulu di sini
    );
  }

  // BUAT METHOD 'copyWith' untuk memudahkan update object
  PengampuInfo copyWith({
    String? namaPengampu,
    String? fase,
    String? idPengampu,
    String? profileImageUrl,
    int? jumlahSiswa,
  }) {
    return PengampuInfo(
      namaPengampu: namaPengampu ?? this.namaPengampu,
      fase: fase ?? this.fase,
      jumlahSiswa: jumlahSiswa ?? this.jumlahSiswa,
      idPengampu: idPengampu ?? this.idPengampu,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}