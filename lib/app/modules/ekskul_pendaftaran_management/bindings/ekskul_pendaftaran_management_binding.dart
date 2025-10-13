import 'package:get/get.dart';

import '../controllers/ekskul_pendaftaran_management_controller.dart';

class EkskulPendaftaranManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EkskulPendaftaranManagementController>(
      () => EkskulPendaftaranManagementController(),
    );
  }
}
