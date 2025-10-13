import 'package:get/get.dart';

import '../controllers/atur_penggantian_rentang_controller.dart';

class AturPenggantianRentangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AturPenggantianRentangController>(
      () => AturPenggantianRentangController(),
    );
  }
}
