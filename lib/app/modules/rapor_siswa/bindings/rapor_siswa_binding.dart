import 'package:get/get.dart';

import '../controllers/rapor_siswa_controller.dart';

class RaporSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RaporSiswaController>(
      () => RaporSiswaController(),
    );
  }
}
