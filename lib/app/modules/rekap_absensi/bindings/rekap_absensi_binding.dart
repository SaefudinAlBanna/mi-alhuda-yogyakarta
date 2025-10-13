import 'package:get/get.dart';

import '../controllers/rekap_absensi_controller.dart';

class RekapAbsensiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekapAbsensiController>(
      () => RekapAbsensiController(),
    );
  }
}
