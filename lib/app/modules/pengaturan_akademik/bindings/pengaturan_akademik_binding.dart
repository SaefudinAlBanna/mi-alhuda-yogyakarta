import 'package:get/get.dart';

import '../controllers/pengaturan_akademik_controller.dart';

class PengaturanAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PengaturanAkademikController>(
      () => PengaturanAkademikController(),
    );
  }
}
