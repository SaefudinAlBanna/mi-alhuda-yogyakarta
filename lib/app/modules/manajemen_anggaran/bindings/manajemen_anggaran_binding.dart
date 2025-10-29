import 'package:get/get.dart';

import '../controllers/manajemen_anggaran_controller.dart';

class ManajemenAnggaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenAnggaranController>(
      () => ManajemenAnggaranController(),
    );
  }
}
