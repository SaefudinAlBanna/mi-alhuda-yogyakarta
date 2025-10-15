// lib/app/modules/halaqah_grading/controllers/halaqah_grading_controller.dart


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/halaqah_setoran_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/siswa_simple_model.dart';

import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../views/halaqah_grading_view.dart';



class HalaqahGradingController extends GetxController {
  late HalaqahGroupModel group;
  late Future<List<SiswaSimpleModel>> listAnggotaFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final RxMap<String, Timestamp> antrianMap = <String, Timestamp>{}.obs;

  @override
  void onInit() {
    super.onInit();
    group = Get.arguments as HalaqahGroupModel;
    listAnggotaFuture = fetchAnggota();
  }

  void goToRiwayatSiswa(SiswaSimpleModel siswa) {
    Get.toNamed(Routes.HALAQAH_RIWAYAT_PENGAMPU, arguments: siswa);
  }

  void goToSetoranPage(SiswaSimpleModel siswa) {
    Get.toNamed(
      Routes.HALAQAH_SETORAN_SISWA,
      arguments: {
        'siswa': siswa,
        'isPengganti': group.isPengganti,
        // --- [BARU] Kirim juga data pengampu utama ---
        'pengampuUtama': {
          'id': group.idPengampu,
          'nama': group.namaPengampu,
        }
      },
    );
  }

  Future<List<SiswaSimpleModel>> fetchAnggota() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;

    final groupRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup').doc(group.id);
    
    // Ambil data anggota dan antrian secara bersamaan
    final results = await Future.wait([
      groupRef.collection('anggota').get(),
      groupRef.get(),
    ]);

    final anggotaSnapshot = results[0] as QuerySnapshot;
    final groupSnapshot = results[1] as DocumentSnapshot;

    // Ambil data antrian dari dokumen grup
    final dataAntrian = (groupSnapshot.data() as Map<String, dynamic>?)?['antrianSetoran'] as Map<String, dynamic>? ?? {};
    
    antrianMap.clear();
    dataAntrian.forEach((uid, data) {
      antrianMap[uid] = data['waktu'] as Timestamp;
    });

    return anggotaSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SiswaSimpleModel(
        uid: doc.id,
        nama: data['namaSiswa'] ?? 'Tanpa Nama',
        kelasId: data['kelasAsal'] ?? 'N/A',
        tingkat: 'Jilid',
        detailTingkat: '1',
      );
    }).toList();
  }
  
  @override
  void onClose() {
    super.onClose();
  }
}