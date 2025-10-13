import 'package:get/get.dart';

import '../controllers/master_ekskul_management_controller.dart';

class MasterEkskulManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterEkskulManagementController>(
      () => MasterEkskulManagementController(),
    );
  }
}
