import 'package:get/get.dart';

import '../controllers/laporan_halaqah_controller.dart';

class LaporanHalaqahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanHalaqahController>(
      () => LaporanHalaqahController(),
    );
  }
}
