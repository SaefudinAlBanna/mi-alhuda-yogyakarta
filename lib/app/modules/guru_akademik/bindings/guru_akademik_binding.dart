import 'package:get/get.dart';

import '../controllers/guru_akademik_controller.dart';

class GuruAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuruAkademikController>(
      () => GuruAkademikController(),
    );
  }
}
