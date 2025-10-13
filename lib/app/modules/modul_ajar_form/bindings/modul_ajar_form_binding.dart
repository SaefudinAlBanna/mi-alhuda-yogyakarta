import 'package:get/get.dart';

import '../controllers/modul_ajar_form_controller.dart';

class ModulAjarFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModulAjarFormController>(
      () => ModulAjarFormController(),
    );
  }
}
