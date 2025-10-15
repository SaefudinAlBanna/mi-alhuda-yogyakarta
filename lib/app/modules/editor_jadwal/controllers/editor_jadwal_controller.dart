// lib/app/modules/editor_jadwal/controllers/editor_jadwal_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';

class EditorJadwalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  late Worker _statusWorker;

  final isLoading = true.obs;
  final isLoadingJadwal = false.obs;
  final isSaving = false.obs;

  // --- State Utama ---
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();
  final RxString selectedHari = 'Senin'.obs;
  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaran = <String, RxList<Map<String, dynamic>>>{}.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  // --- [PEROMBAKAN] State untuk data sumber ---
  final RxList<Map<String, dynamic>> daftarJamMaster = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarMapelTersedia = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _guruTugasTersedia = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _semuaGuruTersedia = <Map<String, dynamic>>[].obs;
  
  // --- [BARU] State untuk kontrol UI ---
  final RxBool tampilkanSemuaGuru = false.obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    for (var hari in daftarHari) { jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs; }
    _statusWorker = ever(configC.status, (appStatus) {
      if (appStatus == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (configC.status.value == AppStatus.authenticated && isLoading.value) {
      _initializeData();
    }
  }

  @override
  void onClose() {
    _statusWorker.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchDaftarKelas();
    isLoading.value = false;
  }

  Future<void> _fetchDaftarKelas() async {
    if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK DITEMUKAN")) {
      Get.snackbar("Kesalahan Konfigurasi", "Tahun ajaran aktif tidak ditemukan.");
      daftarKelas.clear();
      return;
    }
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).orderBy('namaKelas').get();
    daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namaKelas'] ?? doc.id}).toList();
  }

  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null) return;
    selectedKelasId.value = kelasId;
    _clearJadwal();
    isLoadingJadwal.value = true;
    // [PEROMBAKAN] _fetchDaftarJam sekarang menjadi _fetchMasterJam
    await Future.wait([ _fetchJadwal(), _fetchMasterJam(), _fetchGuruDanMapel() ]);
    isLoadingJadwal.value = false;
  }
  
  Future<void> _fetchJadwal() async {
    if (selectedKelasId.value == null) return;
    try {
      final docSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).get();
      _clearJadwal();
      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data() as Map<String, dynamic>;
        dataJadwal.forEach((hari, listData) {
          if (jadwalPelajaran.containsKey(hari) && listData is List) {
            jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(listData);
          }
        });
      }
    } catch (e) { Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}'); }
  }

  // [NAMA BARU & PERAN BARU] Mengambil data master jam untuk template
  Future<void> _fetchMasterJam() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').orderBy('urutan').get();
    daftarJamMaster.value = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'namaKegiatan': data['namaKegiatan'] as String? ?? '',
        'jamMulai': data['jamMulai'] as String? ?? '',
        'jamSelesai': data['jamSelesai'] as String? ?? '',
      };
    }).toList();
  }

  // [PEROMBAKAN] Mengambil dua set data guru: yang ditugaskan dan semua guru
  Future<void> _fetchGuruDanMapel() async {
    if (selectedKelasId.value == null) return;
    try {
      final penugasanSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran')
          .doc(tahunAjaranAktif).collection('penugasan').doc(selectedKelasId.value!)
          .collection('matapelajaran').get();
      
      final semuaGuruSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();

      daftarMapelTersedia.clear();
      _guruTugasTersedia.clear();
      _semuaGuruTersedia.clear();
      final Set<String> uniqueMapelIds = {};

      for(var doc in penugasanSnap.docs) {
        final data = doc.data();
        final namaGuru = data['namaGuru'] as String? ?? 'Tanpa Nama';
        final aliasGuru = data['aliasGuru'] as String?;
        final namaMapel = data['namaMapel'] as String? ?? 'Tanpa Nama Mapel';

        _guruTugasTersedia.add({
          'uid': data['idGuru'], 'nama': namaGuru, 
          'alias': (aliasGuru == null || aliasGuru.isEmpty) ? namaGuru : aliasGuru,
          'idMapel': data['idMapel']
        });

        if (uniqueMapelIds.add(data['idMapel'])) {
          daftarMapelTersedia.add({'idMapel': data['idMapel'], 'nama': namaMapel});
        }
      }

      for (var doc in semuaGuruSnap.docs) {
          final data = doc.data();
          final namaGuru = data['nama'] as String? ?? 'Tanpa Nama';
          final aliasGuru = data['alias'] as String?;
           _semuaGuruTersedia.add({
             'uid': doc.id, 'nama': namaGuru,
             'alias': (aliasGuru == null || aliasGuru.isEmpty || aliasGuru == 'N/A') ? namaGuru : aliasGuru,
           });
      }
      // [BARU] Tambahkan mapel Halaqah secara manual jika belum ada
      if (!uniqueMapelIds.contains('halaqah')) {
          daftarMapelTersedia.add({'idMapel': 'halaqah', 'nama': 'Tahsin/Tahfidz'});
      }

    } catch(e) { Get.snackbar("Error", "Gagal memuat data guru & mapel: $e"); } 
  }

  // [BARU] Getter dinamis yang mengembalikan daftar guru berdasarkan toggle
  RxList<Map<String, dynamic>> get guruDropdownList {
    if(tampilkanSemuaGuru.value) {
      return _semuaGuruTersedia; // <-- Hapus .obs
    }
    return _guruTugasTersedia; // <-- Hapus .obs
  }
  
  // [BARU] Fungsi untuk mengubah state filter guru
  void toggleTampilkanSemuaGuru(bool value) {
      tampilkanSemuaGuru.value = value;
      // Refresh semua jadwal agar dropdown guru di-update
      jadwalPelajaran.refresh();
  }
  
  // [PEROMBAKAN TOTAL] Fungsi untuk memperbarui slot pelajaran
  void updatePelajaran(int index, String key, dynamic value) {
    final pelajaran = jadwalPelajaran[selectedHari.value]![index];

    if (key == 'jamMulai' || key == 'jamSelesai') {
        pelajaran[key] = value;
        // Selalu update field 'jam' agar tetap kompatibel
        final mulai = pelajaran['jamMulai'] ?? '--:--';
        final selesai = pelajaran['jamSelesai'] ?? '--:--';
        pelajaran['jam'] = '$mulai - $selesai';
    } else if (key == 'idMapel') {
        final mapel = daftarMapelTersedia.firstWhere((m) => m['idMapel'] == value, orElse: () => {});
        pelajaran['idMapel'] = value;
        pelajaran['namaMapel'] = mapel['nama'];
        
        // [LOGIKA BARU] Jika mapel adalah Halaqah, set guru default
        if (value == 'halaqah') {
            pelajaran['idGuru'] = 'tim_tahsin'; // ID khusus
            pelajaran['namaGuru'] = 'Tim Tahsin/Tahfidz';
        } else {
            pelajaran['idGuru'] = null;
            pelajaran['namaGuru'] = null;
        }
    } else if (key == 'idGuru') {
        final listGuru = tampilkanSemuaGuru.value ? _semuaGuruTersedia : _guruTugasTersedia;
        final guru = listGuru.firstWhere((g) => g['uid'] == value, orElse: () => {});
        pelajaran['idGuru'] = value;
        pelajaran['namaGuru'] = guru['alias'];
    } else {
        pelajaran[key] = value; // Untuk kasus lain, seperti nama kegiatan dari template
    }
    jadwalPelajaran[selectedHari.value]!.refresh();
  }

  // [PEROMBAKAN] Fungsi ini sekarang menggunakan struktur data baru
  void tambahPelajaran() {
    jadwalPelajaran[selectedHari.value]?.add({
      'jamMulai': null, 'jamSelesai': null, 'jam': '--:-- - --:--',
      'idMapel': null, 'namaMapel': null, 'idGuru': null, 'namaGuru': null,
    });
  }
  
  // [BARU] Fungsi untuk memilih waktu dengan Time Picker
  Future<void> pilihWaktu(BuildContext context, int index, bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final formatWaktu = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      updatePelajaran(index, isMulai ? 'jamMulai' : 'jamSelesai', formatWaktu);
    }
  }

  // [BARU] Fungsi untuk memilih slot dari template Master Jam
  void pilihDariTemplate(int index) {
      Get.dialog(AlertDialog(
        title: const Text("Pilih dari Template"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: daftarJamMaster.length,
            itemBuilder: (context, i) {
              final jam = daftarJamMaster[i];
              final namaKegiatan = jam['namaKegiatan'] as String;

              return ListTile(
                title: Text(namaKegiatan),
                subtitle: Text("${jam['jamMulai']} - ${jam['jamSelesai']}"),
                onTap: () {
                  final pelajaran = jadwalPelajaran[selectedHari.value]![index];
                  pelajaran['jamMulai'] = jam['jamMulai'];
                  pelajaran['jamSelesai'] = jam['jamSelesai'];
                  pelajaran['jam'] = "${jam['jamMulai']} - ${jam['jamSelesai']}";
                  
                  // [LOGIKA BARU YANG LEBIH CERDAS]
                  // Asumsikan: jika nama kegiatan TIDAK mengandung kata "JP",
                  // maka itu adalah kegiatan umum.
                  if (!namaKegiatan.toUpperCase().contains('JP')) {
                      // Ini adalah kegiatan umum (Istirahat, Upacara, dll.)
                      pelajaran['namaMapel'] = namaKegiatan; 
                      pelajaran['idMapel'] = null;
                      pelajaran['idGuru'] = null;
                      pelajaran['namaGuru'] = null;
                  } else {
                      // Ini adalah slot Jam Pelajaran biasa.
                      // Kosongkan namaMapel agar judul kartu tidak berubah
                      // dan dropdown mapel bisa dipilih oleh pengguna.
                      pelajaran['namaMapel'] = null;
                  }

                  jadwalPelajaran[selectedHari.value]!.refresh();
                  Get.back();
                },
              );
            },
          ),
        ),
      ));
  }

  // void pilihDariTemplate(int index) {
  //     Get.dialog(AlertDialog(
  //       title: const Text("Pilih dari Template"),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: daftarJamMaster.length,
  //           itemBuilder: (context, i) {
  //             final jam = daftarJamMaster[i];
  //             return ListTile(
  //               title: Text(jam['namaKegiatan']),
  //               subtitle: Text("${jam['jamMulai']} - ${jam['jamSelesai']}"),
  //               onTap: () {
  //                 final pelajaran = jadwalPelajaran[selectedHari.value]![index];
  //                 pelajaran['jamMulai'] = jam['jamMulai'];
  //                 pelajaran['jamSelesai'] = jam['jamSelesai'];
  //                 pelajaran['jam'] = "${jam['jamMulai']} - ${jam['jamSelesai']}";
                  
  //                 // Jika ini kegiatan umum, isi nama mapel & hapus guru
  //                 if (['Istirahat', 'Upacara', 'Shalat Dhuha'].contains(jam['namaKegiatan'])) {
  //                     pelajaran['namaMapel'] = jam['namaKegiatan'];
  //                     pelajaran['idMapel'] = null;
  //                     pelajaran['idGuru'] = null;
  //                     pelajaran['namaGuru'] = null;
  //                 }
  //                 jadwalPelajaran[selectedHari.value]!.refresh();
  //                 Get.back();
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     ));
  // }

  // ... (fungsi _clearJadwal, hapusPelajaran, dan simpanJadwal tidak banyak berubah)
  void _clearJadwal() { 
    for (var hari in daftarHari) {
       jadwalPelajaran[hari]?.clear(); 
       } 
  }

  void hapusPelajaran(int index) { 
    jadwalPelajaran[selectedHari.value]?.removeAt(index); 
  }
  
  Future<void> simpanJadwal() async {
    if (selectedKelasId.value == null) return;
    isSaving.value = true;
    
    // [VALIDASI BARU] Cek bentrok internal dulu
    String? internalClash = _validateInternalClash();
    if (internalClash != null) {
      Get.snackbar('Jadwal Bentrok!', internalClash, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
      isSaving.value = false;
      return;
    }

    final String? guruClash = await _validateGuruClash();
    if (guruClash != null) {
      Get.snackbar('Jadwal Bentrok!', guruClash, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
      isSaving.value = false;
      return;
    }

    try {
      Map<String, List<Map<String, dynamic>>> dataToSave = {};
      jadwalPelajaran.forEach((hari, list) { dataToSave[hari] = list.toList(); });
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).set(dataToSave);
      Get.snackbar('Berhasil', 'Jadwal pelajaran berhasil disimpan.');
    } catch (e) { Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}'); } 
    finally { isSaving.value = false; }
  }

  // [FUNGSI VALIDASI BARU] Cek bentrok di dalam jadwal yang sedang diedit
  String? _validateInternalClash() {
      final listPelajaran = jadwalPelajaran[selectedHari.value]!;
      if (listPelajaran.length < 2) return null;

      // Konversi semua slot ke menit untuk perbandingan
      List<Map<String, int>> slotsInMinutes = [];
      for (var p in listPelajaran) {
        final mulaiStr = p['jamMulai'] as String?;
        final selesaiStr = p['jamSelesai'] as String?;
        if (mulaiStr == null || selesaiStr == null) continue; // Lewati slot yang belum lengkap
        
        final mulai = TimeOfDay(hour: int.parse(mulaiStr.split(':')[0]), minute: int.parse(mulaiStr.split(':')[1]));
        final selesai = TimeOfDay(hour: int.parse(selesaiStr.split(':')[0]), minute: int.parse(selesaiStr.split(':')[1]));

        slotsInMinutes.add({
          'mulai': mulai.hour * 60 + mulai.minute,
          'selesai': selesai.hour * 60 + selesai.minute,
        });
      }

      // Bandingkan setiap slot dengan semua slot lainnya
      for (int i = 0; i < slotsInMinutes.length; i++) {
        for (int j = i + 1; j < slotsInMinutes.length; j++) {
            final slotA = slotsInMinutes[i];
            final slotB = slotsInMinutes[j];
            // Formula overlap: (StartA < EndB) and (StartB < EndA)
            if (slotA['mulai']! < slotB['selesai']! && slotB['mulai']! < slotA['selesai']!) {
                return "Terdapat tumpang tindih waktu di jadwal hari ${selectedHari.value}. Periksa kembali slot pelajaran Anda.";
            }
        }
      }
      return null; // Tidak ada bentrok
  }
  
  Future<String?> _validateGuruClash() async {
    final otherSchedulesSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').where(FieldPath.documentId, isNotEqualTo: selectedKelasId.value!).get();
    final Map<String, String> guruBookings = {};

    for (var doc in otherSchedulesSnapshot.docs) {
      final idKelasLain = doc.id;
      doc.data().forEach((hari, listPelajaran) {
        if (listPelajaran is List) {
          for (var pelajaran in listPelajaran) {
            final jam = pelajaran['jam'] as String?;
            final idGuru = pelajaran['idGuru'] as String?;
            if (jam != null && idGuru != null) {
              guruBookings['$idGuru-$hari-$jam'] = daftarKelas.firstWhere((k) => k['id'] == idKelasLain, orElse: () => {'nama': '?'})['nama'];
            }
          }
        }
      });
    }

    for (var hari in jadwalPelajaran.keys) {
      for (var slot in jadwalPelajaran[hari]!) {
        final jam = slot['jam'] as String?;
        final idGuru = slot['idGuru'] as String?;
        if (jam == null || idGuru == null) continue;

        final key = '$idGuru-$hari-$jam';
        if (guruBookings.containsKey(key)) {
          final namaGuru = _guruTugasTersedia.firstWhere((g) => g['uid'] == idGuru, orElse: () => {'nama': '?'})['nama'];
          return "Bentrok: $namaGuru sudah terjadwal di Kelas ${guruBookings[key]} pada hari $hari, jam $jam.";
        }
      }
    }
    return null;
  }
}


// // lib/app/modules/editor_jadwal/controllers/editor_jadwal_controller.dart

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

// class EditorJadwalController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
//   late Worker _statusWorker;

//   late Worker _tahunAjaranWorker;

//   final isLoading = true.obs;
//   final isLoadingJadwal = false.obs;
//   final isSaving = false.obs;

//   final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> daftarJam = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> daftarMapelTersedia = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> daftarGuruTersedia = <Map<String, dynamic>>[].obs;

//   final Rxn<String> selectedKelasId = Rxn<String>();
//   final RxString selectedHari = 'Senin'.obs;
//   final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaran = <String, RxList<Map<String, dynamic>>>{}.obs;
//   final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  
//   String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

//    @override
//   void onInit() {
//     super.onInit();
//     for (var hari in daftarHari) { jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs; }

//     // Worker ini akan "mengawasi" status di ConfigController.
//     _statusWorker = ever(configC.status, (appStatus) {
//       if (appStatus == AppStatus.authenticated && isLoading.value) {
//         _initializeData();
//       }
//     });
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     if (configC.status.value == AppStatus.authenticated && isLoading.value) {
//       _initializeData();
//     }
//   }

//   @override
//   void onClose() {
//     _statusWorker.dispose();
//     super.onClose();
//   }

//   Future<void> _initializeData() async {
//     isLoading.value = true;
//     await _fetchDaftarKelas();
//     isLoading.value = false;
//   }

//   Future<void> _fetchDaftarKelas() async {
//     if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK DITEMUKAN")) {
//       Get.snackbar("Kesalahan Konfigurasi", "Tahun ajaran aktif tidak ditemukan.");
//       daftarKelas.clear();
//       return;
//     }
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).orderBy('namaKelas').get();
//     daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namaKelas'] ?? doc.id}).toList();
//   }

//   // Sisa controller tidak ada perubahan...
//   Future<void> onKelasChanged(String? kelasId) async {
//     if (kelasId == null) return;
//     selectedKelasId.value = kelasId;
//     _clearJadwal();
//     isLoadingJadwal.value = true;
//     await Future.wait([ _fetchJadwal(), _fetchDaftarJam(), _fetchGuruDanMapel() ]);
//     isLoadingJadwal.value = false;
//   }
  
//   Future<void> _fetchJadwal() async {
//     if (selectedKelasId.value == null) return;
//     try {
//       final docSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).get();
//       _clearJadwal();
//       if (docSnap.exists && docSnap.data() != null) {
//         final dataJadwal = docSnap.data() as Map<String, dynamic>;
//         dataJadwal.forEach((hari, listData) {
//           if (jadwalPelajaran.containsKey(hari) && listData is List) {
//             jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(listData);
//           }
//         });
//       }
//     } catch (e) { Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}'); }
//   }

//   Future<void> _fetchDaftarJam() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').orderBy('urutan').get();
    
//     // --- [PERBAIKAN] Tambahkan pengecekan null dengan fallback string kosong ---
//     daftarJam.value = snapshot.docs.map((doc) {
//       final data = doc.data();
//       final nama = data['namaKegiatan'] as String? ?? '';
//       final waktu = data['jampelajaran'] as String? ?? '';
//       return {
//         'id': doc.id, 
//         'label': "$nama ($waktu)", 
//         'waktu': waktu,
//       };
//     }).toList();
//     // -------------------------------------------------------------------------
//   }

//   Future<void> _fetchGuruDanMapel() async {
//     if (selectedKelasId.value == null) return;
//     try {
//       final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran')
//                             .doc(tahunAjaranAktif).collection('penugasan').doc(selectedKelasId.value!)
//                             .collection('matapelajaran').get();

//       daftarMapelTersedia.clear();
//       daftarGuruTersedia.clear();
//       final Set<String> uniqueMapelIds = {};

//       for(var doc in snapshot.docs) {
//         final data = doc.data();
        
//         // --- [PERBAIKAN] Ambil data dengan fallback untuk mencegah null ---
//         final namaGuru = data['namaGuru'] as String? ?? 'Tanpa Nama';
//         final aliasGuru = data['aliasGuru'] as String?;
//         final namaMapel = data['namaMapel'] as String? ?? 'Tanpa Nama Mapel';
//         // -----------------------------------------------------------------

//         daftarGuruTersedia.add({
//           'uid': data['idGuru'],
//           'nama': namaGuru, 
//           'alias': (aliasGuru == null || aliasGuru.isEmpty) ? namaGuru : aliasGuru,
//           'idMapel': data['idMapel']
//         });

//         if (uniqueMapelIds.add(data['idMapel'])) {
//           daftarMapelTersedia.add({'idMapel': data['idMapel'], 'nama': namaMapel});
//         }
//       }
//     } catch(e) { Get.snackbar("Error", "Gagal memuat data guru & mapel: $e"); } 
//   }

//   void updatePelajaran(int index, String key, dynamic value) {
//     final pelajaran = jadwalPelajaran[selectedHari.value]![index];
//     if (key == 'idMapel') {
//       final mapel = daftarMapelTersedia.firstWhere((m) => m['idMapel'] == value, orElse: () => {});
//       pelajaran['idMapel'] = value;
//       pelajaran['namaMapel'] = mapel['nama'];
//       pelajaran['idGuru'] = null;
//       pelajaran['namaGuru'] = null;
//     } else if (key == 'idGuru') {
//       final guru = daftarGuruTersedia.firstWhere((g) => g['uid'] == value, orElse: () => {});
//       pelajaran['idGuru'] = value;
//       // --- [PERBAIKAN] Simpan 'alias' guru ke dalam jadwal ---
//       pelajaran['namaGuru'] = guru['alias'];
//       // -------------------------------------------------------
//     } else {
//       pelajaran[key] = value;
//     }
//     jadwalPelajaran[selectedHari.value]!.refresh();
//   }

//   void _clearJadwal() { 
//     for (var hari in daftarHari) { 
//       jadwalPelajaran[hari]?.clear(); 
//     } 
//   }
  
//   void tambahPelajaran() {
//     jadwalPelajaran[selectedHari.value]?.add({
//       'jam': null, 'idMapel': null, 'namaMapel': null, 'idGuru': null, 'namaGuru': null,
//     });
//   }

//   void hapusPelajaran(int index) {
//     jadwalPelajaran[selectedHari.value]?.removeAt(index);
//   }

//   Future<void> simpanJadwal() async {
//     if (selectedKelasId.value == null) return;
//     isSaving.value = true;
    
//     final String? errorMessage = await _validateGuruClash();
//     if (errorMessage != null) {
//       Get.snackbar('Jadwal Bentrok!', errorMessage, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
//       isSaving.value = false;
//       return;
//     }

//     try {
//       Map<String, List<Map<String, dynamic>>> dataToSave = {};
//       jadwalPelajaran.forEach((hari, list) { dataToSave[hari] = list.toList(); });
      
//       await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).set(dataToSave);
//       Get.snackbar('Berhasil', 'Jadwal pelajaran berhasil disimpan.');
//     } catch (e) { Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}'); } 
//     finally { isSaving.value = false; }
//   }

//   Future<String?> _validateGuruClash() async {
//     final otherSchedulesSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').where(FieldPath.documentId, isNotEqualTo: selectedKelasId.value!).get();
//     final Map<String, String> guruBookings = {};

//     for (var doc in otherSchedulesSnapshot.docs) {
//       final idKelasLain = doc.id;
//       doc.data().forEach((hari, listPelajaran) {
//         if (listPelajaran is List) {
//           for (var pelajaran in listPelajaran) {
//             final jam = pelajaran['jam'] as String?;
//             final idGuru = pelajaran['idGuru'] as String?;
//             if (jam != null && idGuru != null) {
//               guruBookings['$idGuru-$hari-$jam'] = daftarKelas.firstWhere((k) => k['id'] == idKelasLain, orElse: () => {'nama': '?'})['nama'];
//             }
//           }
//         }
//       });
//     }

//     for (var hari in jadwalPelajaran.keys) {
//       for (var slot in jadwalPelajaran[hari]!) {
//         final jam = slot['jam'] as String?;
//         final idGuru = slot['idGuru'] as String?;
//         if (jam == null || idGuru == null) continue;

//         final key = '$idGuru-$hari-$jam';
//         if (guruBookings.containsKey(key)) {
//           final namaGuru = daftarGuruTersedia.firstWhere((g) => g['uid'] == idGuru, orElse: () => {'nama': '?'})['nama'];
//           return "Bentrok: $namaGuru sudah terjadwal di Kelas ${guruBookings[key]} pada hari $hari, jam $jam.";
//         }
//       }
//     }
//     return null;
//   }
// }