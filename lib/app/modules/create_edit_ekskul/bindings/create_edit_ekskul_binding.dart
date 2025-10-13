import 'package:get/get.dart';

import '../controllers/create_edit_ekskul_controller.dart';

class CreateEditEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateEditEkskulController>(
      () => CreateEditEkskulController(),
    );
  }
}
