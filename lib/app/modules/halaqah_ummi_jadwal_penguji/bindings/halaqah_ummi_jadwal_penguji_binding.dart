import 'package:get/get.dart';

import '../controllers/halaqah_ummi_jadwal_penguji_controller.dart';

class HalaqahUmmiJadwalPengujiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiJadwalPengujiController>(
      () => HalaqahUmmiJadwalPengujiController(),
    );
  }
}
