import 'package:get/get.dart';

import '../controllers/halaqah_ummi_management_controller.dart';

class HalaqahUmmiManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiManagementController>(
      () => HalaqahUmmiManagementController(),
    );
  }
}
