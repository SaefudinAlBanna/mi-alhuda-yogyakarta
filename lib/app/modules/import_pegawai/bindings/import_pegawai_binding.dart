import 'package:get/get.dart';

import '../controllers/import_pegawai_controller.dart';

class ImportPegawaiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImportPegawaiController>(
      () => ImportPegawaiController(),
    );
  }
}
