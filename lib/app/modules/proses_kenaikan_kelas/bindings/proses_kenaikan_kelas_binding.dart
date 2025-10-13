import 'package:get/get.dart';

import '../controllers/proses_kenaikan_kelas_controller.dart';

class ProsesKenaikanKelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProsesKenaikanKelasController>(
      () => ProsesKenaikanKelasController(),
    );
  }
}
