import 'package:get/get.dart';

import '../controllers/pengaturan_bobot_nilai_controller.dart';

class PengaturanBobotNilaiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PengaturanBobotNilaiController>(
      () => PengaturanBobotNilaiController(),
    );
  }
}
