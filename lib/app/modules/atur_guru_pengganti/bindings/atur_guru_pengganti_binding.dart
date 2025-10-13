import 'package:get/get.dart';

import '../controllers/atur_guru_pengganti_controller.dart';

class AturGuruPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AturGuruPenggantiController>(
      () => AturGuruPenggantiController(),
    );
  }
}
