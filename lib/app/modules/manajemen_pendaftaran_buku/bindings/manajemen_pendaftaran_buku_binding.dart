import 'package:get/get.dart';

import '../controllers/manajemen_pendaftaran_buku_controller.dart';

class ManajemenPendaftaranBukuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenPendaftaranBukuController>(
      () => ManajemenPendaftaranBukuController(),
    );
  }
}
