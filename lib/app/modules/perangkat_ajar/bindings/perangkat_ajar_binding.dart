import 'package:get/get.dart';

import '../controllers/perangkat_ajar_controller.dart';

class PerangkatAjarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PerangkatAjarController>(
      () => PerangkatAjarController(),
    );
  }
}
