import 'package:get/get.dart';

import '../controllers/penugasan_guru_controller.dart';

class PenugasanGuruBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PenugasanGuruController>(
      () => PenugasanGuruController(),
    );
  }
}
