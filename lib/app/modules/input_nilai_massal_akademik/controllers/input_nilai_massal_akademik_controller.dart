// lib/app/modules/input_nilai_massal_akademik/controllers/input_nilai_massal_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/auth_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_model.dart';

import '../../manajemen_tugas/controllers/manajemen_tugas_controller.dart';

class InputNilaiMassalAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController _authController = Get.find<AuthController>();

  // --- DATA KONTEKS DARI ARGUMEN ---
  late String idKelas;
  late String idMapel;
  late String namaMapel;
  late String judulTugas;
  late String kategoriTugas;
  String? idTugasUlangan;

  // --- STATE UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;

  // --- STATE DATA & FORM ---
  final daftarSiswa = <SiswaModel>[].obs;
  final filteredSiswa = <SiswaModel>[].obs;
  final textControllers = <String, TextEditingController>{}.obs;
  final absentStudents = <String>{}.obs;
  final searchController = TextEditingController();

  late String idGuruPencatat;
  late String namaGuruPencatat;
  late String aliasGuruPencatat;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idKelas = args['idKelas'] ?? '';
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? '';
    judulTugas = args['judulTugas'] ?? 'Tugas';
    kategoriTugas = args['kategoriTugas'] ?? 'Harian/PR';
    idTugasUlangan = args['idTugasUlangan'];

    idGuruPencatat = _authController.auth.currentUser!.uid;
    namaGuruPencatat = configC.infoUser['nama'] ?? 'Guru Tidak Dikenal';
    aliasGuruPencatat = configC.infoUser['alias'] ?? namaGuruPencatat;

    searchController.addListener(() => filterSiswa(searchController.text));

    ever(configC.isUserDataReady, (isReady) {
      if (isReady) _fetchSiswaAndPrepareForm();
    });
    if (configC.isUserDataReady.value) {
      _fetchSiswaAndPrepareForm();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> _fetchSiswaAndPrepareForm() async {
    isLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        throw Exception("Tahun ajaran tidak aktif.");
      }

      // 1. Ambil daftar siswa dari kelas
      final siswaSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa')
          .orderBy('namaLengkap')
          .get();
      
      final List<String> siswaUIDs = siswaSnap.docs.map((doc) => doc.id).toList();
      
      if (siswaUIDs.isEmpty) {
        daftarSiswa.clear();
        filteredSiswa.clear();
        isLoading.value = false;
        return;
      }
        
      final siswaDetailSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where(FieldPath.documentId, whereIn: siswaUIDs).get();
      
      final allSiswa = siswaDetailSnap.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
      allSiswa.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));

      daftarSiswa.assignAll(allSiswa);
      filteredSiswa.assignAll(allSiswa);

      // 2. Siapkan text controller untuk setiap siswa
      for (var siswa in daftarSiswa) {
        textControllers[siswa.uid] = TextEditingController();
      }

      // 3. Jika ini adalah penilaian untuk tugas spesifik, ambil nilai terakhir
      if (idTugasUlangan != null) {
        final Map<String, int> nilaiTerakhirSiswa = {};

        // Query untuk setiap siswa untuk mendapatkan nilai terakhirnya untuk tugas ini
        for (final siswa in daftarSiswa) {
          final nilaiSnap = await _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(tahunAjaran)
              .collection('kelastahunajaran').doc(idKelas)
              .collection('daftarsiswa').doc(siswa.uid)
              .collection('semester').doc(configC.semesterAktif.value)
              .collection('matapelajaran').doc(idMapel)
              .collection('nilai_harian')
              .where('idTugasUlangan', isEqualTo: idTugasUlangan)
              .orderBy('tanggal', descending: true)
              .limit(1)
              .get();
          
          if (nilaiSnap.docs.isNotEmpty) {
            nilaiTerakhirSiswa[siswa.uid] = nilaiSnap.docs.first.data()['nilai'] as int;
          }
        }

        // 4. Isi text controller dengan nilai yang sudah ada
        for (var siswa in daftarSiswa) {
          if (nilaiTerakhirSiswa.containsKey(siswa.uid)) {
            textControllers[siswa.uid]?.text = nilaiTerakhirSiswa[siswa.uid].toString();
          }
        }
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data siswa: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void filterSiswa(String query) {
    if (query.isEmpty) {
      filteredSiswa.assignAll(daftarSiswa);
    } else {
      filteredSiswa.assignAll(daftarSiswa.where(
          (siswa) => siswa.namaLengkap.toLowerCase().contains(query.toLowerCase())));
    }
  }

  void toggleAbsen(String uid) {
    if (absentStudents.contains(uid)) {
      absentStudents.remove(uid);
    } else {
      absentStudents.add(uid);
    }
  }

  Future<void> simpanNilaiMassal() async {
    isSaving.value = true;
    final WriteBatch batch = _firestore.batch();
    int validGradesCount = 0; 

    try {
      for (final siswa in daftarSiswa) {
        if (absentStudents.contains(siswa.uid)) continue; 

        final controller = textControllers[siswa.uid];
        final nilaiString = controller?.text.trim();  

        if (nilaiString == null || nilaiString.isEmpty) continue; 

        final int? nilai = int.tryParse(nilaiString); 

        if (nilai == null || nilai < 0 || nilai > 100) {
          Get.snackbar("Input Tidak Valid", "Nilai untuk ${siswa.namaLengkap} tidak valid (harus 0-100).");
          isSaving.value = false;
          return;
        } 

        validGradesCount++; 

        final siswaMapelRef = _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(siswa.uid)
            .collection('semester').doc(configC.semesterAktif.value)
            .collection('matapelajaran').doc(idMapel);
        
        batch.set(siswaMapelRef, {
          'idMapel': idMapel, 'namaMapel': namaMapel, 'idGuru': idGuruPencatat,
          'namaGuru': namaGuruPencatat, 'aliasGuruPencatatAkhir': aliasGuruPencatat,
        }, SetOptions(merge: true));  

        final nilaiRef = siswaMapelRef.collection('nilai_harian').doc(); 
        
        // [PERBAIKAN KUNCI DI SINI] Tambahkan semua field yang dibutuhkan
        batch.set(nilaiRef, {
          'kategori': kategoriTugas, 
          'nilai': nilai, 
          'catatan': judulTugas,
          'tanggal': Timestamp.now(), 
          'idGuruPencatat': idGuruPencatat,
          'namaGuruPencatat': namaGuruPencatat, 
          'aliasGuruPencatat': aliasGuruPencatat,
          'idTugasUlangan': idTugasUlangan,
          'idSekolah': configC.idSekolah,
          'idMapel': idMapel,
          'kelasId': idKelas,
          'semester': int.parse(configC.semesterAktif.value),
        }); 

        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        
        final notifRef = siswaDocRef.collection('notifikasi').doc();
        batch.set(notifRef, {
          'judul': 'Nilai Baru: $namaMapel',
          'isi': 'Ananda ${siswa.namaLengkap} mendapatkan nilai $nilai untuk "$judulTugas".',
          'tipe': 'NILAI_MAPEL',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
          'idSekolah': configC.idSekolah,
        }); 

        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, 
        SetOptions(merge: true));
      } 

      if (validGradesCount == 0) {
        Get.snackbar("Informasi", "Tidak ada nilai baru yang diinput untuk disimpan.",
          backgroundColor: Colors.blueAccent, colorText: Colors.white,
        );
        isSaving.value = false;
        return;
      } 

      await batch.commit();
      
      if (Get.isRegistered<ManajemenTugasController>()) {
        final mtController = Get.find<ManajemenTugasController>();
        mtController.fetchTugas();
      }
      Get.back();   

      Get.snackbar("Berhasil", "$validGradesCount nilai berhasil disimpan.",
        backgroundColor: Colors.green, colorText: Colors.white,
      );  

    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat menyimpan: ${e.toString()}",
        backgroundColor: Colors.red, colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
}