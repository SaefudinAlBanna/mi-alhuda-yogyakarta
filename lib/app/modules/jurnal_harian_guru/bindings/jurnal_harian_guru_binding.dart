import 'package:get/get.dart';

import '../controllers/jurnal_harian_guru_controller.dart';

class JurnalHarianGuruBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JurnalHarianGuruController>(
      () => JurnalHarianGuruController(),
    );
  }
}
