import 'package:get/get.dart';

import '../controllers/halaqah_management_controller.dart';

class HalaqahManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahManagementController>(
      () => HalaqahManagementController(),
    );
  }
}
