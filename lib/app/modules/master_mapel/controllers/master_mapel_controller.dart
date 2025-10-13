// lib/app/modules/master_mapel/controllers/master_mapel_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class MasterMapelController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  
  final isLoading = false.obs;
  final isProcessing = false.obs; // Untuk tombol simpan di dialog
  
  final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;
  final Rxn<String> faseTerpilih = Rxn<String>();

  final List<String> daftarFase = ['fase_a', 'fase_b', 'fase_c'];

  final TextEditingController namaMapelC = TextEditingController();
  final TextEditingController singkatanMapelC = TextEditingController();

  StreamSubscription? _mapelSubscription;

  @override
  void onClose() {
    _mapelSubscription?.cancel();
    namaMapelC.dispose();
    singkatanMapelC.dispose();
    super.onClose();
  }

  String _generateIdMapel(String nama) {
    String safeName = nama.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').substring(0, min(nama.length, 15));
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomStr = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
    return '${safeName}_$randomStr';
  }

  Future<void> pilihFase(String fase) async {
    if (faseTerpilih.value == fase && daftarMapel.isNotEmpty) return;
    faseTerpilih.value = fase;
    isLoading.value = true;
    await _mapelSubscription?.cancel(); // Selalu batalkan listener lama
  
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(fase);
    
    _mapelSubscription = docRef.snapshots().listen((doc) {
      if (doc.exists && doc.data()?['matapelajaran'] != null) {
        final List<dynamic> mapelDariDB = doc.data()!['matapelajaran'];
        daftarMapel.assignAll(List<Map<String, dynamic>>.from(mapelDariDB));
      } else {
        daftarMapel.clear();
      }
      isLoading.value = false;
    }, onError: (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
      isLoading.value = false;
    });
  }
  
  Future<void> _runBatchOperation({required WriteBatch batch, required String successMessage}) async {
    isProcessing.value = true;
    try {
      await batch.commit();
      await pilihFase(faseTerpilih.value!); // Reload data
      Get.back();
      Get.snackbar('Berhasil', successMessage);
    } catch (e) { Get.snackbar('Error', 'Operasi gagal: $e'); } 
    finally { isProcessing.value = false; }
  }

  Future<void> tambahMapel() async {
    if (faseTerpilih.value == null || namaMapelC.text.isEmpty) return;
    
    final newMapel = {
      'idMapel': _generateIdMapel(namaMapelC.text),
      'nama': namaMapelC.text.trim(),
      'singkatan': singkatanMapelC.text.trim(),
    };
    
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(faseTerpilih.value!);
    WriteBatch batch = _firestore.batch();
    batch.set(docRef, {'matapelajaran': FieldValue.arrayUnion([newMapel])}, SetOptions(merge: true));
    _runBatchOperation(batch: batch, successMessage: 'Mata pelajaran berhasil ditambahkan.');
  }

  Future<void> editMapel(Map<String, dynamic> mapelLama) async {
    if (faseTerpilih.value == null || namaMapelC.text.isEmpty) return;
    
    final mapelBaru = {
      'idMapel': mapelLama['idMapel'] ?? _generateIdMapel(namaMapelC.text),
      'nama': namaMapelC.text.trim(),
      'singkatan': singkatanMapelC.text.trim(),
    };
    
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(faseTerpilih.value!);
    WriteBatch batch = _firestore.batch();
    batch.update(docRef, {'matapelajaran': FieldValue.arrayRemove([mapelLama])});
    batch.update(docRef, {'matapelajaran': FieldValue.arrayUnion([mapelBaru])});
    _runBatchOperation(batch: batch, successMessage: 'Mata pelajaran berhasil diperbarui.');
  }
  
  Future<void> hapusMapel(Map<String, dynamic> mapel) async {
    if (faseTerpilih.value == null) return;
    
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kurikulum').doc(faseTerpilih.value!);
    WriteBatch batch = _firestore.batch();
    batch.update(docRef, {'matapelajaran': FieldValue.arrayRemove([mapel])});
    _runBatchOperation(batch: batch, successMessage: 'Mata pelajaran berhasil dihapus.');
  }
}