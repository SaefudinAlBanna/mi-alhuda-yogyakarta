import 'package:get/get.dart';

import '../controllers/prota_prosem_controller.dart';

class ProtaProsemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProtaProsemController>(
      () => ProtaProsemController(),
    );
  }
}
