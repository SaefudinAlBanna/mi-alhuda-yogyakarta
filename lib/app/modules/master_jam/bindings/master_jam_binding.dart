import 'package:get/get.dart';

import '../controllers/master_jam_controller.dart';

class MasterJamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterJamController>(
      () => MasterJamController(),
    );
  }
}
