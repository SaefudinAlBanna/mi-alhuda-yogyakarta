import 'package:get/get.dart';

import '../controllers/pembayaran_spp_controller.dart';

class PembayaranSppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PembayaranSppController>(
      () => PembayaranSppController(),
    );
  }
}
