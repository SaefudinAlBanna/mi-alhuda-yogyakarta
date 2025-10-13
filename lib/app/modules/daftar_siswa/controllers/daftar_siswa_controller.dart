import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';
import '../../../routes/app_pages.dart';

class DaftarSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State Utama
  final isLoading = true.obs;
  final RxList<SiswaModel> _semuaSiswa = <SiswaModel>[].obs;
  final RxList<SiswaModel> daftarSiswaFiltered = <SiswaModel>[].obs;
  
  // State untuk Filter
  final TextEditingController searchC = TextEditingController();
  final searchQuery = "".obs;
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>(); // null artinya "Semua Kelas"

  // Hak Akses
  bool get canManageSiswa {
    final user = configC.infoUser;
    if (user.isEmpty) return false;

    // Peran yang diizinkan untuk mengelola data siswa
    const allowedRoles = ['Admin', 'TU', 'Tata Usaha', 'Kepala Sekolah']; 
    if (user['peranSistem'] == 'superadmin' || allowedRoles.contains(user['role'])) {
      return true;
    }

    // --- [PERBAIKAN LOGIKA] Cek setiap item di dalam list tugas ---
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    const allowedTugas = ['Koordinator Kurikulum'];
    
    // Jika salah satu tugas yang dimiliki user ada di dalam daftar yang diizinkan, return true
    return tugas.any((tugasUser) => allowedTugas.contains(tugasUser));
    // --- AKHIR PERBAIKAN ---
  }

  @override
  void onInit() {
    super.onInit();
    initializeData();
    // Listener untuk memfilter secara reaktif
    ever(searchQuery, (_) => _filterData());
    ever(selectedKelasId, (_) => _filterData());
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      // Ambil data siswa dan kelas secara bersamaan untuk efisiensi
      await Future.wait([
        _fetchSiswa(),
        _fetchDaftarKelas(),
      ]);
      _filterData(); // Terapkan filter awal (tampilkan semua)
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchSiswa() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').orderBy('namaLengkap').get();
    _semuaSiswa.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
  }

  Future<void> _fetchDaftarKelas() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran)
        .orderBy('namaKelas').get();

    // --- [PERBAIKAN] Pastikan nama kelas selalu pendek dan bersih ---
    daftarKelas.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      // Ambil 'namaKelas' dari data, jika tidak ada, ambil dari ID dokumen dan potong.
      final String namaTampilan = data['namaKelas'] ?? doc.id.split('-').first;
      return {'id': doc.id, 'nama': namaTampilan};
    }).toList());
    // --- AKHIR PERBAIKAN ---
  }

  void _filterData() {
    List<SiswaModel> filteredList = List<SiswaModel>.from(_semuaSiswa);

    // --- FILTER LAPIS 1: KELAS ---
    if (selectedKelasId.value != null) {
      filteredList = filteredList.where((siswa) => siswa.kelasId == selectedKelasId.value).toList();
    }

    // --- FILTER LAPIS 2: PENCARIAN (NAMA/NISN) ---
    String query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((siswa) {
        return siswa.namaLengkap.toLowerCase().contains(query) || siswa.nisn.contains(query);
      }).toList();
    }
    
    daftarSiswaFiltered.assignAll(filteredList);
  }

  void goToImportSiswa() => Get.toNamed(Routes.IMPORT_SISWA);
  
  void goToTambahSiswa() async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA);
    if (result == true) initializeData();
  }

  void goToEditSiswa(SiswaModel siswa) async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA, arguments: siswa);
    if (result == true) initializeData();
  }
}