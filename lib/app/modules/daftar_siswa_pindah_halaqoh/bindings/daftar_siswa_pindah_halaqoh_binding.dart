import 'package:get/get.dart';

import '../controllers/daftar_siswa_pindah_halaqoh_controller.dart';

class DaftarSiswaPindahHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarSiswaPindahHalaqohController>(
      () => DaftarSiswaPindahHalaqohController(),
    );
  }
}
