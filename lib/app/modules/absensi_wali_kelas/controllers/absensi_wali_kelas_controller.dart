import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_absensi_model.dart'; // Buat model baru ini (lihat di bawah)

class AbsensiWaliKelasController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State
  final isLoading = true.obs;
  final isSaving = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<SiswaAbsensiModel> daftarSiswa = <SiswaAbsensiModel>[].obs;

  // Info Kontekstual
  late String kelasDiampu;
  String get tanggalTerformat => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    kelasDiampu = configC.infoUser['kelasDiampu'] ?? '';
    if (kelasDiampu.isNotEmpty) {
      _loadDataForSelectedDate();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _loadDataForSelectedDate() async {
    isLoading.value = true;
    try {
      // 1. Ambil daftar siswa dari path yang baru dan stabil
      final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(kelasDiampu)
          .collection('daftarsiswa').orderBy('namaLengkap').get();

      final List<SiswaAbsensiModel> tempList = [];
      final List<Future<void>> futures = [];

      for (var doc in siswaSnapshot.docs) {
        final siswa = SiswaAbsensiModel(uid: doc.id, nama: doc.data()['namaLengkap'] ?? 'Tanpa Nama');
        tempList.add(siswa);
        
        // 2. Untuk setiap siswa, ambil status absensinya hari ini
        futures.add(_fetchAbsensiForSiswa(siswa));
      }

      await Future.wait(futures);
      daftarSiswa.assignAll(tempList);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAbsensiForSiswa(SiswaAbsensiModel siswa) async {
    final absensiDoc = await _getAbsensiSiswaRef(siswa.uid).get();
    if (absensiDoc.exists) {
      // --- [PERBAIKAN] Casting eksplisit ke Map ---
      final data = absensiDoc.data() as Map<String, dynamic>?;
      siswa.status.value = data?['status'] ?? 'Hadir';
      // --- AKHIR PERBAIKAN ---
    } else {
      siswa.status.value = 'Hadir';
    }
  }

  DocumentReference _getAbsensiSiswaRef(String uidSiswa) {
    return _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').doc(kelasDiampu)
        .collection('daftarsiswa').doc(uidSiswa)
        .collection('semester').doc(configC.semesterAktif.value)
        .collection('absensi_siswa').doc(tanggalTerformat);
  }

  void ubahStatusAbsensi(SiswaAbsensiModel siswa, String status) {
    siswa.status.value = status;
  }

  Future<void> simpanAbsensi() async {
    isSaving.value = true;
    try {
      WriteBatch batch = _firestore.batch();
      
      final Map<String, dynamic> dataRekapHarian = {};
      int hadir = 0, sakit = 0, izin = 0, alfa = 0;

      for (var siswa in daftarSiswa) {
        final ref = _getAbsensiSiswaRef(siswa.uid);
        batch.set(ref, {
          'status': siswa.status.value,
          'tanggal': selectedDate.value,
          'idWaliKelas': configC.infoUser['uid'],
          'namaWaliKelas': configC.infoUser['alias'] ?? configC.infoUser['nama']
        });
        
        dataRekapHarian[siswa.uid] = {
            'nama': siswa.nama,
            'status': siswa.status.value,
        };

        switch (siswa.status.value) {
          case 'Hadir': hadir++; break;
          case 'Sakit': sakit++; break;
          case 'Izin': izin++; break;
          case 'Alfa': alfa++; break;
        }
      }
      
      final rekapRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(kelasDiampu)
          .collection('semester').doc(configC.semesterAktif.value)
          .collection('absensi').doc(tanggalTerformat);
      
      // [PERBAIKAN KUNCI DI SINI]
      batch.set(rekapRef, {
        'rekap': {'hadir': hadir, 'sakit': sakit, 'izin': izin, 'alfa': alfa},
        'tanggal': Timestamp.fromDate(selectedDate.value),
        'timestamp': FieldValue.serverTimestamp(),
        // Tambahkan informasi Wali Kelas ke dalam rekap harian
        'idWaliKelas': configC.infoUser['uid'],
        'namaWaliKelas': configC.infoUser['alias'] ?? configC.infoUser['nama'],
        ...dataRekapHarian,
      });

      await batch.commit();
      Get.snackbar("Berhasil", "Absensi untuk tanggal ${DateFormat('dd MMM yyyy').format(selectedDate.value)} telah disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan absensi: $e");
    } finally {
      isSaving.value = false;
    }
  }

  void onDateChanged(DateTime newDate) {
    selectedDate.value = newDate;
    _loadDataForSelectedDate();
  }
}