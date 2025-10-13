import 'package:get/get.dart';

import '../controllers/halaqah_grading_controller.dart';

class HalaqahGradingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahGradingController>(
      () => HalaqahGradingController(),
    );
  }
}
