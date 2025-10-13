import 'package:get/get.dart';

import '../controllers/absensi_wali_kelas_controller.dart';

class AbsensiWaliKelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AbsensiWaliKelasController>(
      () => AbsensiWaliKelasController(),
    );
  }
}
