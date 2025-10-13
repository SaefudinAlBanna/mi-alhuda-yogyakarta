import 'package:get/get.dart';

import '../controllers/rekap_jurnal_admin_controller.dart';

class RekapJurnalAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekapJurnalAdminController>(
      () => RekapJurnalAdminController(),
    );
  }
}
