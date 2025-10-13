// lib/app/modules/manajemen_peran/bindings/manajemen_peran_binding.dart

import 'package:get/get.dart';
import '../controllers/manajemen_peran_controller.dart';

class ManajemenPeranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenPeranController>(
      () => ManajemenPeranController(),
    );
  }
}