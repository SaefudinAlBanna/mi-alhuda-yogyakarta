import 'package:get/get.dart';

import '../controllers/upsert_siswa_controller.dart';

class UpsertSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpsertSiswaController>(
      () => UpsertSiswaController(),
    );
  }
}
