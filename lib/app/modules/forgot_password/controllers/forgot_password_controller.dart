import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController emailC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> sendEmail() async {
    if (emailC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        await auth.sendPasswordResetEmail(email: emailC.text);
        Get.snackbar(
            snackPosition: SnackPosition.BOTTOM,
            'Berhasil',
            'Silhkan buka email, untuk reset password');
            Get.back();
      } catch (e) {
        Get.snackbar(
            snackPosition: SnackPosition.BOTTOM,
            'Peringatan',
            'Tidak bisa mengirim reset password ');
      } finally {
        isLoading.value = false;
      }
    } else {
      isLoading.value = false;
      Get.snackbar(
          snackPosition: SnackPosition.BOTTOM,
          'Peringatan',
          'email wajib diisi');
    }
  }
}
