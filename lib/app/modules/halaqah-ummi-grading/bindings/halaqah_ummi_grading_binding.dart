import 'package:get/get.dart';

import '../controllers/halaqah_ummi_grading_controller.dart';

class HalaqahUmmiGradingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiGradingController>(
      () => HalaqahUmmiGradingController(),
    );
  }
}
