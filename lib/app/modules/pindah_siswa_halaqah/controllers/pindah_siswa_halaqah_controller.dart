// lib/app/modules/pindah_siswa_halaqah/controllers/pindah_siswa_halaqah_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/siswa_simple_model.dart';

class PindahSiswaHalaqahController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State Halaman
  final isLoading = true.obs;
  final isProcessing = false.obs;
  
  // Data
  late HalaqahGroupUmmiModel grupAsal;
  final RxList<SiswaSimpleModel> anggotaGrupAsal = <SiswaSimpleModel>[].obs;
  final RxList<HalaqahGroupUmmiModel> grupTujuanList = <HalaqahGroupUmmiModel>[].obs;

  // State Pilihan Pengguna
  final RxList<SiswaSimpleModel> siswaTerpilih = <SiswaSimpleModel>[].obs;
  final Rxn<HalaqahGroupUmmiModel> selectedGrupTujuan = Rxn<HalaqahGroupUmmiModel>();

  @override
  void onInit() {
    super.onInit();
    grupAsal = Get.arguments as HalaqahGroupUmmiModel;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchAnggotaGrupAsal(),
        _fetchGrupTujuan(),
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAnggotaGrupAsal() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup_ummi').doc(grupAsal.id)
        .collection('anggota').get();
    
    anggotaGrupAsal.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      return SiswaSimpleModel(
        uid: doc.id,
        nama: data['namaSiswa'] ?? 'Tanpa Nama',
        kelasId: data['kelasAsal'] ?? 'N/A',
        tingkat: '', // Tidak perlu ditampilkan di sini
        detailTingkat: '', // Tidak perlu ditampilkan di sini
      );
    }).toList());
  }

  Future<void> _fetchGrupTujuan() async {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup_ummi').get();

    // Filter untuk menampilkan semua grup KECUALI grup asal
    final list = snapshot.docs
        .where((doc) => doc.id != grupAsal.id)
        .map((doc) => HalaqahGroupUmmiModel.fromFirestore(doc))
        .toList();
    
    grupTujuanList.assignAll(list);
  }

  void toggleSiswa(SiswaSimpleModel siswa) {
    if (siswaTerpilih.contains(siswa)) {
      siswaTerpilih.remove(siswa);
    } else {
      siswaTerpilih.add(siswa);
    }
  }

  Future<void> prosesPindahSiswa() async {
    if (siswaTerpilih.isEmpty || selectedGrupTujuan.value == null) {
      Get.snackbar("Peringatan", "Pilih minimal satu siswa dan satu grup tujuan.");
      return;
    }

    Get.defaultDialog(
      title: "Konfirmasi Pemindahan",
      middleText: "Anda akan memindahkan ${siswaTerpilih.length} siswa dari grup '${grupAsal.namaGrup}' ke grup '${selectedGrupTujuan.value!.namaGrup}'. Lanjutkan?",
      confirm: ElevatedButton(
        onPressed: () async {
          Get.back();
          isProcessing.value = true;
          try {
            final WriteBatch batch = _firestore.batch();
            final tahunAjaran = configC.tahunAjaranAktif.value;
            final grupTujuan = selectedGrupTujuan.value!;

            final grupAsalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_grup_ummi').doc(grupAsal.id);
            final grupTujuanRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_grup_ummi').doc(grupTujuan.id);

            for (var siswa in siswaTerpilih) {
              final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);

              // 1. Hapus dari sub-koleksi anggota grup lama
              batch.delete(grupAsalRef.collection('anggota').doc(siswa.uid));

              // 2. Tambahkan ke sub-koleksi anggota grup baru
              batch.set(grupTujuanRef.collection('anggota').doc(siswa.uid), {
                'namaSiswa': siswa.nama,
                'kelasAsal': siswa.kelasId,
                'tahunAjaran': tahunAjaran,
              });

              // 3. Update field 'halaqahUmmi' di dokumen siswa
              batch.update(siswaRef, {
                'halaqahUmmi.idGrup': grupTujuan.id,
                'halaqahUmmi.faseGrup': grupTujuan.fase,
                'halaqahUmmi.namaPengampu': grupTujuan.namaPengampu,
              });
            }

            await batch.commit();

            Get.back(); // Kembali ke halaman manajemen
            Get.snackbar("Berhasil", "${siswaTerpilih.length} siswa berhasil dipindahkan.", backgroundColor: Colors.green, colorText: Colors.white);

          } catch (e) {
            Get.snackbar("Error", "Gagal memindahkan siswa: ${e.toString()}");
          } finally {
            isProcessing.value = false;
          }
        },
        child: const Text("Ya, Pindahkan"),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }
}