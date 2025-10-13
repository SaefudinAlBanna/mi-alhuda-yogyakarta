import 'package:get/get.dart';

import '../controllers/create_edit_halaqah_ummi_group_controller.dart';

class CreateEditHalaqahUmmiGroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateEditHalaqahUmmiGroupController>(
      () => CreateEditHalaqahUmmiGroupController(),
    );
  }
}
