// lib/app/modules/manajemen_tunggakan_awal/controllers/manajemen_tunggakan_awal_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../controllers/config_controller.dart';

// Model sederhana untuk menampung data siswa yang relevan
class SiswaSimpleModel {
  final String uid;
  final String nama;
  final String nisn;
  final String kelasId;
  final String kelasNama;

  SiswaSimpleModel({
    required this.uid,
    required this.nama,
    required this.nisn,
    required this.kelasId,
    required this.kelasNama,
  });
}

class ManajemenTunggakanAwalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // --- State UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;

  // --- State Data & Filter ---
  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  final RxList<SiswaSimpleModel> daftarSemuaSiswa = <SiswaSimpleModel>[].obs;
  final RxList<SiswaSimpleModel> daftarSiswaTampil = <SiswaSimpleModel>[].obs;
  final Rxn<String> kelasTerpilih = Rxn<String>();
  final searchC = TextEditingController();

  // --- State Form ---
  final Rxn<SiswaSimpleModel> siswaTerpilih = Rxn<SiswaSimpleModel>();
  final totalTunggakanC = TextEditingController();
  final keteranganC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchDaftarKelas(),
        _fetchSemuaSiswa(),
      ]);
      daftarSiswaTampil.assignAll(daftarSemuaSiswa); // Tampilkan semua di awal
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDaftarKelas() async {
    final snap = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('master_kelas').orderBy('urutan').get();
    
    final List<Map<String, String>> listKelas = [];
    for (var doc in snap.docs) {
      listKelas.add({
        'id': doc.data()['namaKelas'], 
        'nama': doc.data()['namaKelas']
      });
    }
    daftarKelas.assignAll(listKelas);
  }

  Future<void> _fetchSemuaSiswa() async {
    final taAktif = configC.tahunAjaranAktif.value;
    final snap = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa')
        .where('statusSiswa', isEqualTo: 'Aktif')
        .orderBy('namaLengkap')
        .get();
    
    final List<SiswaSimpleModel> listSiswa = [];
    for (var doc in snap.docs) {
      final data = doc.data();
      final kelasId = data['kelasId'] as String?;
      if (kelasId != null && kelasId.contains(taAktif)) {
        listSiswa.add(SiswaSimpleModel(
          uid: doc.id,
          nama: data['namaLengkap'],
          nisn: data['nisn'] ?? 'N/A',
          kelasId: kelasId,
          kelasNama: kelasId.split('-').first,
        ));
      }
    }
    daftarSemuaSiswa.assignAll(listSiswa);
  }

  void filterSiswa() {
    final query = searchC.text.toLowerCase();
    final kelas = kelasTerpilih.value;

    List<SiswaSimpleModel> filtered = daftarSemuaSiswa.where((siswa) {
      final bool matchesKelas = kelas == null || siswa.kelasNama == kelas;
      final bool matchesQuery = query.isEmpty ||
          siswa.nama.toLowerCase().contains(query) ||
          siswa.nisn.toLowerCase().contains(query);
      return matchesKelas && matchesQuery;
    }).toList();

    daftarSiswaTampil.assignAll(filtered);
  }

  Future<void> pilihSiswa(SiswaSimpleModel siswa) async {
    siswaTerpilih.value = siswa;
    totalTunggakanC.clear();
    keteranganC.clear();

    // Ambil data tunggakan yang sudah ada (jika ada)
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tunggakanAwal').doc(siswa.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data()!;
      totalTunggakanC.text = (data['totalTunggakan'] ?? 0).toString();
      keteranganC.text = data['keterangan'] ?? '';
    }
  }

  void clearSelection() {
    siswaTerpilih.value = null;
    totalTunggakanC.clear();
    keteranganC.clear();
  }

  Future<void> simpanTunggakanAwal() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (siswaTerpilih.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih siswa terlebih dahulu.");
      return;
    }

    isSaving.value = true;
    try {
      final int total = int.tryParse(totalTunggakanC.text.replaceAll('.', '')) ?? 0;
      final String ket = keteranganC.text;

      final dataToSave = {
        "totalTunggakan": total,
        "keterangan": ket,
        "uidSiswa": siswaTerpilih.value!.uid,
        "namaSiswa": siswaTerpilih.value!.nama,
        "kelasSaatInput": siswaTerpilih.value!.kelasId,
        "diinputOleh": configC.infoUser['uid'],
        "diinputOlehNama": _getPencatatNama(),
        "diinputPada": FieldValue.serverTimestamp(),
        "lunas": false,
        "sisaTunggakan": total,
      };

      await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tunggakanAwal').doc(siswaTerpilih.value!.uid)
          .set(dataToSave, SetOptions(merge: true));

      Get.snackbar("Berhasil", "Data tunggakan awal untuk ${siswaTerpilih.value!.nama} berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
      clearSelection();

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  String _getPencatatNama() {
    final alias = configC.infoUser['alias'] as String?;
    if (alias != null && alias.isNotEmpty && alias != 'N/A') return alias;
    return configC.infoUser['nama'] ?? 'User';
  }

  @override
  void onClose() {
    searchC.dispose();
    totalTunggakanC.dispose();
    keteranganC.dispose();
    super.onClose();
  }
}