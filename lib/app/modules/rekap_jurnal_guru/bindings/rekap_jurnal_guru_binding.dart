import 'package:get/get.dart';

import '../controllers/rekap_jurnal_guru_controller.dart';

class RekapJurnalGuruBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekapJurnalGuruController>(
      () => RekapJurnalGuruController(),
    );
  }
}
