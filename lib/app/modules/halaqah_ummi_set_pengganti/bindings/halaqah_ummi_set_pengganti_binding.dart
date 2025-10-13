import 'package:get/get.dart';

import '../controllers/halaqah_ummi_set_pengganti_controller.dart';

class HalaqahUmmiSetPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiSetPenggantiController>(
      () => HalaqahUmmiSetPenggantiController(),
    );
  }
}
