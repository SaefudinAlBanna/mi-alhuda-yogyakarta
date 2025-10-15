// lib/app/modules/create_edit_ekskul/controllers/create_edit_ekskul_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/ekskul_model.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_simple_model.dart';

enum JenisPembina { internal, eksternal }

class CreateEditEkskulController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State
  final isEditMode = false.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  String? ekskulId;

  // Form State
  final formKey = GlobalKey<FormState>();
  final namaC = TextEditingController();
  final deskripsiC = TextEditingController();
  final tujuanC = TextEditingController();
  final jadwalC = TextEditingController();
  final biayaC = TextEditingController();
  
  // --- [DIUBAH] Logika Pembina Fleksibel ---
  final RxList<Map<String, dynamic>> listPembinaTerpilih = <Map<String, dynamic>>[].obs;
  
  final Rxn<PegawaiSimpleModel> selectedPJ = Rxn<PegawaiSimpleModel>();
  final RxList<PegawaiSimpleModel> daftarPegawai = <PegawaiSimpleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final dynamic argument = Get.arguments;
    if (argument is EkskulModel) {
      isEditMode.value = true;
      ekskulId = argument.id;
    }
    _loadInitialData(argument as EkskulModel?);
  }

  Future<void> _loadInitialData(EkskulModel? ekskulToEdit) async {
    isLoading.value = true;
    try {
      final pegawaiSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
      daftarPegawai.assignAll(pegawaiSnap.docs.map((doc) => PegawaiSimpleModel.fromFirestore(doc)).toList());
      
      if (isEditMode.value && ekskulToEdit != null) {
        namaC.text = ekskulToEdit.namaEkskul;
        deskripsiC.text = ekskulToEdit.deskripsi;
        tujuanC.text = ekskulToEdit.tujuan;
        jadwalC.text = ekskulToEdit.jadwalTeks;
        biayaC.text = ekskulToEdit.biaya.toString();
        
        // --- [FIX] Akses properti langsung dari model ---
        listPembinaTerpilih.assignAll(List<Map<String, dynamic>>.from(ekskulToEdit.listPembina));
        
        final pjData = ekskulToEdit.penanggungJawab;
        selectedPJ.value = daftarPegawai.firstWhereOrNull((p) => p.uid == pjData['id']);
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat data: $e"); } 
    finally { isLoading.value = false; }
  }

  void openAddPembinaInternalDialog() {
    final RxList<PegawaiSimpleModel> selection = <PegawaiSimpleModel>[].obs;
    Get.defaultDialog(
      title: "Pilih Pembina Internal",
      content: SizedBox(
        width: Get.width * 0.8,
        height: Get.height * 0.4,
        // Hapus Obx yang membungkus ListView
        child: ListView.builder(
          itemCount: daftarPegawai.length,
          itemBuilder: (context, index) {
            final pegawai = daftarPegawai[index];
            // --- [FIX] Bungkus setiap CheckboxListTile dengan Obx-nya sendiri ---
            return Obx(() => CheckboxListTile(
              title: Text(pegawai.nama),
              value: selection.contains(pegawai),
              onChanged: (isSelected) {
                if (isSelected!) {
                  selection.add(pegawai);
                } else {
                  selection.remove(pegawai);
                }
              },
            ));
          },
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          for (var pegawai in selection) {
            if (!listPembinaTerpilih.any((p) => p['jenis'] == 'internal' && p['id'] == pegawai.uid)) {
              listPembinaTerpilih.add({
                'jenis': 'internal',
                'id': pegawai.uid,
                // --- [FIX] Gunakan alias jika ada, jika tidak baru gunakan nama ---
                'nama': pegawai.alias.isNotEmpty ? pegawai.alias : pegawai.nama
              });
            }
          }
          Get.back();
        },
        child: const Text("Tambah Terpilih"),
      ),
      cancel: TextButton(
        onPressed: Get.back, 
        child: const Text("Batal")),
    );
  }

  void openAddPembinaEksternalDialog() {
    final namaEksternalC = TextEditingController();
    Get.defaultDialog(
      title: "Tambah Pembina Eksternal",
      content: TextField(controller: namaEksternalC, decoration: const InputDecoration(labelText: "Nama Pembina")),
      confirm: ElevatedButton(
        onPressed: () {
          if (namaEksternalC.text.trim().isNotEmpty) {
            listPembinaTerpilih.add({
              'jenis': 'eksternal', 'nama': namaEksternalC.text.trim()
            });
            Get.back();
          }
        },
        child: const Text("Tambah"),
      ),
    );
  }

  void removePembina(int index) {
    listPembinaTerpilih.removeAt(index);
  }

  Future<void> saveEkskul() async {
    // 1. Validasi Form Input
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Peringatan", "Harap periksa kembali data yang Anda isi.");
      return;
    }
    // 2. Validasi Pembina & PJ
    if (listPembinaTerpilih.isEmpty) {
      Get.snackbar("Peringatan", "Harap tambahkan minimal satu pembina.");
      return;
    }
    if (selectedPJ.value == null) {
      Get.snackbar("Peringatan", "Harap pilih seorang Penanggung Jawab (PJ).");
      return;
    }
    
    isSaving.value = true;
    try {
      // Referensi ke dokumen di Firestore
      final ekskulRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('ekskul_ditawarkan').doc(ekskulId); // Jika ekskulId null, ID baru akan dibuat

      // Ambil data PJ terpilih
      final pj = selectedPJ.value!;
      // Tentukan nama PJ (prioritaskan alias)
      final namaPjToShow = pj.alias.isNotEmpty ? pj.alias : pj.nama;

      // Siapkan data lengkap untuk disimpan
      final Map<String, dynamic> dataToSave = {
        'namaEkskul': namaC.text.trim(),
        'deskripsi': deskripsiC.text.trim(),
        'tujuan': tujuanC.text.trim(),
        'jadwalTeks': jadwalC.text.trim(),
        'biaya': int.tryParse(biayaC.text.trim()) ?? 0,
        // Gunakan list pembina yang sudah dikelola (sudah berisi alias jika ada)
        'listPembina': listPembinaTerpilih.toList(),
        'penanggungJawab': {
          'id': pj.uid,
          'nama': namaPjToShow, // Gunakan nama yang sudah diprioritaskan
        },
        'tahunAjaran': configC.tahunAjaranAktif.value,
        'semester': configC.semesterAktif.value,
      };

      // Simpan data ke Firestore
      await ekskulRef.set(dataToSave, SetOptions(merge: true));
      
      Get.back(); // Kembali ke halaman manajemen
      Get.snackbar("Berhasil", "Data ekstrakurikuler telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    namaC.dispose(); deskripsiC.dispose(); tujuanC.dispose();
    jadwalC.dispose(); biayaC.dispose();
    super.onClose();
  }
}