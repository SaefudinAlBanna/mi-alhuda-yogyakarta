import 'package:get/get.dart';

import '../controllers/halaqah_set_pengganti_controller.dart';

class HalaqahSetPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahSetPenggantiController>(
      () => HalaqahSetPenggantiController(),
    );
  }
}
