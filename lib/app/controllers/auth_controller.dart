// lib/app/controllers/auth_controller.dart (Aplikasi SEKOLAH)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/home/controllers/home_controller.dart';
import '../modules/login/controllers/login_controller.dart';
import '../routes/app_pages.dart';
import 'config_controller.dart';
import 'dashboard_controller.dart';

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  late final Stream<User?> authStateChanges;
  final Rxn<User> _firebaseUser = Rxn<User>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    authStateChanges = auth.authStateChanges();
    _firebaseUser.bindStream(authStateChanges);
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan.";
      if (e.code == 'user-not-found') {
        errorMessage = "Email tidak terdaftar.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Password yang Anda masukkan salah.";
      } else {
        errorMessage = "Gagal login. Periksa kembali email dan password Anda.";
      }
      Get.snackbar("Gagal Login",errorMessage, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error","Terjadi kesalahan yang tidak diketahui.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().cancelDashboardStreams();
      }
      if (Get.isRegistered<LoginController>()) {
        Get.delete<LoginController>(force: true);
      }
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().cancelDashboardStreams();
      }
      if (Get.isRegistered<ConfigController>()) {
        final configC = Get.find<ConfigController>();
        await configC.clearUserConfig();
      }
      
      await auth.signOut();
      
      Get.offAllNamed(Routes.ROOT);

    } catch (e) {
      Get.snackbar("Error", "Gagal untuk logout: ${e.toString()}", snackPosition: SnackPosition.BOTTOM);
      Get.offAllNamed(Routes.ROOT);
    } finally {
      isLoading.value = false;
    }
  }
}