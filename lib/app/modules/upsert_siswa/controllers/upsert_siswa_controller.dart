// lib/app/modules/upsert_siswa/controllers/upsert_siswa_controller.dart (SEKOLAH - FINAL)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

class UpsertSiswaController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController namaC, nisnC, sppC, passAdminC;
  final isLoading = false.obs;

  SiswaModel? _siswaToEdit;
  bool get isEditMode => _siswaToEdit != null;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController(); nisnC = TextEditingController(); sppC = TextEditingController(); passAdminC = TextEditingController();
    if (Get.arguments != null && Get.arguments is SiswaModel) {
      _siswaToEdit = Get.arguments;
      namaC.text = _siswaToEdit!.namaLengkap;
      nisnC.text = _siswaToEdit!.nisn;
      sppC.text = _siswaToEdit!.spp?.toString() ?? '0';
    }
  }

  @override
  void onClose() {
    namaC.dispose(); nisnC.dispose(); sppC.dispose(); passAdminC.dispose();
    super.onClose();
  }

  void validasiDanProses() {
    if (!formKey.currentState!.validate()) return;
    if (isEditMode) {
      _prosesSimpanData();
    } else {
      Get.defaultDialog(
        title: 'Verifikasi Admin',
        content: TextField(controller: passAdminC, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Password Admin Anda')),
        actions: [
          OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(onPressed: _prosesSimpanData, child: const Text('Konfirmasi')),
        ],
      );
    }
  }

  Future<void> _prosesSimpanData() async {
    isLoading.value = true;
    final adminEmail = _auth.currentUser?.email;
    final adminPassword = passAdminC.text;

    configC.isCreatingNewUser.value = true;
    
    try {
      if (isEditMode) {
        final dataToUpdate = {'namaLengkap': namaC.text, 'spp': num.tryParse(sppC.text) ?? 0};
        await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(_siswaToEdit!.uid).update(dataToUpdate);
        Get.back(result: true); Get.snackbar('Berhasil', 'Data siswa berhasil diperbarui.');
      } else {
        if (adminEmail == null || adminPassword.isEmpty) throw Exception('Sesi admin tidak valid.');
        Get.back();

        await _auth.currentUser!.reauthenticateWithCredential(EmailAuthProvider.credential(email: adminEmail, password: adminPassword));
        final emailSiswa = "${nisnC.text}@mialhuda.com";
        UserCredential cred = await _auth.createUserWithEmailAndPassword(email: emailSiswa, password: 'alhuda');
        
        await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword); 

        final dataSiswa = {
          'namaLengkap': namaC.text, 'nisn': nisnC.text, 'spp': num.tryParse(sppC.text) ?? 0, 'email': emailSiswa,
          'isProfileComplete': false, 'mustChangePassword': true, 'statusSiswa': "Aktif",
          'createdAt': FieldValue.serverTimestamp(), 'createdBy': adminEmail, 'uid': cred.user!.uid,
          'kelasId': null,
        };
        await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(cred.user!.uid).set(dataSiswa);
        
        Get.back(result: true); Get.snackbar('Berhasil', 'Siswa baru berhasil ditambahkan.');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan.';
      if (e.code == 'wrong-password') msg = 'Password Admin salah.';
      if (e.code == 'email-already-in-use') msg = 'NISN ini sudah terdaftar.';
      Get.snackbar('Gagal', msg);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      passAdminC.clear();
      configC.isCreatingNewUser.value = false;
    }
  }
}