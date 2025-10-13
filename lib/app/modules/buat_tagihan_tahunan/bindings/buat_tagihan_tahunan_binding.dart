import 'package:get/get.dart';

import '../controllers/buat_tagihan_tahunan_controller.dart';

class BuatTagihanTahunanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuatTagihanTahunanController>(
      () => BuatTagihanTahunanController(),
    );
  }
}
