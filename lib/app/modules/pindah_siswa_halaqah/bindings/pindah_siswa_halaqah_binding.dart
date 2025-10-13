import 'package:get/get.dart';

import '../controllers/pindah_siswa_halaqah_controller.dart';

class PindahSiswaHalaqahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PindahSiswaHalaqahController>(
      () => PindahSiswaHalaqahController(),
    );
  }
}
