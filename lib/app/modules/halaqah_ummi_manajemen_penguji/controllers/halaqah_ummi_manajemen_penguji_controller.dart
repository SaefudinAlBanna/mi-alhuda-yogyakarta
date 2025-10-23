import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/pegawai_simple_model.dart';

class HalaqahUmmiManajemenPengujiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final List<PegawaiSimpleModel> _allPegawai = [];
  final RxList<PegawaiSimpleModel> kandidatPenguji = <PegawaiSimpleModel>[].obs;
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
      // Ambil data secara paralel
      final results = await Future.wait([
        _fetchDaftarPengujiAktif(),
        _fetchAllPegawai(),
      ]);

      final Set<String> daftarPengujiAktif = results[0] as Set<String>;
      
      _gabungkanDanFilterData(daftarPengujiAktif);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penguji: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<Set<String>> _fetchDaftarPengujiAktif() async {
    final doc = await _configDocRef.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      // Ambil semua UID dari map 'daftarPenguji'
      return (data['daftarPenguji'] as Map<String, dynamic>?)?.keys.toSet() ?? {};
    }
    return {};
  }

  Future<void> _fetchAllPegawai() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('pegawai').get();
    
    _allPegawai.assignAll(snapshot.docs.map((doc) => PegawaiSimpleModel.fromFirestore(doc)).toList());
  }

  void _gabungkanDanFilterData(Set<String> daftarPengujiAktif) {
    pengujiStatus.clear();
    kandidatPenguji.clear();
    final List<PegawaiSimpleModel> tempKandidat = [];

    for (var pegawai in _allPegawai) {
      final bool isActiveAsPenguji = daftarPengujiAktif.contains(pegawai.uid);

      // Logika untuk menentukan siapa yang muncul di list:
      // - Tampilkan jika ia adalah seorang pengampu.
      // - ATAU, tampilkan jika ia sebelumnya adalah penguji (meskipun perannya sudah berubah),
      //   agar kita bisa menonaktifkannya.
      final dataPegawai = configC.infoUser; // Mengambil data pegawai dari ConfigController
      final role = dataPegawai['role'] as String? ?? '';
      final tugas = List<String>.from(dataPegawai['tugas'] ?? []);

      if (role == 'Pengampu' || tugas.contains('Pengampu') || isActiveAsPenguji) {
        tempKandidat.add(pegawai);
        pengujiStatus[pegawai.uid] = isActiveAsPenguji;
      }
    }
    
    // Urutkan daftar kandidat
    tempKandidat.sort((a, b) => a.displayName.compareTo(b.displayName));
    kandidatPenguji.assignAll(tempKandidat);
  }

  // Future<void> _fetchAllPengampuCandidates() async {
  //   final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
  //   final List<PegawaiSimpleModel> eligible = [];
  //   for (var doc in snapshot.docs) {
  //     final data = doc.data();
  //     final role = data['role'] as String? ?? '';
  //     final tugas = List<String>.from(data['tugas'] ?? []);
  //     if (role == 'Pengampu' || tugas.contains('Pengampu')) {
  //       eligible.add(PegawaiSimpleModel.fromFirestore(doc));
  //     }
  //   }
  //   eligible.sort((a, b) => a.nama.compareTo(b.nama));
  //   _allPengampu.assignAll(eligible);
  // }

  // void _gabungkanData(Set<String> daftarPengujiAktif) {
  //   pengujiStatus.clear();
  //   for (var pengampu in _allPengampu) {
  //     pengujiStatus[pengampu.uid] = daftarPengujiAktif.contains(pengampu.uid);
  //   }
  // }

  void togglePenguji(String uid, bool isSelected) {
    pengujiStatus[uid] = isSelected;
  }

  Future<void> simpanPerubahan() async {
    isSaving.value = true;
    try {
      final Map<String, dynamic> dataToSave = {};
      
      // Iterasi melalui SEMUA kandidat yang ditampilkan di layar
      for (var kandidat in kandidatPenguji) {
        // Jika statusnya true, tambahkan ke map untuk disimpan
        if (pengujiStatus[kandidat.uid] == true) {
          dataToSave[kandidat.uid] = kandidat.displayName;
        }
      }
  
      // --- [PERBAIKAN KUNCI] Gunakan 'update' bukan 'set(merge:true)' ---
      // 'update' akan menimpa field 'daftarPenguji' secara keseluruhan
      // dengan map yang baru, secara efektif menghapus data yang tidak relevan.
      await _configDocRef.update({
        'daftarPenguji': dataToSave,
      });
  
      Get.back();
      Get.snackbar("Berhasil", "Daftar penguji munaqosyah telah diperbarui.");
  
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }

  List<PegawaiSimpleModel> get allPengampu => kandidatPenguji;
}