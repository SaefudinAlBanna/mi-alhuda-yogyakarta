import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/pegawai_simple_model.dart';

class HalaqahUmmiManajemenPengujiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final List<PegawaiSimpleModel> _allPengampu = [];
  final RxMap<String, bool> pengujiStatus = <String, bool>{}.obs;

  // --- [PERBAIKAN] Definisikan DocumentReference di sini agar konsisten ---
  DocumentReference get _configDocRef => _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('pengaturan').doc('halaqah_ummi_config');

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      final Set<String> daftarPengujiAktif = await _fetchDaftarPengujiAktif();
      await _fetchAllPengampuCandidates();
      _gabungkanData(daftarPengujiAktif);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penguji: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<Set<String>> _fetchDaftarPengujiAktif() async {
    // --- [PERBAIKAN] Path disederhanakan ---
    final doc = await _configDocRef.get();
    
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['daftarPenguji'] as Map<String, dynamic>?)?.keys.toSet() ?? {};
    }
    return {};
  }

  Future<void> _fetchAllPengampuCandidates() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    final List<PegawaiSimpleModel> eligible = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      final tugas = List<String>.from(data['tugas'] ?? []);
      if (role == 'Pengampu' || tugas.contains('Pengampu')) {
        eligible.add(PegawaiSimpleModel.fromFirestore(doc));
      }
    }
    eligible.sort((a, b) => a.nama.compareTo(b.nama));
    _allPengampu.assignAll(eligible);
  }

  void _gabungkanData(Set<String> daftarPengujiAktif) {
    pengujiStatus.clear();
    for (var pengampu in _allPengampu) {
      pengujiStatus[pengampu.uid] = daftarPengujiAktif.contains(pengampu.uid);
    }
  }

  void togglePenguji(String uid, bool isSelected) {
    pengujiStatus[uid] = isSelected;
  }

  Future<void> simpanPerubahan() async {
    isSaving.value = true;
    try {
      final Map<String, dynamic> dataToSave = {};
      
      // Cari semua pegawai yang statusnya 'true'
      for (var pengampu in _allPengampu) {
        if (pengujiStatus[pengampu.uid] == true) {
          // --- REVISI DI SINI ---
          // Gunakan getter 'displayName' dari model yang secara otomatis
          // memilih alias, dan fallback ke nama jika alias kosong.
          dataToSave[pengampu.uid] = pengampu.displayName;
          // --- AKHIR REVISI ---
        }
      }
  
      // Simpan ke Firestore
      await _configDocRef.set({
        'daftarPenguji': dataToSave,
      }, SetOptions(merge: true));
  
      Get.back();
      Get.snackbar("Berhasil", "Daftar penguji munaqosyah telah diperbarui.");
  
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }

  List<PegawaiSimpleModel> get allPengampu => _allPengampu;
}