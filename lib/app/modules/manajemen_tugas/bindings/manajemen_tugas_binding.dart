import 'package:get/get.dart';

import '../controllers/manajemen_tugas_controller.dart';

class ManajemenTugasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenTugasController>(
      () => ManajemenTugasController(),
    );
  }
}
