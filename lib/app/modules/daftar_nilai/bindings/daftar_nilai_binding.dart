import 'package:get/get.dart';

import '../controllers/daftar_nilai_controller.dart';

class DaftarNilaiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarNilaiController>(
      () => DaftarNilaiController(),
    );
  }
}
