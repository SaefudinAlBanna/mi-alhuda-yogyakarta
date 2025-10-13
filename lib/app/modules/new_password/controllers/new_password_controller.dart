// lib/app/modules/new_password/controllers/new_password_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import '../../../routes/app_pages.dart';

class NewPasswordController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController _configController = Get.find<ConfigController>();

  final formKey = GlobalKey<FormState>();
  // --- TAMBAHKAN CONTROLLER UNTUK PASSWORD LAMA ---
  final oldPassC = TextEditingController(text: "alhuda"); // Kita bisa pre-fill jika mau
  // ---------------------------------------------
  final newPassC = TextEditingController();
  final confirmPassC = TextEditingController();
  
  final isLoading = false.obs;
  final isOldPassObscure = true.obs;
  final isNewPassObscure = true.obs;
  final isConfirmPassObscure = true.obs;

  @override
  void onClose() {
    oldPassC.dispose();
    newPassC.dispose();
    confirmPassC.dispose();
    super.onClose();
  }

  /// --- FUNGSI UTAMA YANG DIROMBAK TOTAL ---
  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    isLoading.value = true;
    try {
      User currentUser = _auth.currentUser!;
      String email = currentUser.email!;
      String oldPassword = oldPassC.text;
      String newPassword = newPassC.text;

      // 1. BUAT KREDENSIAL DENGAN EMAIL & PASSWORD LAMA
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      // 2. LAKUKAN RE-AUTENTIKASI
      await currentUser.reauthenticateWithCredential(credential);

      // 3. JIKA BERHASIL, BARU UPDATE PASSWORD
      // Langkah ini sekarang dijamin berhasil karena sesi sudah segar.
      await currentUser.updatePassword(newPassword);

      // 4. UPDATE FLAG DI FIRESTORE
      await _updatePasswordFlagInFirestore();

      // 5. LOGOUT DAN NAVIGASI
      await _auth.signOut();
      Get.offAllNamed(Routes.LOGIN);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        'Berhasil',
        'Password berhasil diubah. Silakan login kembali.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'wrong-password') {
        message = "Password lama yang Anda masukkan salah.";
      } else if (e.code == 'weak-password') {
        message = "Password baru terlalu lemah (minimal 6 karakter).";
      } else {
        message = "Terjadi kesalahan. Kode: ${e.code}";
      }
      Get.snackbar("Gagal", message, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
    } catch (e) {
      Get.snackbar('Error Kritis', 'Terjadi kesalahan tidak diketahui: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updatePasswordFlagInFirestore() async {
    final uid = _auth.currentUser!.uid;
    final idSekolah = _configController.idSekolah;
    final docRef = _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(uid);
    await docRef.set({'mustChangePassword': false}, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }
}