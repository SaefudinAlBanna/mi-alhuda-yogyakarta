import 'package:get/get.dart';

import '../controllers/laporan_komite_pimpinan_controller.dart';

class LaporanKomitePimpinanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanKomitePimpinanController>(
      () => LaporanKomitePimpinanController(),
    );
  }
}
