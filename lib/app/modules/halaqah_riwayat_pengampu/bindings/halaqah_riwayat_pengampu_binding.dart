import 'package:get/get.dart';

import '../controllers/halaqah_riwayat_pengampu_controller.dart';

class HalaqahRiwayatPengampuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahRiwayatPengampuController>(
      () => HalaqahRiwayatPengampuController(),
    );
  }
}
