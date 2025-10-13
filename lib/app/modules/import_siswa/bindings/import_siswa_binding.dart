import 'package:get/get.dart';

import '../controllers/import_siswa_controller.dart';

class ImportSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImportSiswaController>(
      () => ImportSiswaController(),
    );
  }
}
