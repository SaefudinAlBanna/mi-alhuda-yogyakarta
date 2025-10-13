import 'package:get/get.dart';

import '../controllers/editor_jadwal_controller.dart';

class EditorJadwalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditorJadwalController>(
      () => EditorJadwalController(),
    );
  }
}
