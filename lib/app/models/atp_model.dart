import 'package:cloud_firestore/cloud_firestore.dart';

class AtpModel {
  String idAtp;
  String idSekolah;
  String idPenyusun;
   String namaPenyusun;
  final String idTahunAjaran;
  final String namaMapel;
  final String fase;
  final int kelas;
  final String capaianPembelajaran;
  Timestamp createdAt;
  Timestamp lastModified;
  final List<UnitPembelajaran> unitPembelajaran;

  AtpModel({
    required this.idAtp,
    required this.idSekolah,
    required this.idPenyusun,
    required this.namaPenyusun,
    required this.idTahunAjaran,
    required this.namaMapel,
    required this.fase,
    required this.kelas,
    required this.capaianPembelajaran,
    required this.createdAt,
    required this.lastModified,
    required this.unitPembelajaran,
  });

  // Konversi dari JSON (Map Firestore) ke Object Dart
  factory AtpModel.fromJson(Map<String, dynamic> json) {
    return AtpModel(
      idAtp: json['idAtp'] ?? '',
      idSekolah: json['idSekolah'] ?? '',
      idPenyusun: json['idPenyusun'] ?? '',
      namaPenyusun: json['namaPenyusun'] ?? '',
      idTahunAjaran: json['idTahunAjaran'] ?? '',
      namaMapel: json['namaMapel'] ?? '',
      fase: json['fase'] ?? '',
      kelas: json['kelas'] ?? 0,
      capaianPembelajaran: json['capaianPembelajaran'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      lastModified: json['lastModified'] ?? Timestamp.now(),
      unitPembelajaran: (json['unitPembelajaran'] as List<dynamic>? ?? [])
          .map((unit) => UnitPembelajaran.fromJson(unit))
          .toList(),
    );
  }

  // Konversi dari Object Dart ke JSON (Map untuk dikirim ke Firestore)
  Map<String, dynamic> toJson() {
    return {
      'idAtp': idAtp,
      'idSekolah': idSekolah,
      'idPenyusun': idPenyusun,
      'namaPenyusun': namaPenyusun,
      'idTahunAjaran': idTahunAjaran,
      'namaMapel': namaMapel,
      'fase': fase,
      'kelas': kelas,
      'capaianPembelajaran': capaianPembelajaran,
      'createdAt': createdAt,
      'lastModified': lastModified,
      'unitPembelajaran': unitPembelajaran.map((unit) => unit.toJson()).toList(),
    };
  }
   
  // Fungsi untuk duplikasi (ini akan sangat berguna nanti!)
  AtpModel copyWith({String? idAtp, String? idTahunAjaran}) {
    return AtpModel(
      idAtp: idAtp ?? this.idAtp,
      idSekolah: this.idSekolah,
      idPenyusun: this.idPenyusun,
      namaPenyusun: this.namaPenyusun,
      idTahunAjaran: idTahunAjaran ?? this.idTahunAjaran,
      namaMapel: this.namaMapel,
      fase: this.fase,
      kelas: this.kelas,
      capaianPembelajaran: this.capaianPembelajaran,
      createdAt: Timestamp.now(), // Waktu baru saat diduplikasi
      lastModified: Timestamp.now(), // Waktu baru saat diduplikasi
      unitPembelajaran: this.unitPembelajaran.map((e) => e.copyWith()).toList(),
    );
  }
}

class UnitPembelajaran {
  final String idUnit;
  final int urutan;
  final String lingkupMateri;
  final String jenisTeks;
  final String gramatika;
  final String alokasiWaktu;
  final List<String> tujuanPembelajaran;
  final List<AlurPembelajaran> alurPembelajaran;

  // --- TAMBAHAN BARU ---
  int? semester; // Semester berapa unit ini diajarkan (1 atau 2)
  String? bulan;  // Bulan apa unit ini diajarkan (e.g., "Juli", "Agustus")

  UnitPembelajaran({
    required this.idUnit,
    required this.urutan,
    required this.lingkupMateri,
    required this.jenisTeks,
    required this.gramatika,
    required this.alokasiWaktu,
    required this.tujuanPembelajaran,
    required this.alurPembelajaran,

    // Tambahkan di constructor
    this.semester,
    this.bulan,
  });

  factory UnitPembelajaran.fromJson(Map<String, dynamic> json) {
    return UnitPembelajaran(
      idUnit: json['idUnit'] ?? '',
      urutan: json['urutan'] ?? 0,
      lingkupMateri: json['lingkupMateri'] ?? '',
      jenisTeks: json['jenisTeks'] ?? '',
      gramatika: json['gramatika'] ?? '',
      alokasiWaktu: json['alokasiWaktu'] ?? '',
      tujuanPembelajaran: List<String>.from(json['tujuanPembelajaran'] ?? []),
      alurPembelajaran: (json['alurPembelajaran'] as List<dynamic>? ?? [])
          .map((alur) => AlurPembelajaran.fromJson(alur))
          .toList(),

          // Ambil data baru dari JSON
      semester: json['semester'], // Boleh null
      bulan: json['bulan'],     // Boleh null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUnit': idUnit,
      'urutan': urutan,
      'lingkupMateri': lingkupMateri,
      'jenisTeks': jenisTeks,
      'gramatika': gramatika,
      'alokasiWaktu': alokasiWaktu,
      'tujuanPembelajaran': tujuanPembelajaran,
      'alurPembelajaran': alurPembelajaran.map((alur) => alur.toJson()).toList(),

       // Tambahkan field baru ke JSON
      'semester': semester,
      'bulan': bulan,
    };
  }
    
  UnitPembelajaran copyWith() {
    return UnitPembelajaran(
      idUnit: this.idUnit,
      urutan: this.urutan,
      lingkupMateri: this.lingkupMateri,
      jenisTeks: this.jenisTeks,
      gramatika: this.gramatika,
      alokasiWaktu: this.alokasiWaktu,
      tujuanPembelajaran: List<String>.from(this.tujuanPembelajaran),
      alurPembelajaran: this.alurPembelajaran.map((e) => e.copyWith()).toList(),
    );
  }
}

class AlurPembelajaran {
  final int urutan;
  final String deskripsi;

  AlurPembelajaran({required this.urutan, required this.deskripsi});

  factory AlurPembelajaran.fromJson(Map<String, dynamic> json) {
    return AlurPembelajaran(
      urutan: json['urutan'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urutan': urutan,
      'deskripsi': deskripsi,
    };
  }
    
  AlurPembelajaran copyWith() {
      return AlurPembelajaran(
      urutan: this.urutan,
      deskripsi: this.deskripsi,
      );
  }
}