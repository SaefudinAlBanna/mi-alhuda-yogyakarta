import 'package:get/get.dart';

import '../controllers/halaqah_ummi_manajemen_penguji_controller.dart';

class HalaqahUmmiManajemenPengujiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiManajemenPengujiController>(
      () => HalaqahUmmiManajemenPengujiController(),
    );
  }
}
