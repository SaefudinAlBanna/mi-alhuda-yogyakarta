import 'package:get/get.dart';

import '../controllers/laporan_jurnal_pribadi_controller.dart';

class LaporanJurnalPribadiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanJurnalPribadiController>(
      () => LaporanJurnalPribadiController(),
    );
  }
}
