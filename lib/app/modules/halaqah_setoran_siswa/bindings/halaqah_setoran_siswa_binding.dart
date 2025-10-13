import 'package:get/get.dart';

import '../controllers/halaqah_setoran_siswa_controller.dart';

class HalaqahSetoranSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahSetoranSiswaController>(
      () => HalaqahSetoranSiswaController(),
    );
  }
}
