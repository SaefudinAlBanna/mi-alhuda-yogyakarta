import 'package:get/get.dart';

import '../controllers/create_edit_halaqah_group_controller.dart';

class CreateEditHalaqahGroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateEditHalaqahGroupController>(
      () => CreateEditHalaqahGroupController(),
    );
  }
}
