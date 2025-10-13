import 'package:get/get.dart';

import '../controllers/laporan_perubahan_up_controller.dart';

class LaporanPerubahanUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanPerubahanUpController>(
      () => LaporanPerubahanUpController(),
    );
  }
}
