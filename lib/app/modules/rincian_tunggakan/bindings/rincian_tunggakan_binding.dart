import 'package:get/get.dart';

import '../controllers/rincian_tunggakan_controller.dart';

class RincianTunggakanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RincianTunggakanController>(
      () => RincianTunggakanController(),
    );
  }
}
