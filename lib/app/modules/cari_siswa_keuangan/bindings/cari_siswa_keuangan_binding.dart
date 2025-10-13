import 'package:get/get.dart';

import '../controllers/cari_siswa_keuangan_controller.dart';

class CariSiswaKeuanganBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CariSiswaKeuanganController>(
      () => CariSiswaKeuanganController(),
    );
  }
}
