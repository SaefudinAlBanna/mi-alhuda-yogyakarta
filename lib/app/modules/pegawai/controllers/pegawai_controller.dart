import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_model.dart';
import '../../../routes/app_pages.dart';

class PegawaiController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configController = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE ---
  final RxBool isLoading = true.obs;
  final RxList<PegawaiModel> _semuaPegawai = <PegawaiModel>[].obs;
  final RxList<PegawaiModel> daftarPegawaiFiltered = <PegawaiModel>[].obs;
  
  // --- STATE PENCARIAN & HAPUS ---
  final TextEditingController searchC = TextEditingController();
  final RxString searchQuery = "".obs;
  final TextEditingController passAdminC = TextEditingController();

  // --- GETTER HAK AKSES ---
  bool get canManagePegawai {
    final role = configController.infoUser['role'];
    const allowedRoles = ['Admin', 'Operator', 'TU', 'Tata Usaha', 'Kepala Sekolah'];
    return configController.infoUser['peranSistem'] == 'superadmin' || allowedRoles.contains(role);
  }

  bool get canConfigureRoles {
    final role = configController.infoUser['role'];
    const allowedRoles = ['Kepala Sekolah', 'TU', 'Tata Usaha'];
    final tugas = configController.infoUser['tugas'];
    const allowedTugas = ['Koordinator Kurikulum'];
    return configController.infoUser['peranSistem'] == 'superadmin' || allowedRoles.contains(role) || allowedTugas.contains(tugas);
  }

  @override
  void onInit() {
    super.onInit();
    // Panggil fetchPegawai saat pertama kali controller dibuat
    fetchPegawai();
    // Buat listener yang akan memfilter daftar setiap kali searchQuery berubah
    ever(searchQuery, (_) => _filterData());
  }

  @override
  void onClose() {
    searchC.dispose();
    passAdminC.dispose();
    super.onClose();
  }

  Future<void> fetchPegawai() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('Sekolah')
          .doc(configController.idSekolah)
          .collection('pegawai')
          .orderBy('nama')
          .get();
      
      final tempList = snapshot.docs.map((doc) => PegawaiModel.fromFirestore(doc)).toList();
      _semuaPegawai.assignAll(tempList);
      daftarPegawaiFiltered.assignAll(_semuaPegawai); // Tampilkan semua data pada awalnya
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data pegawai: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void _filterData() {
    String query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      daftarPegawaiFiltered.assignAll(_semuaPegawai);
    } else {
      var filtered = _semuaPegawai.where((pegawai) {
        final String nama = pegawai.nama.toLowerCase();
        final String role = pegawai.role.displayName.toLowerCase();
        // Pencarian bisa ditambahkan untuk tugas jika perlu
        return nama.contains(query) || role.contains(query);
      }).toList();
      daftarPegawaiFiltered.assignAll(filtered);
    }
  }

  void hapusPegawai(PegawaiModel pegawai) {
    Get.defaultDialog(
      title: 'Hapus Pegawai',
      middleText: 'Anda yakin ingin menghapus "${pegawai.nama}"?\n\nUntuk keamanan, masukkan password Admin Anda.',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: passAdminC,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password Admin'),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () { passAdminC.clear(); Get.back(); }, child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _performDeletion(pegawai),
          child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _performDeletion(PegawaiModel pegawai) async {
    if (passAdminC.text.isEmpty) {
      Get.snackbar('Error', 'Password Admin tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception("Sesi Admin tidak valid.");

      // 1. Re-autentikasi Admin
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: passAdminC.text);
      await user.reauthenticateWithCredential(credential);

      // 2. Hapus dokumen dari Firestore
      await _firestore.collection('Sekolah').doc(configController.idSekolah).collection('pegawai').doc(pegawai.uid).delete();
      
      // 3. TODO: Hapus user dari Firebase Auth menggunakan Cloud Function
      // Untuk saat ini, user di Auth masih ada, tapi sudah tidak bisa login karena profilnya di Firestore tidak ada.

      Get.back(); // Tutup dialog loading
      Get.back(); // Tutup dialog konfirmasi
      passAdminC.clear();
      Get.snackbar('Berhasil', 'Data pegawai "${pegawai.nama}" telah dihapus.');
      fetchPegawai(); // Refresh daftar pegawai

    } on FirebaseAuthException catch (e) {
      Get.back();
      String message = 'Password Admin yang Anda masukkan salah.';
      if (e.code != 'wrong-password') message = 'Terjadi kesalahan otentikasi. Coba lagi.';
      Get.snackbar('Gagal', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back();
      Get.snackbar('Gagal', 'Terjadi kesalahan sistem: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // --- NAVIGASI ---
  void goToManajemenPeran() {
    Get.toNamed(Routes.MANAJEMEN_PERAN);
  }

  void goToTambahPegawai() async {
    final result = await Get.toNamed(Routes.UPSERT_PEGAWAI);
    // Jika kembali dari halaman tambah dengan sinyal sukses, refresh daftar.
    if (result == true) {
      fetchPegawai();
    }
  }

  void goToEditPegawai(PegawaiModel pegawai) async {
    final result = await Get.toNamed(Routes.UPSERT_PEGAWAI, arguments: pegawai);
    // Jika kembali dari halaman edit dengan sinyal sukses, refresh daftar.
    if (result == true) {
      fetchPegawai();
    }
  }
}