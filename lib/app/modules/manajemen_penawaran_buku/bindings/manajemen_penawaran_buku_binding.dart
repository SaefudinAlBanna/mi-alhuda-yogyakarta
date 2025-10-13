import 'package:get/get.dart';

import '../controllers/manajemen_penawaran_buku_controller.dart';

class ManajemenPenawaranBukuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenPenawaranBukuController>(
      () => ManajemenPenawaranBukuController(),
    );
  }
}
