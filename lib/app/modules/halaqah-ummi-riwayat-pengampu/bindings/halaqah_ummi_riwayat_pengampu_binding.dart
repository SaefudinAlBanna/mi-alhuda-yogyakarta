import 'package:get/get.dart';

import '../controllers/halaqah_ummi_riwayat_pengampu_controller.dart';

class HalaqahUmmiRiwayatPengampuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiRiwayatPengampuController>(
      () => HalaqahUmmiRiwayatPengampuController(),
    );
  }
}
