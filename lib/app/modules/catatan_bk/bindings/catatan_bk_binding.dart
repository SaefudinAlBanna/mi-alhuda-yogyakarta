import 'package:get/get.dart';

import '../controllers/catatan_bk_controller.dart';

class CatatanBkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatatanBkController>(
      () => CatatanBkController(),
    );
  }
}
