// lib/app/modules/guru_akademik/controllers/guru_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/mapel_diampu_model.dart';
import '../../../routes/app_pages.dart';

class GuruAkademikController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State UI
  final isLoading = true.obs;
  
  // State Data (Struktur Baru untuk UI ChoiceChip)
  final RxMap<String, List<MapelDiampuModel>> mapelPerKelas = <String, List<MapelDiampuModel>>{}.obs;
  final RxList<String> daftarIdKelas = <String>[].obs;
  final Rxn<String> kelasTerpilihId = Rxn<String>();
  final RxList<MapelDiampuModel> mapelDiKelasTerpilih = <MapelDiampuModel>[].obs;

  // State Wali Kelas
  final RxBool isWaliKelas = false.obs;
  final RxString kelasDiampuId = "".obs;

  @override
  void onInit() {
    super.onInit();
    ever(configC.infoUser, (_) => _updateWaliKelasStatus());
  }

  @override
  void onReady() {
    super.onReady();
    fetchMapelDiampu();
    _updateWaliKelasStatus();
  }

  void _updateWaliKelasStatus() {
    final hasKelasDiampu = configC.infoUser.containsKey('kelasDiampu');
    isWaliKelas.value = hasKelasDiampu;
    if (hasKelasDiampu) {
      kelasDiampuId.value = configC.infoUser['kelasDiampu'] ?? '';
    } else {
      kelasDiampuId.value = '';
    }
  }

  Future<void> fetchMapelDiampu() async {
    isLoading.value = true;
    try {
      final String uid = _auth.currentUser!.uid;
      final String tahunAjaran = configC.tahunAjaranAktif.value;
  
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        throw Exception("Tahun ajaran tidak valid.");
      }
  
      final List<MapelDiampuModel> listMapelFinal = [];
      final Set<String> uniqueMapelKeys = {};
  
      // [SUMBER 1: JADWAL REGULER - PATH AMAN]
      final jadwalRegulerSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').doc(uid)
          .collection('jadwal_mengajar').doc(tahunAjaran)
          .collection('mapel_diampu')
          .get();
  
      for (var doc in jadwalRegulerSnap.docs) {
        final mapel = MapelDiampuModel.fromFirestore(doc, isPengganti: false);
        final key = "${mapel.idKelas}-${mapel.idMapel}";
        if (uniqueMapelKeys.add(key)) {
          listMapelFinal.add(mapel);
        }
      }
  
      // [SUMBER 2: PENGGANTIAN RENTANG WAKTU]
      final now = DateTime.now();
      final penggantianRentangSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('penggantianAkademik')
          .where('idGuruPengganti', isEqualTo: uid)
          .where('status', isEqualTo: 'aktif')
          .get();
  
      for (var doc in penggantianRentangSnap.docs) {
        final data = doc.data();
        final tanggalMulai = (data['tanggalMulai'] as Timestamp).toDate();
        final tanggalSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
  
        if ((now.isAfter(tanggalMulai) || now.isAtSameMomentAs(tanggalMulai)) && 
            (now.isBefore(tanggalSelesai) || now.isAtSameMomentAs(tanggalSelesai))) {
            
          final List<dynamic> jadwalSalinan = data['jadwalYangDigantikan'] ?? [];
  
          for (var mapelData in jadwalSalinan) {
            if (mapelData is Map<String, dynamic>) {
              final mapel = MapelDiampuModel(
                idMapel: mapelData['idMapel'] ?? '',
                namaMapel: mapelData['namamatapelajaran'] ?? 'N/A',
                idKelas: mapelData['idKelas'] ?? '',
                idGuru: uid,
                namaGuru: configC.infoUser['nama'] ?? 'Pengganti',
                isPengganti: true,
                namaGuruAsli: data['namaGuruAsli'],
              );
              final key = "${mapel.idKelas}-${mapel.idMapel}";
              if (uniqueMapelKeys.add(key)) {
                listMapelFinal.add(mapel);
              }
            }
          }
        }
      }
  
      // [SUMBER 3: PENGGANTIAN INSIDENTAL (PER SESI)]
      final tanggalStr = DateFormat('yyyy-MM-dd').format(now);
      final penggantianSesiSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('sesi_pengganti_kbm')
          .where('idGuruPengganti', isEqualTo: uid)
          .where('tanggal', isEqualTo: tanggalStr)
          .get();
  
      for (var doc in penggantianSesiSnap.docs) {
        final data = doc.data();
        final mapel = MapelDiampuModel(
          idMapel: data['idMapel'] ?? '',
          namaMapel: data['namaMapel'] ?? 'Tugas Harian', 
          idKelas: data['idKelas'] ?? '',
          idGuru: uid,
          namaGuru: data['namaGuruPengganti'] ?? 'Pengganti',
          isPengganti: true,
          namaGuruAsli: data['namaGuruAsli'],
        );
        final key = "${mapel.idKelas}-${mapel.idMapel}";
        if (uniqueMapelKeys.add(key)) {
          listMapelFinal.add(mapel);
        }
      }
  
      // [FINALISASI & PEMROSESAN DATA UNTUK UI BARU]
      final Map<String, List<MapelDiampuModel>> tempMap = {};
      for (var mapel in listMapelFinal) {
        if (tempMap[mapel.idKelas] == null) {
          tempMap[mapel.idKelas] = [];
        }
        tempMap[mapel.idKelas]!.add(mapel);
      }
      
      mapelPerKelas.value = tempMap;
      daftarIdKelas.value = tempMap.keys.toList()..sort();
  
      if (daftarIdKelas.isNotEmpty) {
        pilihKelas(daftarIdKelas.first);
      } else {
        // Pastikan state bersih jika tidak ada mapel sama sekali
        kelasTerpilihId.value = null;
        mapelDiKelasTerpilih.clear();
      }
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data mengajar: ${e.toString()}");
      print("### GURU AKADEMIK ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void pilihKelas(String idKelas) {
    kelasTerpilihId.value = idKelas;
    mapelDiKelasTerpilih.value = mapelPerKelas[idKelas] ?? [];
    mapelDiKelasTerpilih.sort((a, b) => a.namaMapel.compareTo(b.namaMapel));
  }

  void goToDaftarSiswaPermapel(MapelDiampuModel mapel) {
    // Navigasi ke halaman selanjutnya dengan membawa semua data yang dibutuhkan
    Get.toNamed(
      Routes.DAFTAR_SISWA_PERMAPEL,
      arguments: {
        'idKelas': mapel.idKelas,
        'idMapel': mapel.idMapel,
        'namaMapel': mapel.namaMapel,
        // 'idGuru': mapel.idGuru,
        // 'namaGuru': mapel.namaGuru,
        'idGuru': _auth.currentUser!.uid, 
        'namaGuru': configC.infoUser['nama'] ?? 'Pengguna',
        'isPengganti': mapel.isPengganti,
      },
    );
  }

  void goToAbsensi() {
    Get.toNamed(Routes.ABSENSI_WALI_KELAS);
  }

  void goToRekapAbsensiKelas() {
    Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'kelas', 'id': kelasDiampuId.value});
  }
}