import 'package:get/get.dart';

import '../controllers/laporan_keuangan_sekolah_controller.dart';

class LaporanKeuanganSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanKeuanganSekolahController>(
      () => LaporanKeuanganSekolahController(),
    );
  }
}
