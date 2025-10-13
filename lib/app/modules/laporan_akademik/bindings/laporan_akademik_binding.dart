import 'package:get/get.dart';

import '../controllers/laporan_akademik_controller.dart';

class LaporanAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanAkademikController>(
      () => LaporanAkademikController(),
    );
  }
}
