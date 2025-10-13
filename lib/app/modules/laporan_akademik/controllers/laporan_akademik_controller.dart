// lib/app/modules/laporan_akademik/controllers/laporan_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/nilai_harian_model.dart'; // Impor model nilai harian
import '../../../models/siswa_laporan_model.dart';


class LaporanAkademikController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController;

  final isLoading = true.obs;
  final isDetailLoading = false.obs;
  
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> kelasTerpilih = Rxn<Map<String, dynamic>>();
  final RxString infoWaliKelas = "".obs;
  final RxList<SiswaLaporanModel> siswaDiKelas = <SiswaLaporanModel>[].obs;
  late final Map<String, int> _bobotNilai;

  // [STATE BARU UNTUK PILAR 3]
  final Rxn<SiswaLaporanModel> siswaTerpilihDetail = Rxn<SiswaLaporanModel>();
  final RxList<Map<String, dynamic>> detailNilaiSiswa = <Map<String, dynamic>>[].obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchBobotNilai();
    await _fetchDaftarKelas();
    isLoading.value = false;
  }
  
  Future<void> _fetchBobotNilai() async {
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('pengaturan').doc('bobot_nilai');
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        _bobotNilai = {
          'tugasHarian': data['bobotTugasHarian'] ?? 20,
          'ulanganHarian': data['bobotUlanganHarian'] ?? 20,
          'nilaiTambahan': data['bobotNilaiTambahan'] ?? 20,
          'pts': data['bobotPts'] ?? 20,
          'pas': data['bobotPas'] ?? 20,
        };
      } else {
        _bobotNilai = {'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20, 'pts': 20, 'pas': 20};
      }
    } catch (e) {
      print("### Peringatan: Gagal fetch bobot nilai. Menggunakan nilai default. Error: $e");
      _bobotNilai = {'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20, 'pts': 20, 'pas': 20};
    }
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif)
      .collection('kelastahunajaran').orderBy('namaKelas').get();
    daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> onKelasChanged(Map<String, dynamic> kelas) async {
    if (kelasTerpilih.value?['id'] == kelas['id']) return;
    
    kelasTerpilih.value = kelas;
    isDetailLoading.value = true;
    infoWaliKelas.value = kelas['namaWaliKelas'] ?? 'Belum diatur';
    
    // Reset detail view saat ganti kelas
    siswaTerpilihDetail.value = null;
    detailNilaiSiswa.clear();
    tabController.animateTo(0);

    await _fetchLaporanDetailKelas(kelas['id']);

    isDetailLoading.value = false;
  }
  
  Future<void> _fetchLaporanDetailKelas(String idKelas) async {
    try {
      final semester = configC.semesterAktif.value;

      final siswaSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa')
          .get();

      if (siswaSnapshot.docs.isEmpty) {
        siswaDiKelas.clear(); return;
      }

      final Map<String, SiswaLaporanModel> siswaMap = {
        for (var doc in siswaSnapshot.docs)
          doc.id: SiswaLaporanModel(
            uid: doc.id,
            nama: doc.data()['namaLengkap'] ?? 'Tanpa Nama',
            nisn: doc.data()['nisn'] ?? '-',
          )
      };

      final allMapelSnapshot = await _firestore
          .collectionGroup('matapelajaran')
          .where('kelasId', isEqualTo: idKelas)
          .where('semester', isEqualTo: int.parse(semester))
          .get();

      final allNilaiHarianSnapshot = await _firestore
          .collectionGroup('nilai_harian')
          .where('kelasId', isEqualTo: idKelas)
          .where('semester', isEqualTo: int.parse(semester))
          .get();

      final Map<String, List<Map<String, dynamic>>> mapelPerSiswa = {};
      for (var doc in allMapelSnapshot.docs) {
        final uidSiswa = doc.reference.parent.parent!.parent!.id;
        if (!mapelPerSiswa.containsKey(uidSiswa)) mapelPerSiswa[uidSiswa] = [];
        mapelPerSiswa[uidSiswa]!.add(doc.data());
      }

      final Map<String, List<NilaiHarianModel>> nilaiHarianPerSiswa = {};
      for (var doc in allNilaiHarianSnapshot.docs) {
        final uidSiswa = doc.reference.parent.parent!.parent!.parent!.parent!.id;
        if (!nilaiHarianPerSiswa.containsKey(uidSiswa)) nilaiHarianPerSiswa[uidSiswa] = [];
        nilaiHarianPerSiswa[uidSiswa]!.add(NilaiHarianModel.fromFirestore(doc));
      }

      siswaMap.forEach((uid, siswa) {
        final daftarMapelSiswa = mapelPerSiswa[uid] ?? [];
        if (daftarMapelSiswa.isNotEmpty) {
          double totalNilaiRapor = 0;
          for (var mapelData in daftarMapelSiswa) {
            final idMapel = mapelData['idMapel'];
            final nilaiHarianMapelIni = (nilaiHarianPerSiswa[uid] ?? [])
                .where((n) => n.idMapel == idMapel).toList();
            totalNilaiRapor += _calculateNilaiAkhir(mapelData, nilaiHarianMapelIni);
          }
          siswa.nilaiAkhirRapor = totalNilaiRapor / daftarMapelSiswa.length;
        }
      });

      final tempList = siswaMap.values.toList();
      tempList.sort((a, b) => b.nilaiAkhirRapor.compareTo(a.nilaiAkhirRapor));
      siswaDiKelas.value = tempList;

    } catch (e) {
      print("### FATAL ERROR fetchLaporanDetailKelas: $e");
      Get.snackbar("Error Kritis", "Gagal memuat detail laporan kelas: $e");
    }
  }

  double _calculateNilaiAkhir(Map<String, dynamic> mapelData, List<NilaiHarianModel> nilaiHarian) {
    double avgTugasHarian = _calculateAverage(nilaiHarian, "Harian/PR");
    double avgUlanganHarian = _calculateAverage(nilaiHarian, 'Ulangan Harian');
    double avgNilaiTambahan = _calculateAverage(nilaiHarian, 'Nilai Tambahan'); // Diperlakukan sebagai rata-rata
    int pts = (mapelData['nilai_pts'] as num?)?.toInt() ?? 0;
    int pas = (mapelData['nilai_pas'] as num?)?.toInt() ?? 0;

    int bobotTugas = _bobotNilai['tugasHarian'] ?? 0;
    int bobotUlangan = _bobotNilai['ulanganHarian'] ?? 0;
    int bobotTambahan = _bobotNilai['nilaiTambahan'] ?? 0;
    int bobotPTS = _bobotNilai['pts'] ?? 0;
    int bobotPAS = _bobotNilai['pas'] ?? 0;

    int totalBobot = bobotTugas + bobotUlangan + bobotTambahan + bobotPTS + bobotPAS;
    if (totalBobot == 0) return 0.0;

    double finalScore = 
        ((avgTugasHarian * bobotTugas) +
        (avgUlanganHarian * bobotUlangan) +
        (avgNilaiTambahan * bobotTambahan) + // Nilai tambahan sekarang bagian dari rata-rata berbobot
        (pts * bobotPTS) +
        (pas * bobotPAS)) / totalBobot; 

    return finalScore.clamp(0.0, 100.0);
  }

  double _calculateAverage(List<NilaiHarianModel> listNilai, String kategori) {
    var filteredList = listNilai.where((n) {
      if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
      return n.kategori == kategori;
    }).toList();
    if (filteredList.isEmpty) return 0.0;
    return filteredList.fold<double>(0.0, (sum, item) => sum + item.nilai) / filteredList.length;
  }
  
  double _calculateSum(List<NilaiHarianModel> listNilai, String kategori) {
    var filteredList = listNilai.where((n) => n.kategori == kategori).toList();
    if (filteredList.isEmpty) return 0.0;
    return filteredList.fold<double>(0.0, (sum, item) => sum + item.nilai);
  }

  // [FUNGSI BARU UNTUK PILAR 3]
  Future<void> onSiswaTapped(SiswaLaporanModel siswa) async {
    siswaTerpilihDetail.value = siswa;
    tabController.animateTo(1); // Pindah ke tab Detail Siswa
    
    // Ambil rincian nilai siswa yang di-tap
    await _fetchDetailNilaiSiswa(siswa.uid);
  }

  // [FUNGSI BARU UNTUK PILAR 3]
  Future<void> _fetchDetailNilaiSiswa(String uidSiswa) async {
    try {
      final semester = configC.semesterAktif.value;
      final idKelas = kelasTerpilih.value!['id'];

      final mapelSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa').doc(uidSiswa)
          .collection('semester').doc(semester)
          .collection('matapelajaran')
          .get();
      
      final rekapNilai = mapelSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'mapel': data['namaMapel'] ?? doc.id,
          'nilai_akhir': (data['nilai_akhir'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      rekapNilai.sort((a, b) => (b['nilai_akhir'] as double).compareTo(a['nilai_akhir'] as double));
      detailNilaiSiswa.assignAll(rekapNilai);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat detail nilai untuk siswa ini: $e");
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}

// // lib/app/modules/laporan_akademik/controllers/laporan_akademik_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../controllers/config_controller.dart';
// import '../../../models/nilai_harian_model.dart'; // Impor model nilai harian
// import '../../../models/siswa_laporan_model.dart';

// class LaporanAkademikController extends GetxController with GetTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   late TabController tabController;

//   final isLoading = true.obs;
//   final isDetailLoading = false.obs;
  
//   final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
//   final Rxn<Map<String, dynamic>> kelasTerpilih = Rxn<Map<String, dynamic>>();
//   final RxString infoWaliKelas = "".obs;
//   final RxList<SiswaLaporanModel> siswaDiKelas = <SiswaLaporanModel>[].obs;
//   late final Map<String, int> _bobotNilai;

//   String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 2, vsync: this);
//     _initializeData();
//   }

//   Future<void> _initializeData() async {
//     isLoading.value = true;
//     await _fetchBobotNilai();
//     await _fetchDaftarKelas();
//     isLoading.value = false;
//   }
  
//   Future<void> _fetchBobotNilai() async {
//     final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaranAktif)
//         .collection('pengaturan').doc('bobot_nilai');
//     try {
//       final doc = await docRef.get();
//       if (doc.exists) {
//         final data = doc.data()!;
//         _bobotNilai = {
//           'tugasHarian': data['bobotTugasHarian'] ?? 20,
//           'ulanganHarian': data['bobotUlanganHarian'] ?? 20,
//           'nilaiTambahan': data['bobotNilaiTambahan'] ?? 20,
//           'pts': data['bobotPts'] ?? 20,
//           'pas': data['bobotPas'] ?? 20,
//         };
//       } else {
//         _bobotNilai = {'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20, 'pts': 20, 'pas': 20};
//       }
//     } catch (e) {
//       print("### Peringatan: Gagal fetch bobot nilai. Menggunakan nilai default. Error: $e");
//       _bobotNilai = {'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20, 'pts': 20, 'pas': 20};
//     }
//   }

//   Future<void> _fetchDaftarKelas() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//       .collection('tahunajaran').doc(tahunAjaranAktif)
//       .collection('kelastahunajaran').orderBy('namaKelas').get();
//     daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
//   }

//   Future<void> onKelasChanged(Map<String, dynamic> kelas) async {
//     if (kelasTerpilih.value?['id'] == kelas['id']) return;
    
//     kelasTerpilih.value = kelas;
//     isDetailLoading.value = true;
//     infoWaliKelas.value = kelas['namaWaliKelas'] ?? 'Belum diatur';
    
//     await _fetchLaporanDetailKelas(kelas['id']);

//     isDetailLoading.value = false;
//   }
  
//   // [PEROMBAKAN FINAL DENGAN LOGIKA SUPERIOR]
//   Future<void> _fetchLaporanDetailKelas(String idKelas) async {
//     try {
//       final semester = configC.semesterAktif.value;
      
//       // Query langsung ke subkoleksi `daftarsiswa`
//       final siswaSnapshot = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaranAktif)
//           .collection('kelastahunajaran').doc(idKelas)
//           .collection('daftarsiswa')
//           .get();
  
//       if (siswaSnapshot.docs.isEmpty) {
//         siswaDiKelas.clear();
//         return;
//       }
      
//       final Map<String, SiswaLaporanModel> siswaMap = {
//         for (var doc in siswaSnapshot.docs)
//           doc.id: SiswaLaporanModel(
//             uid: doc.id,
//             nama: doc.data()['namaLengkap'] ?? 'Tanpa Nama',
//             nisn: doc.data()['nisn'] ?? '-',
//           )
//       };

//       // 1. Ambil semua nilai utama (PTS, PAS) dalam 1 query
//       final allMapelSnapshot = await _firestore
//           .collectionGroup('matapelajaran')
//           .where('kelasId', isEqualTo: idKelas)
//           .where('semester', isEqualTo: int.parse(semester))
//           .get();

//       // 2. Ambil semua nilai harian dalam 1 query
//       final allNilaiHarianSnapshot = await _firestore
//           .collectionGroup('nilai_harian')
//           .where('kelasId', isEqualTo: idKelas) // Kita perlu menambahkan 'kelasId' saat menyimpan nilai
//           .where('semester', isEqualTo: int.parse(semester)) // Begitu juga 'semester'
//           .get();

//       // 3. Olah dan kelompokkan semua data di klien (super cepat)
//       final Map<String, List<Map<String, dynamic>>> mapelPerSiswa = {};
//       for (var doc in allMapelSnapshot.docs) {
//         final uidSiswa = doc.reference.parent.parent!.parent!.id;
//         if (!mapelPerSiswa.containsKey(uidSiswa)) mapelPerSiswa[uidSiswa] = [];
//         mapelPerSiswa[uidSiswa]!.add(doc.data());
//       }

//       final Map<String, List<NilaiHarianModel>> nilaiHarianPerSiswa = {};
//       for (var doc in allNilaiHarianSnapshot.docs) {
//         final uidSiswa = doc.reference.parent.parent!.parent!.parent!.parent!.id;
//         if (!nilaiHarianPerSiswa.containsKey(uidSiswa)) nilaiHarianPerSiswa[uidSiswa] = [];
//         nilaiHarianPerSiswa[uidSiswa]!.add(NilaiHarianModel.fromFirestore(doc));
//       }

//       // 4. Hitung nilai rapor untuk setiap siswa
//       siswaMap.forEach((uid, siswa) {
//         final daftarMapelSiswa = mapelPerSiswa[uid] ?? [];
//         if (daftarMapelSiswa.isNotEmpty) {
//           double totalNilaiRapor = 0;
//           for (var mapelData in daftarMapelSiswa) {
//             final idMapel = mapelData['idMapel'];
//             final nilaiHarianMapelIni = (nilaiHarianPerSiswa[uid] ?? [])
//                 .where((n) => n.idMapel == idMapel).toList(); // Asumsi ada idMapel di NilaiHarianModel
//             totalNilaiRapor += _calculateNilaiAkhir(mapelData, nilaiHarianMapelIni);
//           }
//           siswa.nilaiAkhirRapor = totalNilaiRapor / daftarMapelSiswa.length;
//         }
//       });
      
//       final tempList = siswaMap.values.toList();
//       tempList.sort((a, b) => b.nilaiAkhirRapor.compareTo(a.nilaiAkhirRapor));
//       siswaDiKelas.value = tempList;

//     } catch (e) {
//       print("### FATAL ERROR fetchLaporanDetailKelas: $e");
//       Get.snackbar("Error Kritis", "Gagal memuat detail laporan kelas: $e");
//     }
//   }

//   double _calculateNilaiAkhir(Map<String, dynamic> mapelData, List<NilaiHarianModel> nilaiHarian) {
//     double avgTugasHarian = _calculateAverage(nilaiHarian, "Harian/PR");
//     double avgUlanganHarian = _calculateAverage(nilaiHarian, 'Ulangan Harian');
//     double totalNilaiTambahan = _calculateSum(nilaiHarian, 'Nilai Tambahan');
//     int pts = (mapelData['nilai_pts'] as num?)?.toInt() ?? 0;
//     int pas = (mapelData['nilai_pas'] as num?)?.toInt() ?? 0;

//     int bobotTugas = _bobotNilai['tugasHarian'] ?? 0;
//     int bobotUlangan = _bobotNilai['ulanganHarian'] ?? 0;
//     int bobotPTS = _bobotNilai['pts'] ?? 0;
//     int bobotPAS = _bobotNilai['pas'] ?? 0;
    
//     int totalBobot = bobotTugas + bobotUlangan + bobotPTS + bobotPAS;
//     if (totalBobot == 0) return 0.0;
    
//     double finalScore = 
//         ((avgTugasHarian * bobotTugas) +
//         (avgUlanganHarian * bobotUlangan) +
//         (pts * bobotPTS) +
//         (pas * bobotPAS)) / totalBobot; 
    
//     finalScore += totalNilaiTambahan; // Nilai tambahan adalah bonus di atas 100

//     return finalScore.clamp(0.0, 100.0);
//   }

//   double _calculateAverage(List<NilaiHarianModel> listNilai, String kategori) {
//     var filteredList = listNilai.where((n) {
//       if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
//       return n.kategori == kategori;
//     }).toList();
//     if (filteredList.isEmpty) return 0;
//     return filteredList.fold(0, (sum, item) => sum + item.nilai) / filteredList.length;
//   }
  
//   double _calculateSum(List<NilaiHarianModel> listNilai, String kategori) {
//     var filteredList = listNilai.where((n) => n.kategori == kategori).toList();
//     if (filteredList.isEmpty) return 0;
//     return filteredList.fold(0, (sum, item) => sum + item.nilai).toDouble();
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }
// }