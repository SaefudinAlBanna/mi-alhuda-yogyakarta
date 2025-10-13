import 'package:get/get.dart';

import '../controllers/kelompok_halaqoh_controller.dart';

class KelompokHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KelompokHalaqohController>(
      () => KelompokHalaqohController(),
    );
  }
}
