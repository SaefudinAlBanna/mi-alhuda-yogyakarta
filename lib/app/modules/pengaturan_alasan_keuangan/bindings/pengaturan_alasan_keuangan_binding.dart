import 'package:get/get.dart';

import '../controllers/pengaturan_alasan_keuangan_controller.dart';

class PengaturanAlasanKeuanganBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PengaturanAlasanKeuanganController>(
      () => PengaturanAlasanKeuanganController(),
    );
  }
}
