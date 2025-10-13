import 'package:get/get.dart';

import '../controllers/atp_form_controller.dart';

class AtpFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AtpFormController>(
      () => AtpFormController(),
    );
  }
}
