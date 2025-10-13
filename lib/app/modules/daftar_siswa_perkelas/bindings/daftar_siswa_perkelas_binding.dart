import 'package:get/get.dart';

import '../controllers/daftar_siswa_perkelas_controller.dart';

class DaftarSiswaPerkelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarSiswaPerkelasController>(
      () => DaftarSiswaPerkelasController(),
    );
  }
}
