import 'package:get/get.dart';

import '../controllers/manajemen_kalender_akademik_controller.dart';

class ManajemenKalenderAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenKalenderAkademikController>(
      () => ManajemenKalenderAkademikController(),
    );
  }
}
