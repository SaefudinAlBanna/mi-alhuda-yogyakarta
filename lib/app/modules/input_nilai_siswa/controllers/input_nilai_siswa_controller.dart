// lib/app/modules/input_nilai_siswa/controllers/input_nilai_siswa_controller.dart

import 'dart:async'; // Pastikan ini ada
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/atp_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/nilai_harian_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

class InputNilaiSiswaController extends GetxController with GetTickerProviderStateMixin {
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String idKelas, namaMapel, idMapel, idGuru, namaGuru; 
  late SiswaModel siswa;
  late String idTahunAjaran, semesterAktif;
  late DocumentReference siswaMapelRef;

  late String idGuruPencatat;
  late String namaGuruPencatat;
  late String aliasGuruPencatat;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxBool isWaliKelas = false.obs;

  final RxList<NilaiHarianModel> daftarNilaiHarian = <NilaiHarianModel>[].obs;
  final RxMap<String, int> bobotNilai = <String, int>{}.obs;
  final Rxn<int> nilaiPTS = Rxn<int>();
  final Rxn<int> nilaiPAS = Rxn<int>();
  final Rxn<double> nilaiAkhir = Rxn<double>();
  final RxList<Map<String, dynamic>> rekapNilaiMapelLain = <Map<String, dynamic>>[].obs;

  final Rxn<AtpModel> atpModel = Rxn<AtpModel>();
  final RxMap<String, String> capaianTpSiswa = <String, String>{}.obs;
  final TextEditingController deskripsiCapaianC = TextEditingController();

  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final harianC = TextEditingController(), ulanganC = TextEditingController(), 
        ptsC = TextEditingController(), pasC = TextEditingController(), 
        tambahanC = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments == null) {
      Get.snackbar("Error", "Argumen halaman tidak valid.");
      isLoading.value = false;
      return;
    }
    _initializeArguments();
    // [PERBAIKAN]: Panggil inisialisasi data mapel siswa di sini
    _initializeSiswaMapelData(); 
    loadInitialData();
  }

  void _initializeArguments() {
    final Map<String, dynamic> args = Get.arguments ?? {};
    idKelas = args['idKelas'] ?? '';
    namaMapel = args['namaMapel'] ?? '';
    idMapel = args['idMapel'] ?? '';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    siswa = args['siswa'];

    idTahunAjaran = configC.tahunAjaranAktif.value;
    semesterAktif = configC.semesterAktif.value;

    siswaMapelRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(idTahunAjaran)
      .collection('kelastahunajaran').doc(idKelas)
      .collection('daftarsiswa').doc(siswa.uid)
      .collection('semester').doc(semesterAktif)
      .collection('matapelajaran').doc(idMapel);
    
    idGuruPencatat = _authController.auth.currentUser!.uid;
    namaGuruPencatat = configC.infoUser['nama'] ?? 'Guru Tidak Dikenal';
    aliasGuruPencatat = configC.infoUser['alias'] ?? namaGuruPencatat;
  }

  // [BARU]: Fungsi untuk memastikan data dasar mata pelajaran siswa ada
  Future<void> _initializeSiswaMapelData() async {
    try {
      await siswaMapelRef.set({
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'aliasGuruPencatatAkhir': aliasGuruPencatat, // Menambahkan alias guru pengampu/pencatat terakhir
        // Tambahkan field lain yang mungkin relevan secara default jika belum ada
      }, SetOptions(merge: true));
    } catch (e) {
      print("### Error initializing siswa mapel data: $e");
      Get.snackbar("Error", "Gagal menginisialisasi data mata pelajaran siswa. ${e.toString()}");
    }
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchBobotNilai(),
        fetchNilaiDanDeskripsiSiswa(),
        fetchNilaiHarian(),
        checkIsWaliKelas(),
        _fetchAtp(),
      ]);
      hitungNilaiAkhir();
    } catch (e) { Get.snackbar("Error", "Gagal memuat data nilai siswa: $e"); } 
    finally { isLoading.value = false; }
  }

  Future<void> checkIsWaliKelas() async {
    if (configC.infoUser['kelasDiampu'] == idKelas) {
      isWaliKelas.value = true;
      fetchRekapNilaiMapelLain(); 
    }
  }

   Future<void> fetchRekapNilaiMapelLain() async {
      try {
        final snapshot = await siswaMapelRef.parent.get();

        final List<Map<String, dynamic>> rekapList = [];
        for (var doc in snapshot.docs) {
          if (doc.id == idMapel) continue;

          final data = doc.data() as Map<String, dynamic>?;

          if (data != null) {
            rekapList.add({
              'mapel': data['namaMapel'] ?? doc.id,
              'guru': data['namaGuru'] ?? 'N/A',
              'nilai_akhir': (data['nilai_akhir'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }

        rekapNilaiMapelLain.assignAll(rekapList);
      } catch (e) {
        Get.snackbar("Error", "Gagal memuat rekap nilai mapel lain: $e");
      }
    }

  Future<void> _fetchAtp() async {
    try {
      final kelasString = idKelas.split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
      final kelasAngka = int.tryParse(kelasString) ?? 0;
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('atp')
          .where('idTahunAjaran', isEqualTo: idTahunAjaran)
          .where('namaMapel', isEqualTo: namaMapel)
          .where('kelas', isEqualTo: kelasAngka).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        atpModel.value = AtpModel.fromJson(snapshot.docs.first.data());
      } else {
        atpModel.value = null;
      }
    } catch (e) { print("### Info ATP: Gagal memuat data ATP: $e"); atpModel.value = null; }
  }

  Future<void> fetchNilaiDanDeskripsiSiswa() async {
    final doc = await siswaMapelRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      nilaiPTS.value = data['nilai_pts'];
      nilaiPAS.value = data['nilai_pas'];
      deskripsiCapaianC.text = data['deskripsi_capaian'] ?? '';
      if (data['capaian_tp'] != null) capaianTpSiswa.value = Map<String, String>.from(data['capaian_tp']);
    }
  }

  void setCapaianTp(String tp, String status) {
    if (capaianTpSiswa[tp] == status) { capaianTpSiswa.remove(tp); } 
    else { capaianTpSiswa[tp] = status; }
  }

  Future<void> simpanSemuaCapaian() async {
    isSaving.value = true;
    try {
      await siswaMapelRef.set({
        'deskripsi_capaian': deskripsiCapaianC.text.trim(),
        'capaian_tp': capaianTpSiswa,
        'idGuruPencatat': idGuruPencatat,
        'namaGuruPencatat': namaGuruPencatat,
        'aliasGuruPencatatAkhir': aliasGuruPencatat, // Perbaikan: Gunakan 'aliasGuruPencatatAkhir'
        'lastEdited': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Get.snackbar("Berhasil", "Capaian pembelajaran berhasil disimpan.");
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan capaian: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> fetchBobotNilai() async {
    final docRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('pengaturan').doc('bobot_nilai');

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        bobotNilai.value = {
          'tugasHarian': data['bobotTugasHarian'] ?? 20,
          'ulanganHarian': data['bobotUlanganHarian'] ?? 20,
          'nilaiTambahan': data['bobotNilaiTambahan'] ?? 20,
          'pts': data['bobotPts'] ?? 20,
          'pas': data['bobotPas'] ?? 20,
        };
      } else {
        bobotNilai.value = {
          'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20,
          'pts': 20, 'pas': 20,
        };
      }
    } catch (e) {
      print("### Gagal fetch bobot nilai, menggunakan default. Error: $e");
      bobotNilai.value = {
        'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20,
        'pts': 20, 'pas': 20,
      };
    }
  }

  Future<void> fetchNilaiHarian() async {
    final snapshot = await siswaMapelRef.collection('nilai_harian').orderBy('tanggal', descending: true).get();
    daftarNilaiHarian.assignAll(snapshot.docs.map((doc) => NilaiHarianModel.fromFirestore(doc)).toList());
  }


  Future<void> simpanNilaiHarian(String kategori) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai < 0 || nilai > 100) { Get.snackbar("Peringatan", "Nilai harus angka 0-100."); return; }
    isSaving.value = true;
    try {
      WriteBatch batch = _firestore.batch();
      final refNilaiBaru = siswaMapelRef.collection('nilai_harian').doc();
      
      // [PERBAIKAN KUNCI DI SINI] Tambahkan semua field yang dibutuhkan
      batch.set(refNilaiBaru, {
        'kategori': kategori, 
        'nilai': nilai, 
        'catatan': catatanC.text.trim(), 
        'tanggal': Timestamp.now(),
        'idGuruPencatat': idGuruPencatat,
        'namaGuruPencatat': namaGuruPencatat,
        'aliasGuruPencatat': aliasGuruPencatat,
        'idSekolah': configC.idSekolah,
        'idMapel': idMapel,
        'kelasId': idKelas,
        'semester': int.parse(semesterAktif),
      });
      
      final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': 'Nilai Baru: $namaMapel', 'isi': 'Ananda ${siswa.namaLengkap} mendapatkan nilai $nilai untuk $kategori.',
          'tipe': 'NILAI_MAPEL', 'tanggal': FieldValue.serverTimestamp(), 'isRead': false,
          'idSekolah': configC.idSekolah,
      });
      final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
      batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, 
      SetOptions(merge: true));
      
      await batch.commit();
      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
      Get.snackbar("Berhasil", "Nilai $kategori berhasil disimpan.");
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> updateNilaiHarian(String idNilai) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai < 0 || nilai > 100) { Get.snackbar("Peringatan", "Nilai harus berupa angka 0-100."); return; }
    isSaving.value = true;
    try {
      await siswaMapelRef.collection('nilai_harian').doc(idNilai).update({
        'nilai': nilai, 
        'catatan': catatanC.text.trim(),
        'idGuruPencatat': idGuruPencatat,
        'namaGuruPencatat': namaGuruPencatat,
        'aliasGuruPencatat': aliasGuruPencatat,
        'lastEdited': FieldValue.serverTimestamp(),
      });
      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil diperbarui.");
    } catch (e) { Get.snackbar("Error", "Gagal memperbarui nilai: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> deleteNilaiHarian(String idNilai) async {
    try {
      await siswaMapelRef.collection('nilai_harian').doc(idNilai).delete();
      daftarNilaiHarian.removeWhere((item) => item.id == idNilai);
      hitungNilaiAkhir();
      Get.snackbar("Berhasil", "Nilai harian telah dihapus.");
    } catch (e) { Get.snackbar("Error", "Gagal menghapus nilai: $e"); }
  }

  Future<void> simpanNilaiUtama(String jenisNilai, int nilai) async {
    isSaving.value = true;
    try {
      await siswaMapelRef.set({
        jenisNilai: nilai,
        'idGuruPencatat': idGuruPencatat,
        'namaGuruPencatat': namaGuruPencatat,
        'aliasGuruPencatatAkhir': aliasGuruPencatat, // Perbaikan: Gunakan 'aliasGuruPencatatAkhir'
        'lastEdited': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await fetchNilaiDanDeskripsiSiswa();
      hitungNilaiAkhir();
      Get.back();
      Get.snackbar("Berhasil", "Nilai $jenisNilai berhasil disimpan.");
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); }
    finally { isSaving.value = false; }
  }

  // void hitungNilaiAkhir() {
  //   if (bobotNilai.isEmpty) {
  //     nilaiAkhir.value = 0.0;
  //     return;
  //   }
    
  //   double avgTugasHarian = _calculateAverage("Harian/PR");
  //   double avgUlanganHarian = _calculateAverage('Ulangan Harian');
  //   double totalNilaiTambahan = _calculateSum('Nilai Tambahan');
  //   int pts = nilaiPTS.value ?? 0;
  //   int pas = nilaiPAS.value ?? 0;

  //   int bobotTugas = bobotNilai['tugasHarian'] ?? 0;
  //   int bobotUlangan = bobotNilai['ulanganHarian'] ?? 0;
  //   int bobotPTS = bobotNilai['pts'] ?? 0;
  //   int bobotPAS = bobotNilai['pas'] ?? 0;
    
  //   int totalBobot = bobotTugas + bobotUlangan + bobotPTS + bobotPAS;
  //   if (totalBobot == 0) {
  //     nilaiAkhir.value = 0.0;
  //     return;
  //   }
    
  //   double finalScore = 
  //       ((avgTugasHarian * bobotTugas) +
  //       (avgUlanganHarian * bobotUlangan) +
  //       (pts * bobotPTS) +
  //       (pas * bobotPAS)) / totalBobot; 
    
  //   finalScore += totalNilaiTambahan;

  //   nilaiAkhir.value = finalScore.clamp(0.0, 100.0);
    
  //   siswaMapelRef.set({
  //     'nilai_akhir': nilaiAkhir.value,
  //     'namaMapel': namaMapel,
  //     'namaGuru': namaGuru, // Nama guru pengampu mapel
  //     'idGuru': idGuru,     // ID guru pengampu mapel
  //     'aliasGuruPencatatAkhir': aliasGuruPencatat, // [PERBAIKAN] Simpan alias guru pencatat/pengampu ke field 'aliasGuruPencatatAkhir'
  //     'idGuruPencatatAkhir': idGuruPencatat,
  //     'namaGuruPencatatAkhir': namaGuruPencatat,
  //     'lastEdited': FieldValue.serverTimestamp(),
  //   }, SetOptions(merge: true));
  // }

  void hitungNilaiAkhir() {
    if (bobotNilai.isEmpty) {
      nilaiAkhir.value = 0.0;
      return;
    }
    
    // 1. Hitung rata-rata untuk setiap komponen
    double avgTugasHarian = _calculateAverage("Harian/PR");
    double avgUlanganHarian = _calculateAverage('Ulangan Harian');
    double avgNilaiTambahan = _calculateAverage('Nilai Tambahan'); // Diperlakukan sebagai rata-rata
    int pts = nilaiPTS.value ?? 0;
    int pas = nilaiPAS.value ?? 0;

    // 2. Ambil bobot dari state
    int bobotTugas = bobotNilai['tugasHarian'] ?? 0;
    int bobotUlangan = bobotNilai['ulanganHarian'] ?? 0;
    int bobotTambahan = bobotNilai['nilaiTambahan'] ?? 0; // Ambil bobot nilai tambahan
    int bobotPTS = bobotNilai['pts'] ?? 0;
    int bobotPAS = bobotNilai['pas'] ?? 0;
    
    // 3. Hitung total pembagi bobot
    int totalBobot = bobotTugas + bobotUlangan + bobotTambahan + bobotPTS + bobotPAS;
    if (totalBobot == 0) {
      nilaiAkhir.value = 0.0;
      return;
    }
    
    // 4. Hitung nilai akhir murni berdasarkan bobot
    double finalScore = 
        ((avgTugasHarian * bobotTugas) +
        (avgUlanganHarian * bobotUlangan) +
        (avgNilaiTambahan * bobotTambahan) + // Masukkan nilai tambahan ke dalam rata-rata berbobot
        (pts * bobotPTS) +
        (pas * bobotPAS)) / totalBobot; 
    
    nilaiAkhir.value = finalScore.clamp(0.0, 100.0);
    
    // 5. Simpan semua hasil perhitungan ke Firestore
    siswaMapelRef.set({
      'nilai_akhir': nilaiAkhir.value,
      'rata_rata_tugas': avgTugasHarian,
      'rata_rata_ulangan': avgUlanganHarian,
      'rata_rata_tambahan': avgNilaiTambahan,
      // Field lain yang sudah ada juga di-set di sini
      'namaMapel': namaMapel,
      'namaGuru': namaGuru,
      'idGuru': idGuru,
      'aliasGuruPencatatAkhir': aliasGuruPencatat,
      'idGuruPencatatAkhir': idGuruPencatat,
      'namaGuruPencatatAkhir': namaGuruPencatat,
      'lastEdited': FieldValue.serverTimestamp(),
      'kelasId': idKelas, // Pastikan field ini juga tersimpan
      'semester': int.parse(semesterAktif), // Pastikan field ini juga tersimpan
    }, SetOptions(merge: true));
  }
  
  double _calculateAverage(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) {
      if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
      return n.kategori == kategori;
    }).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai) / listNilai.length;
  }
  
  double _calculateSum(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai).toDouble();
  }
}