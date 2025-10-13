// lib/app/modules/atp_form/controllers/atp_form_controller.dart (FINAL DENGAN VALIDASI)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/atp_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/perangkat_ajar/controllers/perangkat_ajar_controller.dart';
import 'package:uuid/uuid.dart';

class AtpFormController extends GetxController {
  final PerangkatAjarController _perangkatAjarC = Get.find<PerangkatAjarController>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var uuid = const Uuid();

  final RxBool isEditMode = false.obs;
  AtpModel? originalAtp;

  // --- State Penugasan ---
  final RxBool isPenugasanLoading = true.obs;
  final List<Map<String, dynamic>> penugasanGuru = []; // Data mentah dari Firestore

  // --- State Form Utama ---
  final TextEditingController capaianPembelajaranC = TextEditingController();
  final RxList<String> daftarMapelUnik = <String>[].obs; // Hanya nama mapel unik
  final RxList<String> daftarKelasTersedia = <String>[].obs; // Kelas yang tersedia setelah mapel dipilih
  final Rxn<String> mapelTerpilih = Rxn<String>();
  final Rxn<String> kelasTerpilih = Rxn<String>();
  final RxString faseTerpilih = ''.obs;

  // --- State Unit Pembelajaran Dinamis ---
  final RxList<UnitPembelajaranForm> unitPembelajaranForms = <UnitPembelajaranForm>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadPenugasanGuru(); // Ganti _loadInitialData dengan ini
    if (Get.arguments != null && Get.arguments is AtpModel) {
      isEditMode.value = true;
      originalAtp = Get.arguments as AtpModel;
      _fillFormWithData(originalAtp!);
    }
  }


    @override
  void onClose() {
    capaianPembelajaranC.dispose();
    for (var unitForm in unitPembelajaranForms) {
      unitForm.dispose();
    }
    super.onClose();
  }

  Future<void> _loadPenugasanGuru() async {
    isPenugasanLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').doc(configC.infoUser['uid'])
          .collection('jadwal_mengajar').doc(configC.tahunAjaranAktif.value)
          .collection('mapel_diampu').get();

      penugasanGuru.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
      
      // Buat daftar mapel unik dari data penugasan
      final mapelSet = <String>{};
      for (var tugas in penugasanGuru) {
        mapelSet.add(tugas['namamatapelajaran']);
      }
      daftarMapelUnik.assignAll(mapelSet.toList()..sort());

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penugasan mengajar Anda.");
    } finally {
      isPenugasanLoading.value = false;
    }
  }

  void _fillFormWithData(AtpModel atp) {
    mapelTerpilih.value = atp.namaMapel;
    // Panggil onMapelChanged untuk mengisi daftar kelas yang relevan
    onMapelChanged(atp.namaMapel); 
    kelasTerpilih.value = atp.kelas.toString();
    faseTerpilih.value = atp.fase;
    capaianPembelajaranC.text = atp.capaianPembelajaran;
    unitPembelajaranForms.value = atp.unitPembelajaran.map((unit) => UnitPembelajaranForm.fromModel(unit)).toList();
  }

  void onMapelChanged(String? newValue) {
    mapelTerpilih.value = newValue;
    // Reset pilihan kelas & fase
    kelasTerpilih.value = null;
    faseTerpilih.value = '';
    daftarKelasTersedia.clear();

    if (newValue != null) {
      // Filter penugasan untuk mapel yang dipilih, lalu ambil kelasnya
      final kelasSet = <String>{};
      for (var tugas in penugasanGuru) {
        if (tugas['namamatapelajaran'] == newValue) {
          // Ambil hanya angka dari ID kelas (e.g., '4' dari '4A-2024')
          final kelasAngka = tugas['idKelas'].split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
          if (kelasAngka.isNotEmpty) kelasSet.add(kelasAngka);
        }
      }
      daftarKelasTersedia.assignAll(kelasSet.toList()..sort());
    }
  }

  void onKelasChanged(String? newValue) {
    kelasTerpilih.value = newValue;
    if (newValue != null) {
      int kelasAngka = int.tryParse(newValue) ?? 0;
      if (kelasAngka <= 2) faseTerpilih.value = 'A';
      else if (kelasAngka <= 4) faseTerpilih.value = 'B';
      else if (kelasAngka <= 6) faseTerpilih.value = 'C';
      else faseTerpilih.value = '';
    }
  }

  void addUnitPembelajaran() {
    unitPembelajaranForms.add(UnitPembelajaranForm());
  }

  void removeUnitPembelajaran(int index) {
    unitPembelajaranForms[index].dispose();
    unitPembelajaranForms.removeAt(index);
  }

  Future<void> saveAtp() async {
    if (mapelTerpilih.value == null || kelasTerpilih.value == null || capaianPembelajaranC.text.trim().isEmpty) {
      Get.snackbar("Validasi Gagal", "Informasi umum (Mapel, Kelas, CP) wajib diisi.", backgroundColor: Colors.orange);
      return;
    }
    if (unitPembelajaranForms.isEmpty) {
      Get.snackbar("Validasi Gagal", "Minimal harus ada satu Unit Pembelajaran.", backgroundColor: Colors.orange);
      return;
    }

    AtpModel atpData = AtpModel(
      idAtp: originalAtp?.idAtp ?? '',
      idSekolah: configC.idSekolah,
      idPenyusun: configC.infoUser['uid'],
      namaPenyusun: configC.infoUser['alias'] ?? configC.infoUser['nama'],
      idTahunAjaran: configC.tahunAjaranAktif.value,
      namaMapel: mapelTerpilih.value!,
      fase: faseTerpilih.value,
      kelas: int.parse(kelasTerpilih.value!),
      capaianPembelajaran: capaianPembelajaranC.text.trim(),
      createdAt: originalAtp?.createdAt ?? Timestamp.now(),
      lastModified: Timestamp.now(),
      unitPembelajaran: unitPembelajaranForms.map((form) => form.toModel()).toList(),
    );

    if (isEditMode.value) {
      await _perangkatAjarC.updateAtp(atpData);
    } else {
      await _perangkatAjarC.createAtp(atpData);
    }
  }
}

// Helper class untuk mengelola state form per Unit Pembelajaran
  class UnitPembelajaranForm {
    late TextEditingController lingkupMateriC;
    late TextEditingController alokasiWaktuC;
    RxList<String> tujuanPembelajaran = <String>[].obs;

    UnitPembelajaranForm() {
      lingkupMateriC = TextEditingController();
      alokasiWaktuC = TextEditingController();
    }
    
    factory UnitPembelajaranForm.fromModel(UnitPembelajaran model) {
      final form = UnitPembelajaranForm();
      form.lingkupMateriC.text = model.lingkupMateri;
      form.alokasiWaktuC.text = model.alokasiWaktu;
      form.tujuanPembelajaran.value = List<String>.from(model.tujuanPembelajaran);
      return form;
    }

    UnitPembelajaran toModel() {
      return UnitPembelajaran(
        idUnit: const Uuid().v4(),
        urutan: 0,
        lingkupMateri: lingkupMateriC.text.trim(),
        alokasiWaktu: alokasiWaktuC.text.trim(),
        tujuanPembelajaran: List<String>.from(tujuanPembelajaran),
        // Atribut lain dari model Anda yang mungkin tidak ada di form ini
        jenisTeks: '', 
        gramatika: '',
        alurPembelajaran: [],
      );
    }

    void dispose() {
      lingkupMateriC.dispose();
      alokasiWaktuC.dispose();
    }
  }