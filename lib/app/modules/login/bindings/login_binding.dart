// lib/app/modules/login/bindings/login_binding.dart (Aplikasi SEKOLAH)

import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // [PERBAIKAN] Gunakan lazyPut untuk LoginController agar dibuat saat dibutuhkan
    Get.lazyPut<LoginController>(
      () => LoginController(),
    );
  }
}