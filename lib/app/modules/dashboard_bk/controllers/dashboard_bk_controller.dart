import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';

class DashboardBkController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  
  // Untuk dropdown
  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();

  // Daftar siswa
  final RxList<SiswaModel> daftarSiswa = <SiswaModel>[].obs;
  final RxSet<String> siswaDenganCatatan = <String>{}.obs; // Set untuk performa

  // Kontrol UI
  final RxBool canSelectClass = false.obs;
  final RxString title = 'Dashboard BK'.obs;

  // --- [PROPERTI BARU UNTUK FILTER & SEARCH] ---
  final TextEditingController searchC = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool showOnlyWithNotes = false.obs;

  // --- [BARU] Getter Reaktif untuk Menampilkan Data ---
  // UI akan selalu "mendengarkan" getter ini.
  RxList<SiswaModel> get filteredSiswaList {
    List<SiswaModel> _filtered = List.from(daftarSiswa);

    // Filter 1: Hanya yang punya catatan
    if (showOnlyWithNotes.value) {
      _filtered = _filtered.where((siswa) => siswaDenganCatatan.contains(siswa.uid)).toList();
    }

    // Filter 2: Pencarian
    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      _filtered = _filtered.where((siswa) => 
        siswa.namaLengkap.toLowerCase().contains(query) || 
        siswa.nisn.contains(query)
      ).toList();
    }

    return _filtered.obs; // Kembalikan sebagai RxList
  }


  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    final user = configC.infoUser;
    final String userRole = user['role'] ?? '';
    final List userTugas = user['tugas'] ?? [];
    final String? kelasWali = user['waliKelasDari'];

    // Listener untuk memuat data siswa saat kelas dipilih
    ever(selectedKelasId, (String? kelasId) {
      if (kelasId != null) {
        _fetchSiswaDanCatatan(kelasId);
      }
    });

    if (userRole == 'Kepala Sekolah' || userTugas.contains('Kesiswaan')) {
      canSelectClass.value = true;
      title.value = 'Pantauan Catatan BK';
      await _fetchDaftarKelas();
      
      // --- [PERBAIKAN DI SINI] ---
      // Jika ada kelas, langsung set kelas pertama sebagai pilihan
      // DAN panggil fetch secara manual. Listener 'ever' tidak akan
      // langsung terpanggil saat inisialisasi.
      if (daftarKelas.isNotEmpty) {
        final firstClassId = daftarKelas.first['id'];
        selectedKelasId.value = firstClassId;
        await _fetchSiswaDanCatatan(firstClassId!); // Panggil manual
      } else {
        isLoading.value = false; // Hentikan loading jika tidak ada kelas sama sekali
      }
      // -----------------------------

    } else if (kelasWali != null && kelasWali.isNotEmpty) {
      canSelectClass.value = false;
      title.value = 'Catatan BK Kelas ${kelasWali.split('-').first}';
      selectedKelasId.value = kelasWali;
      await _fetchSiswaDanCatatan(kelasWali); // Panggil manual
    }
  }

  Future<void> _fetchDaftarKelas() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran)
        .orderBy('namaKelas').get();
    daftarKelas.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      // Lakukan casting secara eksplisit ke String.
      final String namaKelas = (data['namaKelas'] as String?) ?? doc.id.split('-').first;
      return {
        'id': doc.id,
        'nama': namaKelas,
      };
    }).toList());
  }

  Future<void> _fetchSiswaDanCatatan(String kelasId) async {
    isLoading.value = true;
    daftarSiswa.clear();
    siswaDenganCatatan.clear(); // Kita tetap gunakan set ini untuk UI
    try {
      // 1. Ambil semua siswa di kelas tersebut. Query ini sudah termasuk
      // data 'memilikiCatatanBk' karena sudah kita tambahkan di model.
      final siswaSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where('kelasId', isEqualTo: kelasId)
          .orderBy('namaLengkap').get();
      
      final siswaList = siswaSnap.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
      daftarSiswa.assignAll(siswaList);

      if (siswaList.isEmpty) return;

      // 2. Cukup filter dari data yang sudah kita dapatkan. TIDAK ADA QUERY TAMBAHAN!
      final Set<String> siswaIdsWithNotes = {};
      for (var siswa in siswaList) {
        if (siswa.memilikiCatatanBk) {
          siswaIdsWithNotes.add(siswa.uid);
        }
      }
      siswaDenganCatatan.assignAll(siswaIdsWithNotes);

    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: ${e.toString()}');
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  void goToCatatanSiswa(SiswaModel siswa) {
    Get.toNamed(Routes.CATATAN_BK_LIST, arguments: {
      'siswaId': siswa.uid,
      'siswaNama': siswa.namaLengkap,
    });
  }
}