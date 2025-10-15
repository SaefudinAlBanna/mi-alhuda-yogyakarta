// lib/app/modules/pemberian_kelas_siswa/controllers/pemberian_kelas_siswa_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_model.dart';

class PemberianKelasSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Worker _statusWorker;

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isWaliKelasLoading = false.obs;

  final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
  final Rxn<DocumentSnapshot> kelasTerpilih = Rxn<DocumentSnapshot>();

  final RxList<SiswaModel> siswaDiKelas = <SiswaModel>[].obs;
  final RxList<SiswaModel> siswaTanpaKelas = <SiswaModel>[].obs;
  
  final RxList<PegawaiModel> daftarGuru = <PegawaiModel>[].obs;
  final RxString searchQueryGuru = "".obs;
  final RxSet<String> assignedWaliKelasUids = <String>{}.obs;
  final RxList<Map<String, dynamic>> daftarMasterKelas = <Map<String, dynamic>>[].obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;
  String get semesterAktif => configC.semesterAktif.value;
  
  @override
  void onInit() {
    super.onInit();
    _statusWorker = ever(configC.status, (appStatus) {
      if (appStatus == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
    if (configC.status.value == AppStatus.authenticated) {
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
    await Future.wait([
      fetchKelas(),
      fetchSiswaTanpaKelas(),
      fetchDaftarGuru(),
      _fetchMasterKelas(),
    ]);
    isLoading.value = false;
  }

  Future<void> _fetchMasterKelas() async {
  try {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('master_kelas').orderBy('urutan').get();
    daftarMasterKelas.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
  } catch (e) {
    Get.snackbar("Error", "Gagal memuat data master kelas: $e");
  }
}

  Future<void> fetchKelas() async {
    if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK")) return;
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).get();
    daftarKelas.assignAll(snapshot.docs);
    
    final uids = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['waliKelasUid'] as String?)
        .where((uid) => uid != null && uid.isNotEmpty).cast<String>().toSet();
    assignedWaliKelasUids.assignAll(uids);
  }

  Future<void> fetchSiswaTanpaKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('kelasId', isNull: true).get();
    siswaTanpaKelas.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
  }

  Future<void> fetchDaftarGuru() async {
  final snapshot = await _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('pegawai').where('role', isEqualTo: 'Guru Kelas').get();
  // --- [PERBAIKAN] Langsung gunakan model yang sudah cerdas ---
  daftarGuru.assignAll(snapshot.docs.map((doc) => PegawaiModel.fromFirestore(doc)).toList());
  // -----------------------------------------------------------
}

  Future<void> pilihKelas(DocumentSnapshot kelasDoc) async {
    kelasTerpilih.value = kelasDoc;
    siswaDiKelas.clear();
    final dataKelas = kelasDoc.data() as Map<String, dynamic>;
    final List<String> siswaUids = List<String>.from(dataKelas['siswaUids'] ?? []);
    if (siswaUids.isNotEmpty) {
      final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where(FieldPath.documentId, whereIn: siswaUids).get();
      siswaDiKelas.assignAll(siswaSnapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
    }
  }

  // --- FUNGSI DIPERBAIKI DENGAN DENORMALISASI ---
  Future<void> addSiswaToKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;
    
    final kelasDoc = kelasTerpilih.value!;
    final kelasRef = kelasDoc.reference;
    final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
    
    final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
  .collection('tahunajaran').doc(tahunAjaranAktif)
  .collection('kelastahunajaran').doc(kelasRef.id);
      
    // final semesterSiswaRef = kelasTahunAjaranRef.collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(siswa.uid);
    final daftarSiswaRef = kelasTahunAjaranRef.collection('daftarsiswa').doc(siswa.uid);

    WriteBatch batch = _firestore.batch();
    
    batch.update(kelasRef, {'siswaUids': FieldValue.arrayUnion([siswa.uid])});
    batch.update(siswaRef, {'kelasId': kelasRef.id, 'statusSiswa': 'Aktif'});
    // batch.set(semesterSiswaRef, {'uid': siswa.uid, 'nisn': siswa.nisn, 'namasiswa': siswa.namaLengkap});
    batch.set(daftarSiswaRef, {'uid': siswa.uid, 'nisn': siswa.nisn, 'namaLengkap': siswa.namaLengkap});
    
    await batch.commit();
    
    siswaTanpaKelas.removeWhere((s) => s.uid == siswa.uid);
    siswaDiKelas.add(siswa);
    isProcessing.value = false;
  }

  // --- FUNGSI DIPERBAIKI DENGAN DENORMALISASI ---
  Future<void> removeSiswaFromKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;

    final kelasRef = kelasTerpilih.value!.reference;
    final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
    final semesterSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif).collection('kelastahunajaran')
      .doc(kelasRef.id).collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(siswa.uid);

    WriteBatch batch = _firestore.batch();
    
    batch.update(kelasRef, {'siswaUids': FieldValue.arrayRemove([siswa.uid])});
    batch.update(siswaRef, {'kelasId': FieldValue.delete(), 'statusSiswa': 'Tidak Aktif'});
    batch.delete(semesterSiswaRef);

    await batch.commit();
    
    siswaDiKelas.removeWhere((s) => s.uid == siswa.uid);
    siswaTanpaKelas.add(siswa);
    isProcessing.value = false;
  }

  // --- FUNGSI LAINNYA TIDAK BERUBAH ---
  void showBuatKelasDialog() {
    final Rxn<Map<String, dynamic>> kelasTerpilihDariMaster = Rxn<Map<String, dynamic>>();

    // Filter master kelas: hanya tampilkan yang belum dibuat di tahun ajaran ini
    final namaKelasYangSudahAda = daftarKelas.map((doc) => (doc.data() as Map)['namaKelas']).toSet();
    final pilihanKelasTersedia = daftarMasterKelas.where((master) => !namaKelasYangSudahAda.contains(master['namaKelas'])).toList();

    Get.defaultDialog(
      title: "Buat Kelas Baru",
      content: Obx(() => DropdownButtonFormField<Map<String, dynamic>>(
        value: kelasTerpilihDariMaster.value,
        hint: const Text("Pilih dari master kelas..."),
        isExpanded: true,
        items: pilihanKelasTersedia.map((masterKelas) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: masterKelas,
            child: Text(masterKelas['namaKelas']),
          );
        }).toList(),
        onChanged: (value) {
          kelasTerpilihDariMaster.value = value;
        },
        validator: (value) => value == null ? 'Pilihan tidak boleh kosong' : null,
      )),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if (kelasTerpilihDariMaster.value != null) {
              Get.back();
              _buatKelas(kelasTerpilihDariMaster.value!);
            } else {
              Get.snackbar("Peringatan", "Anda harus memilih kelas dari daftar.");
            }
          },
          child: const Text("Buat"),
        ),
      ],
    );
  }

  Future<void> _buatKelas(Map<String, dynamic> masterKelasData) async {
    final namaKelas = masterKelasData['namaKelas'];
    final fase = masterKelasData['fase'];

    if (namaKelas == null || namaKelas.isEmpty) return;

    final kelasId = "$namaKelas-$tahunAjaranAktif";
    await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').doc(kelasId).set({
      'namaKelas': namaKelas,
      'tahunAjaran': tahunAjaranAktif,
      'fase': fase,
      'waliKelasUid': null,
      'waliKelasNama': null,
      'siswaUids': [],
    });
    fetchKelas(); // Ambil ulang daftar kelas untuk memperbarui UI
  }

    Future<void> assignWaliKelas(PegawaiModel guru) async {
      if (kelasTerpilih.value == null) return;
      isWaliKelasLoading.value = true;

      final kelasDoc = kelasTerpilih.value!;
      final kelasRef = kelasDoc.reference;
      final guruBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guru.uid);
      final String? guruLamaUid = (kelasDoc.data() as Map<String, dynamic>)['waliKelasUid'];

      WriteBatch batch = _firestore.batch();

      if (guruLamaUid != null && guruLamaUid.isNotEmpty) {
        final guruLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guruLamaUid);
        batch.update(guruLamaRef, {'waliKelasDari': FieldValue.delete()});
      }

      batch.update(guruBaruRef, {'waliKelasDari': kelasRef.id});

      // --- [PERBAIKAN] Simpan alias dan nama lengkap ---
      final namaUntukDitampilkan = (guru.alias == null || guru.alias!.isEmpty) ? guru.nama : guru.alias!;
      batch.update(kelasRef, {
        'waliKelasUid': guru.uid,
        'waliKelasNama': namaUntukDitampilkan, // Ini adalah alias (atau nama jika alias kosong)
        'waliKelasNamaLengkap': guru.nama, // Field baru untuk referensi
      });

      final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('kelastahunajaran').doc(kelasRef.id);

      batch.set(kelasTahunAjaranRef, {
        'idWaliKelas': guru.uid,
        'namaWaliKelas': namaUntukDitampilkan, // Gunakan variabel yang sama
        'namaKelas': (kelasDoc.data() as Map<String, dynamic>)['namaKelas'],
      }, SetOptions(merge: true));
      // --- AKHIR PERBAIKAN ---

      await batch.commit();

      await fetchKelas();
      kelasTerpilih.value = await kelasRef.get();
      isWaliKelasLoading.value = false;
      Get.back();
    }
}
