import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../models/siswa_keuangan_model.dart';

class PengaturanBiayaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isAuthorized = false.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isSavingUangPangkal = false.obs;

  final daftarUlangC = TextEditingController();
  final uangKegiatanC = TextEditingController();
  
  final RxList<SiswaKeuanganModel> daftarSiswaKelas1 = <SiswaKeuanganModel>[].obs;
  final RxMap<String, TextEditingController> uangPangkalControllers = <String, TextEditingController>{}.obs;

  late DocumentReference _masterBiayaRef;
  int _defaultUangPangkal = 0;

  @override
  void onInit() {
    super.onInit();
    _checkAuthorization();
    if (isAuthorized.value) {
      _initialize();
    } else {
      isLoading.value = false;
    }
  }

  void _checkAuthorization() {
    final dashboardC = Get.find<DashboardController>();
    final userRole = configC.infoUser['role'] ?? '';
    isAuthorized.value = dashboardC.isPimpinan || userRole == 'Bendahara';
  }

  void _initialize() {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    _masterBiayaRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('pengaturan').doc('master_biaya');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _fetchMasterBiaya();
      await _fetchSiswaKelas1();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMasterBiaya() async {
    final doc = await _masterBiayaRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      daftarUlangC.text = (data['daftarUlang'] ?? 0).toString();
      uangKegiatanC.text = (data['uangKegiatan'] ?? 0).toString();
      _defaultUangPangkal = (data['uangPangkal'] ?? 0);
    }
  }

  Future<void> _fetchSiswaKelas1() async {
    final kelasSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas')
        .where('namaKelas', whereIn: ['1A', '1B', '1C', '1D', '1E', '1F'])
        .where('tahunAjaran', isEqualTo: configC.tahunAjaranAktif.value)
        .get();
    
    final List<String> kelas1Ids = kelasSnap.docs.map((d) => d.id).toList();

    if (kelas1Ids.isNotEmpty) {
      final siswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa')
          .where('kelasId', whereIn: kelas1Ids).get();
      
      final siswaList = siswaSnap.docs.map((d) => SiswaKeuanganModel.fromFirestore(d)).toList();
      daftarSiswaKelas1.assignAll(siswaList);

      for (var siswa in daftarSiswaKelas1) {
        final nominal = siswa.uangPangkalDitetapkan > 0 ? siswa.uangPangkalDitetapkan : _defaultUangPangkal;
        uangPangkalControllers[siswa.uid] = TextEditingController(text: nominal.toString());
      }
    }
  }

  Future<void> simpanMasterBiaya() async {
    isSaving.value = true;
    try {
      final pencatatUid = configC.infoUser['uid'] ?? 'unknown';
      final pencatatNama = configC.infoUser['alias'] ?? configC.infoUser['nama'] ?? 'Unknown';
      
      await _masterBiayaRef.set({
        'daftarUlang': int.tryParse(daftarUlangC.text) ?? 0,
        'uangKegiatan': int.tryParse(uangKegiatanC.text) ?? 0,
        'uangPangkal': _defaultUangPangkal, // Tetap simpan default-nya
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': { 'uid': pencatatUid, 'nama': pencatatNama },
      }, SetOptions(merge: true));

      Get.snackbar("Berhasil", "Data master biaya telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> simpanUangPangkalSiswa() async {
    for (var controller in uangPangkalControllers.values) {
      final nominal = int.tryParse(controller.text) ?? 0;
      if (nominal <= 0) {
        Get.snackbar("Peringatan", "Semua nominal Uang Pangkal wajib diisi dan tidak boleh nol.", backgroundColor: Colors.orange);
        return;
      }
    }

    isSavingUangPangkal.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      for (var siswa in daftarSiswaKelas1) {
        final nominal = int.tryParse(uangPangkalControllers[siswa.uid]!.text) ?? 0;
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        
        batch.set(siswaRef, {
          'uangPangkal': { 'totalTagihan': nominal, 'totalTerbayar': 0, 'status': 'Belum Lunas' }
        }, SetOptions(merge: true));
      }
      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "Data Uang Pangkal siswa kelas 1 telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data Uang Pangkal: ${e.toString()}");
    } finally {
      isSavingUangPangkal.value = false;
    }
  }

  @override
  void onClose() {
    daftarUlangC.dispose();
    uangKegiatanC.dispose();
    uangPangkalControllers.values.forEach((c) => c.dispose());
    super.onClose();
  }
}