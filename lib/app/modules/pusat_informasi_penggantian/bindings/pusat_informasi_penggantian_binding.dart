import 'package:get/get.dart';

import '../controllers/pusat_informasi_penggantian_controller.dart';

class PusatInformasiPenggantianBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PusatInformasiPenggantianController>(
      () => PusatInformasiPenggantianController(),
    );
  }
}
