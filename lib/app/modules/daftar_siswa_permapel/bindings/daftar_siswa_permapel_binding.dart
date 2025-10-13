import 'package:get/get.dart';

import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarSiswaPermapelController>(
      () => DaftarSiswaPermapelController(),
    );
  }
}
