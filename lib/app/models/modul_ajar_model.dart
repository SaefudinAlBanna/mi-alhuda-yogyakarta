// app/models/modul_ajar_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class ModulAjarModel {
  String idModul;
  String idSekolah;
  String idPenyusun;
  String namaPenyusun;
  String idTahunAjaran;
  String mapel;
  int kelas;
  String fase;
  String alokasiWaktu;
  String kompetensiAwal;
  List<String> profilPancasila;
  List<String> profilRahmatan;
  List<String> media;
  List<String> sumberBelajar;
  List<String> targetPesertaDidik;
  String modelPembelajaran;
  List<String> elemen;
  String tujuanPembelajaran; // Bisa menggunakan format markdown
  String pemahamanBermakna;
  List<String> pertanyaanPemantik;
  List<SesiPembelajaran> kegiatanPembelajaran;
  String status; // 'draf' atau 'dipublikasikan'
  Timestamp createdAt;
  Timestamp lastModified;

  ModulAjarModel({
    required this.idModul,
    required this.idSekolah,
    required this.idPenyusun,
    required this.namaPenyusun,
    required this.idTahunAjaran,
    required this.mapel,
    required this.kelas,
    required this.fase,
    required this.alokasiWaktu,
    required this.kompetensiAwal,
    required this.profilPancasila,
    required this.profilRahmatan,
    required this.media,
    required this.sumberBelajar,
    required this.targetPesertaDidik,
    required this.modelPembelajaran,
    required this.elemen,
    required this.tujuanPembelajaran,
    required this.pemahamanBermakna,
    required this.pertanyaanPemantik,
    required this.kegiatanPembelajaran,
    required this.status,
    required this.createdAt,
    required this.lastModified,
  });

  factory ModulAjarModel.fromJson(Map<String, dynamic> json) {
    return ModulAjarModel(
      idModul: json['idModul'] ?? '',
      idSekolah: json['idSekolah'] ?? '',
      idPenyusun: json['idPenyusun'] ?? '',
      namaPenyusun: json['namaPenyusun'] ?? '',
      idTahunAjaran: json['idTahunAjaran'] ?? '',
      mapel: json['mapel'] ?? '',
      kelas: json['kelas'] ?? 0,
      fase: json['fase'] ?? '',
      alokasiWaktu: json['alokasiWaktu'] ?? '',
      kompetensiAwal: json['kompetensiAwal'] ?? '',
      profilPancasila: List<String>.from(json['profilPancasila'] ?? []),
      profilRahmatan: List<String>.from(json['profilRahmatan'] ?? []),
      media: List<String>.from(json['media'] ?? []),
      sumberBelajar: List<String>.from(json['sumberBelajar'] ?? []),
      targetPesertaDidik: List<String>.from(json['targetPesertaDidik'] ?? []),
      modelPembelajaran: json['modelPembelajaran'] ?? '',
      elemen: List<String>.from(json['elemen'] ?? []),
      tujuanPembelajaran: json['tujuanPembelajaran'] ?? '',
      pemahamanBermakna: json['pemahamanBermakna'] ?? '',
      pertanyaanPemantik: List<String>.from(json['pertanyaanPemantik'] ?? []),
      kegiatanPembelajaran: (json['kegiatanPembelajaran'] as List<dynamic>? ?? [])
          .map((sesi) => SesiPembelajaran.fromJson(sesi))
          .toList(),
      status: json['status'] ?? 'draf',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      lastModified: json['lastModified'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idModul': idModul,
      'idSekolah': idSekolah,
      'idPenyusun': idPenyusun,
      'namaPenyusun': namaPenyusun,
      'idTahunAjaran': idTahunAjaran,
      'mapel': mapel,
      'kelas': kelas,
      'fase': fase,
      'alokasiWaktu': alokasiWaktu,
      'kompetensiAwal': kompetensiAwal,
      'profilPancasila': profilPancasila,
      'profilRahmatan': profilRahmatan,
      'media': media,
      'sumberBelajar': sumberBelajar,
      'targetPesertaDidik': targetPesertaDidik,
      'modelPembelajaran': modelPembelajaran,
      'elemen': elemen,
      'tujuanPembelajaran': tujuanPembelajaran,
      'pemahamanBermakna': pemahamanBermakna,
      'pertanyaanPemantik': pertanyaanPemantik,
      'kegiatanPembelajaran': kegiatanPembelajaran.map((sesi) => sesi.toJson()).toList(),
      'status': status,
      'createdAt': createdAt,
      'lastModified': lastModified,
    };
  }
  
  // Fungsi duplikasi
  ModulAjarModel copyWith({String? idModul, String? idTahunAjaran}) {
    return ModulAjarModel(
      idModul: idModul ?? this.idModul,
      idSekolah: this.idSekolah,
      idPenyusun: this.idPenyusun,
      namaPenyusun: this.namaPenyusun,
      idTahunAjaran: idTahunAjaran ?? this.idTahunAjaran,
      mapel: this.mapel,
      kelas: this.kelas,
      fase: this.fase,
      alokasiWaktu: this.alokasiWaktu,
      kompetensiAwal: this.kompetensiAwal,
      profilPancasila: List<String>.from(this.profilPancasila),
      profilRahmatan: List<String>.from(this.profilRahmatan),
      media: List<String>.from(this.media),
      sumberBelajar: List<String>.from(this.sumberBelajar),
      targetPesertaDidik: List<String>.from(this.targetPesertaDidik),
      modelPembelajaran: this.modelPembelajaran,
      elemen: List<String>.from(this.elemen),
      tujuanPembelajaran: this.tujuanPembelajaran,
      pemahamanBermakna: this.pemahamanBermakna,
      pertanyaanPemantik: List<String>.from(this.pertanyaanPemantik),
      kegiatanPembelajaran: this.kegiatanPembelajaran.map((e) => e.copyWith()).toList(),
      status: 'draf', // Selalu set ke draf saat diduplikasi
      createdAt: Timestamp.now(),
      lastModified: Timestamp.now(),
    );
  }
}

class SesiPembelajaran {
  final int sesi;
  final String judulSesi;
  final String pendahuluan;
  final String kegiatanInti;
  final String penutup;

  SesiPembelajaran({
    required this.sesi,
    required this.judulSesi,
    required this.pendahuluan,
    required this.kegiatanInti,
    required this.penutup,
  });

  factory SesiPembelajaran.fromJson(Map<String, dynamic> json) {
    return SesiPembelajaran(
      sesi: json['sesi'] ?? 0,
      judulSesi: json['judulSesi'] ?? '',
      pendahuluan: json['pendahuluan'] ?? '',
      kegiatanInti: json['kegiatanInti'] ?? '',
      penutup: json['penutup'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sesi': sesi,
      'judulSesi': judulSesi,
      'pendahuluan': pendahuluan,
      'kegiatanInti': kegiatanInti,
      'penutup': penutup,
    };
  }

  SesiPembelajaran copyWith() {
    return SesiPembelajaran(
      sesi: this.sesi,
      judulSesi: this.judulSesi,
      pendahuluan: this.pendahuluan,
      kegiatanInti: this.kegiatanInti,
      penutup: this.penutup,
    );
  }
}