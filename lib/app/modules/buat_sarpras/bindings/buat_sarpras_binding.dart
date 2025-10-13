import 'package:get/get.dart';

import '../controllers/buat_sarpras_controller.dart';

class BuatSarprasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuatSarprasController>(
      () => BuatSarprasController(),
    );
  }
}
