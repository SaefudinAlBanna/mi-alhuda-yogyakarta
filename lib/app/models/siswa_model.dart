// lib/app/models/siswa_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaModel {
  // --- KATEGORI: IDENTITAS INTI ---
  final String uid;              // UID dari Firebase Auth, digunakan sebagai ID dokumen
  final String nisn;             // Nomor Induk Siswa Nasional (Kunci unik sekunder)
  final String namaLengkap;
  final String? namaPanggilan;
  final String? email;            // Email login (saat ini {nisn}@telagailmu.com)
  final String? fotoProfilUrl;

  // --- KATEGORI: DATA PRIBADI ---
  final String? jenisKelamin;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final String? agama;
  final String? kewarganegaraan;
  final int? anakKe;
  final int? jumlahSaudara;

  // --- KATEGORI: DATA AKADEMIK & STATUS ---
  final String? kelasId;          // ID dokumen kelas (misal: '1A_2024') untuk relasi
  final String? statusSiswa;      // 'Aktif', 'Lulus', 'Pindah', 'Dikeluarkan'
  final int? tahunMasuk;
  final num? spp;                // Biaya SPP per bulan

  // --- KATEGORI: DATA ORANG TUA ---
  final String? namaAyah;
  final String? pekerjaanAyah;
  final String? pendidikanAyah;
  final String? noHpAyah;
  
  final String? namaIbu;
  final String? pekerjaanIbu;
  final String? pendidikanIbu;
  final String? noHpIbu;

  // --- KATEGORI: DATA WALI (JIKA BERBEDA DARI ORANG TUA) ---
  final String? namaWali;
  final String? hubunganWali;
  final String? pekerjaanWali;
  final String? noHpWali;

  // --- KATEGORI: KONTAK & ALAMAT ---
  final String? alamatLengkap;
  final String? teleponRumah;

  // --- KATEGORI: METADATA APLIKASI ---
  final bool isProfileComplete;    // Untuk fitur "Paksa Lengkapi Profil"
  final bool mustChangePassword;   // Untuk fitur "Paksa Ganti Password"
  final DateTime? createdAt;       // Waktu dokumen dibuat
  final String? createdBy;         // Email admin yang membuat

  SiswaModel({
    // Wajib ada saat pembuatan
    required this.uid,
    required this.nisn,
    required this.namaLengkap,
    
    // Opsional
    this.namaPanggilan,
    this.email,
    this.fotoProfilUrl,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.agama,
    this.kewarganegaraan,
    this.anakKe,
    this.jumlahSaudara,
    this.kelasId,
    this.statusSiswa,
    this.tahunMasuk,
    this.spp,
    this.namaAyah,
    this.pekerjaanAyah,
    this.pendidikanAyah,
    this.noHpAyah,
    this.namaIbu,
    this.pekerjaanIbu,
    this.pendidikanIbu,
    this.noHpIbu,
    this.namaWali,
    this.hubunganWali,
    this.pekerjaanWali,
    this.noHpWali,
    this.alamatLengkap,
    this.teleponRumah,
    this.isProfileComplete = false,
    this.mustChangePassword = true,
    this.createdAt,
    this.createdBy,
  });

  factory SiswaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? toDateTime(Timestamp? timestamp) => timestamp?.toDate();

    return SiswaModel(
      uid: doc.id,
      nisn: data['nisn'] ?? '',
      namaLengkap: data['namaLengkap'] ?? 'Tanpa Nama',
      namaPanggilan: data['namaPanggilan'],
      email: data['email'],
      fotoProfilUrl: data['fotoProfilUrl'],
      jenisKelamin: data['jenisKelamin'],
      tempatLahir: data['tempatLahir'],
      tanggalLahir: toDateTime(data['tanggalLahir']),
      agama: data['agama'],
      kewarganegaraan: data['kewarganegaraan'],
      anakKe: data['anakKe'],
      jumlahSaudara: data['jumlahSaudara'],
      kelasId: data['kelasId'],
      statusSiswa: data['statusSiswa'],
      tahunMasuk: data['tahunMasuk'],
      spp: data['spp'],
      namaAyah: data['namaAyah'],
      pekerjaanAyah: data['pekerjaanAyah'],
      pendidikanAyah: data['pendidikanAyah'],
      noHpAyah: data['noHpAyah'],
      namaIbu: data['namaIbu'],
      pekerjaanIbu: data['pekerjaanIbu'],
      pendidikanIbu: data['pendidikanIbu'],
      noHpIbu: data['noHpIbu'],
      namaWali: data['namaWali'],
      hubunganWali: data['hubunganWali'],
      pekerjaanWali: data['pekerjaanWali'],
      noHpWali: data['noHpWali'],
      alamatLengkap: data['alamatLengkap'],
      teleponRumah: data['teleponRumah'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      mustChangePassword: data['mustChangePassword'] ?? false,
      createdAt: toDateTime(data['createdAt']),
      createdBy: data['createdBy'],
    );
  }
}