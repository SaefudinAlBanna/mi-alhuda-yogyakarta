import 'package:get/get.dart';

import '../controllers/halaqah_ummi_grading_massal_controller.dart';

class HalaqahUmmiGradingMassalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiGradingMassalController>(
      () => HalaqahUmmiGradingMassalController(),
    );
  }
}
