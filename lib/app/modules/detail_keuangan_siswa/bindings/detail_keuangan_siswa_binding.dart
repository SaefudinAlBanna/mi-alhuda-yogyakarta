import 'package:get/get.dart';

import '../controllers/detail_keuangan_siswa_controller.dart';

class DetailKeuanganSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailKeuanganSiswaController>(
      () => DetailKeuanganSiswaController(),
    );
  }
}
