// lib/app/modules/login/controllers/login_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final ConfigController configController = Get.find<ConfigController>();

  late GlobalKey<FormState> formKey;

  final RxBool isPasswordHidden = true.obs;
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  StreamSubscription? _authNavSubscription;

  @override
  void onInit() {
    super.onInit();
    formKey = GlobalKey<FormState>();

    _authNavSubscription = configController.isUserDataReady.listen((isReady) {
      print("🔍 [LoginController] ConfigController isUserDataReady changed to: $isReady");
      final currentStatus = configController.status.value;
      print("🔍 [LoginController] Current ConfigController status: $currentStatus");

      if (isReady && currentStatus == AppStatus.authenticated) {
        print("🚀 [LoginController] Authenticated and data ready. Navigating to HOME.");
        _authNavSubscription?.cancel();
        // [PERBAIKAN KRUSIAL] Tunda navigasi hingga setelah frame saat ini
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.HOME);
        });
      } else if (currentStatus == AppStatus.needsNewPassword) {
        print("⚠️ [LoginController] Needs new password. Navigating to NEW_PASSWORD.");
        _authNavSubscription?.cancel();
        // [PERBAIKAN KRUSIAL] Tunda navigasi hingga setelah frame saat ini
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.NEW_PASSWORD);
        });
      }
    });

    // Tambahan: Pastikan juga untuk menangani kasus `needsNewPassword` secara langsung
    ever(configController.status, (AppStatus status) {
      if (status == AppStatus.needsNewPassword) {
        print("⚠️ [LoginController] ConfigController status changed to needsNewPassword. Navigating to NEW_PASSWORD.");
        _authNavSubscription?.cancel(); 
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.NEW_PASSWORD);
        });
      }
      // Tambahkan penanganan untuk AppStatus.unauthenticated jika perlu,
      // tetapi biasanya cukup ditangani oleh RootController saat login gagal.
      if (status == AppStatus.unauthenticated) {
        print("⚠️ [LoginController] ConfigController status changed to unauthenticated. Remaining on login screen or showing error.");
        // Opsi: tampilkan snackbar jika ada error autentikasi yang tidak tertangkap oleh AuthController
        // if (authController.lastLoginError.value != null && authController.lastLoginError.value!.isNotEmpty) {
        //   Get.snackbar("Gagal Login", authController.lastLoginError.value!, snackPosition: SnackPosition.BOTTOM);
        //   authController.lastLoginError.value = null; // Clear error
        // }
      }
    });
  }

  void login() async {
    if (formKey.currentState!.validate()) {
      print("🎯 [LoginController] Attempting to login...");
      // Panggil metode login di AuthController
      await authController.login(emailC.text, passC.text);
      print("✅ [LoginController] authController.login() completed. Waiting for ConfigController status update.");
      // Jika authController.login() gagal (misalnya kredensial salah) dan tidak melempar,
      // maka _authController.authStateChanges tidak akan terpicu dan ConfigController.status tetap unauthenticated.
      // Dalam kasus ini, listener di LoginController tidak akan menavigasi.
      // AuthController.login sudah memiliki snackbar error, jadi tidak perlu lagi di sini.
    } else {
      Get.snackbar(
        "Input Tidak Valid",
        "Mohon periksa kembali data yang Anda masukkan.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (value.length < 6) {
      return 'Password minimal harus 6 karakter.';
    }
    return null;
  }

  @override
  void onClose() {
    print("🗑️ [LoginController] onClose called. Cancelling auth navigation subscription.");
    _authNavSubscription?.cancel();
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }
}