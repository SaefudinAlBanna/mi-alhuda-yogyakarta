import 'package:get/get.dart';

import '../controllers/laporan_jurnal_kelas_controller.dart';

class LaporanJurnalKelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanJurnalKelasController>(
      () => LaporanJurnalKelasController(),
    );
  }
}
