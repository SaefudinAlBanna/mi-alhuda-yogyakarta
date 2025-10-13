import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/buku_model.dart';

class CreateEditBukuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isEditMode = false.obs;
  final isSaving = false.obs;
  String? bukuId;

  final formKey = GlobalKey<FormState>();
  final namaC = TextEditingController();
  final deskripsiC = TextEditingController();
  final hargaC = TextEditingController();
  final isPaket = false.obs;
  final RxList<String> daftarBukuDiPaket = <String>[].obs;
  final bukuPaketC = TextEditingController(); // Untuk input item paket

  @override
  void onInit() {
    super.onInit();
    final dynamic argument = Get.arguments;
    if (argument is BukuModel) {
      isEditMode.value = true;
      bukuId = argument.id;
      _fillForm(argument);
    }
  }

  void _fillForm(BukuModel buku) {
    namaC.text = buku.namaItem;
    deskripsiC.text = buku.deskripsi;
    hargaC.text = buku.harga.toString();
    isPaket.value = buku.isPaket;
    daftarBukuDiPaket.assignAll(List<String>.from(buku.daftarBukuDiPaket));
  }

  void tambahBukuKePaket() {
    if (bukuPaketC.text.trim().isNotEmpty) {
      daftarBukuDiPaket.add(bukuPaketC.text.trim());
      bukuPaketC.clear();
    }
  }

  void hapusBukuDariPaket(int index) {
    daftarBukuDiPaket.removeAt(index);
  }

  Future<void> simpanBuku() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Peringatan", "Harap periksa kembali data yang Anda isi.");
      return;
    }
    
    isSaving.value = true;
    try {
      final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('buku_ditawarkan').doc(bukuId);

      final dataToSave = {
        'namaItem': namaC.text.trim(),
        'deskripsi': deskripsiC.text.trim(),
        'harga': int.tryParse(hargaC.text) ?? 0,
        'isPaket': isPaket.value,
        'daftarBukuDiPaket': isPaket.value ? daftarBukuDiPaket.toList() : [],
        'tahunAjaran': configC.tahunAjaranAktif.value,
        // 'targetKelas' bisa ditambahkan di sini jika perlu
      };

      await ref.set(dataToSave, SetOptions(merge: true));
      
      Get.back();
      Get.snackbar("Berhasil", "Data buku telah disimpan.", backgroundColor: Colors.green);

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    namaC.dispose();
    deskripsiC.dispose();
    hargaC.dispose();
    bukuPaketC.dispose();
    super.onClose();
  }
}