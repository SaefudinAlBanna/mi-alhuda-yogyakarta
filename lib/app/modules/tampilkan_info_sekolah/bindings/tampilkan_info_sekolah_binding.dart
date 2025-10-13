import 'package:get/get.dart';

import '../controllers/tampilkan_info_sekolah_controller.dart';

class TampilkanInfoSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TampilkanInfoSekolahController>(
      () => TampilkanInfoSekolahController(),
    );
  }
}
