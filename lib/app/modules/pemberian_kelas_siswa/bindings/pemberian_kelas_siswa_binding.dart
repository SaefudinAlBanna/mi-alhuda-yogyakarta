import 'package:get/get.dart';

import '../controllers/pemberian_kelas_siswa_controller.dart';

class PemberianKelasSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PemberianKelasSiswaController>(
      () => PemberianKelasSiswaController(),
    );
  }
}
