import 'package:get/get.dart';

import '../controllers/create_edit_buku_controller.dart';

class CreateEditBukuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateEditBukuController>(
      () => CreateEditBukuController(),
    );
  }
}
