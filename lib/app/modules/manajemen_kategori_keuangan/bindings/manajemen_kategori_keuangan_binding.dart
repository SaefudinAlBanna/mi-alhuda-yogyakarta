import 'package:get/get.dart';

import '../controllers/manajemen_kategori_keuangan_controller.dart';

class ManajemenKategoriKeuanganBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenKategoriKeuanganController>(
      () => ManajemenKategoriKeuanganController(),
    );
  }
}
