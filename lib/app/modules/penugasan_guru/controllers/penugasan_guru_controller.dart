// lib/app/modules/penugasan_guru/controllers/penugasan_guru_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

class PenugasanGuruController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  
  final isLoading = true.obs;
  final isLoadingMapel = false.obs;
  
  final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
  final RxList<Map<String, dynamic>> daftarGuru = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> guruTerpilihSementara = Rxn<Map<String, dynamic>>();
  
  final Rxn<DocumentSnapshot> kelasTerpilih = Rxn<DocumentSnapshot>();
  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await Future.wait([_fetchDaftarKelas(), _fetchDaftarGuru()]);
    isLoading.value = false;
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).get();
    daftarKelas.assignAll(snapshot.docs);
  }

  Future<void> _fetchDaftarGuru() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('pegawai')
        .where('role', whereIn: ['Guru Kelas', 'Guru Mapel'])
        .get();
        
    daftarGuru.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      final nama = data['nama'] as String? ?? '?';
      final alias = data['alias'] as String?;

      return {
        'uid': doc.id,
        'nama': nama,
        'alias': (alias == null || alias.isEmpty) ? nama : alias,
      };
    }).toList());
  }

  Future<void> gantiKelasTerpilih(DocumentSnapshot kelasDoc) async {
    if (kelasTerpilih.value?.id == kelasDoc.id) return;
    kelasTerpilih.value = kelasDoc;
    isLoadingMapel.value = true;
    try {
      final fase = (kelasDoc.data() as Map<String, dynamic>)['fase'];
      final faseId = "fase_${fase.split(' ').last.toLowerCase()}";
      final kurikulumDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(faseId).get();
      if (kurikulumDoc.exists && kurikulumDoc.data()?['matapelajaran'] != null) {
        daftarMapel.assignAll(List<Map<String, dynamic>>.from(kurikulumDoc.data()!['matapelajaran']));
      } else {
        daftarMapel.clear();
      }
    } catch (e) { Get.snackbar("Gagal Memuat Kurikulum", e.toString()); } 
    finally { isLoadingMapel.value = false; }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedMapelStream() {
    if (kelasTerpilih.value == null) return const Stream.empty();
    return _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('penugasan').doc(kelasTerpilih.value!.id).collection('matapelajaran').snapshots();
  }


  Future<void> assignGuruToMapel(Map<String, dynamic> guru, Map<String, dynamic> mapel) async {
    if (kelasTerpilih.value == null) return;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final kelasId = kelasTerpilih.value!.id;
      final guruId = guru['uid'];
      final mapelId = mapel['idMapel'];
      
      final String docIdMapelDiampu = '$mapelId-$kelasId';

      final dataToSave = {
        'idGuru': guruId, 
        'namaGuru': guru['nama'], 
        'aliasGuru': guru['alias'],
        'idMapel': mapelId, 
        'namaMapel': mapel['nama'], // [PERBAIKAN]: Ganti 'namamatapelajaran' menjadi 'namaMapel'
        'idKelas': kelasId, 
        'idTahunAjaran': tahunAjaranAktif,
      };

      final penugasanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                        .collection('tahunajaran').doc(tahunAjaranAktif).collection('penugasan')
                        .doc(kelasId).collection('matapelajaran').doc(mapelId);
      final pegawaiJadwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                        .collection('pegawai').doc(guruId).collection('jadwal_mengajar').doc(tahunAjaranAktif);

      WriteBatch batch = _firestore.batch();
      batch.set(penugasanRef, dataToSave);
      batch.set(pegawaiJadwalRef.collection('mapel_diampu').doc(docIdMapelDiampu), dataToSave);
      batch.set(pegawaiJadwalRef, {'tahunAjaran': tahunAjaranAktif}, SetOptions(merge: true));
      await batch.commit();
      
      Get.back();
    } catch (e) { Get.back(); Get.snackbar('Gagal', e.toString()); }
  }

  Future<void> removeGuruFromMapel(String mapelId) async {
     if (kelasTerpilih.value == null) return;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final kelasId = kelasTerpilih.value!.id;
      final penugasanRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran')
                          .doc(tahunAjaranAktif).collection('penugasan').doc(kelasId).collection('matapelajaran').doc(mapelId);
      final doc = await penugasanRef.get();
      if (!doc.exists) throw Exception('Data penugasan tidak ditemukan.');
      
      final guruId = doc.data()!['idGuru'];
      final String docIdMapelDiampu = '$mapelId-$kelasId';
      final pegawaiJadwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai')
                              .doc(guruId).collection('jadwal_mengajar').doc(tahunAjaranAktif)
                              .collection('mapel_diampu').doc(docIdMapelDiampu);

      WriteBatch batch = _firestore.batch();
      batch.delete(penugasanRef);
      batch.delete(pegawaiJadwalRef);
      await batch.commit();
      
      Get.back();
    } catch (e) { Get.back(); Get.snackbar('Gagal', e.toString()); }
  }
}

// // lib/app/modules/penugasan_guru/controllers/penugasan_guru_controller.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

// class PenugasanGuruController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
  
//   final isLoading = true.obs;
//   final isLoadingMapel = false.obs;
  
//   final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
//   final RxList<Map<String, dynamic>> daftarGuru = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;
//   final Rxn<Map<String, dynamic>> guruTerpilihSementara = Rxn<Map<String, dynamic>>();
  
//   final Rxn<DocumentSnapshot> kelasTerpilih = Rxn<DocumentSnapshot>();
//   String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeData();
//   }

//   Future<void> _initializeData() async {
//     isLoading.value = true;
//     await Future.wait([_fetchDaftarKelas(), _fetchDaftarGuru()]);
//     isLoading.value = false;
//   }

//   Future<void> _fetchDaftarKelas() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).get();
//     daftarKelas.assignAll(snapshot.docs);
//   }

//   Future<void> _fetchDaftarGuru() async {
//     final snapshot = await _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('pegawai')
//         .where('role', whereIn: ['Guru Kelas', 'Guru Mapel'])
//         .get();
        
//     daftarGuru.assignAll(snapshot.docs.map((doc) {
//       final data = doc.data();
//       final nama = data['nama'] as String? ?? '?';
//       final alias = data['alias'] as String?;

//       return {
//         'uid': doc.id,
//         'nama': nama,
//         // --- [IMPLEMENTASI LOGIKA FALLBACK] ---
//         'alias': (alias == null || alias.isEmpty) ? nama : alias,
//       };
//     }).toList());
//   }

//   Future<void> gantiKelasTerpilih(DocumentSnapshot kelasDoc) async {
//     if (kelasTerpilih.value?.id == kelasDoc.id) return;
//     kelasTerpilih.value = kelasDoc;
//     isLoadingMapel.value = true;
//     try {
//       final fase = (kelasDoc.data() as Map<String, dynamic>)['fase'];
//       final faseId = "fase_${fase.split(' ').last.toLowerCase()}";
//       final kurikulumDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(faseId).get();
//       if (kurikulumDoc.exists && kurikulumDoc.data()?['matapelajaran'] != null) {
//         daftarMapel.assignAll(List<Map<String, dynamic>>.from(kurikulumDoc.data()!['matapelajaran']));
//       } else {
//         daftarMapel.clear();
//       }
//     } catch (e) { Get.snackbar("Gagal Memuat Kurikulum", e.toString()); } 
//     finally { isLoadingMapel.value = false; }
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedMapelStream() {
//     if (kelasTerpilih.value == null) return const Stream.empty();
//     return _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('penugasan').doc(kelasTerpilih.value!.id).collection('matapelajaran').snapshots();
//   }


//   Future<void> assignGuruToMapel(Map<String, dynamic> guru, Map<String, dynamic> mapel) async {
//     if (kelasTerpilih.value == null) return;
//     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
//     try {
//       final kelasId = kelasTerpilih.value!.id;
//       final guruId = guru['uid'];
//       final mapelId = mapel['idMapel'];
      
//       // --- [PERBAIKAN ARSITEKTUR] ID Dokumen baru yang unik ---
//       final String docIdMapelDiampu = '$mapelId-$kelasId';
//       // --------------------------------------------------------

//       final dataToSave = {
//         'idGuru': guruId, 'namaGuru': guru['nama'], 'aliasGuru': guru['alias'],
//         'idMapel': mapelId, 'namamatapelajaran': mapel['nama'],
//         'idKelas': kelasId, 'idTahunAjaran': tahunAjaranAktif,
//       };

//       final penugasanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//                         .collection('tahunajaran').doc(tahunAjaranAktif).collection('penugasan')
//                         .doc(kelasId).collection('matapelajaran').doc(mapelId);
//       final pegawaiJadwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//                         .collection('pegawai').doc(guruId).collection('jadwal_mengajar').doc(tahunAjaranAktif);

//       WriteBatch batch = _firestore.batch();
//       batch.set(penugasanRef, dataToSave);
//       // Gunakan ID dokumen baru
//       batch.set(pegawaiJadwalRef.collection('mapel_diampu').doc(docIdMapelDiampu), dataToSave);
//       batch.set(pegawaiJadwalRef, {'tahunAjaran': tahunAjaranAktif}, SetOptions(merge: true));
//       await batch.commit();
      
//       Get.back();
//     } catch (e) { Get.back(); Get.snackbar('Gagal', e.toString()); }
//   }

//   Future<void> removeGuruFromMapel(String mapelId) async {
//      if (kelasTerpilih.value == null) return;
//     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
//     try {
//       final kelasId = kelasTerpilih.value!.id;
//       final penugasanRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran')
//                           .doc(tahunAjaranAktif).collection('penugasan').doc(kelasId).collection('matapelajaran').doc(mapelId);
//       final doc = await penugasanRef.get();
//       if (!doc.exists) throw Exception('Data penugasan tidak ditemukan.');
      
//       final guruId = doc.data()!['idGuru'];
//       // --- [PERBAIKAN ARSITEKTUR] Hapus dokumen dengan ID yang benar ---
//       final String docIdMapelDiampu = '$mapelId-$kelasId';
//       final pegawaiJadwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai')
//                               .doc(guruId).collection('jadwal_mengajar').doc(tahunAjaranAktif)
//                               .collection('mapel_diampu').doc(docIdMapelDiampu);
//       // -----------------------------------------------------------

//       WriteBatch batch = _firestore.batch();
//       batch.delete(penugasanRef);
//       batch.delete(pegawaiJadwalRef);
//       await batch.commit();
      
//       Get.back();
//     } catch (e) { Get.back(); Get.snackbar('Gagal', e.toString()); }
//   }
// }