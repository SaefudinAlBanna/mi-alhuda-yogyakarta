import 'package:get/get.dart';

import '../controllers/manajemen_komite_controller.dart';

class ManajemenKomiteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenKomiteController>(
      () => ManajemenKomiteController(),
    );
  }
}
