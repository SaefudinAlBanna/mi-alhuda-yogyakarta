import 'package:get/get.dart';

import '../controllers/pengaturan_biaya_controller.dart';

class PengaturanBiayaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PengaturanBiayaController>(
      () => PengaturanBiayaController(),
    );
  }
}
