import 'package:get/get.dart';

import '../controllers/master_mapel_controller.dart';

class MasterMapelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterMapelController>(
      () => MasterMapelController(),
    );
  }
}
