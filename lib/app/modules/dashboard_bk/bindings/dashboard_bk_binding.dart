import 'package:get/get.dart';

import '../controllers/dashboard_bk_controller.dart';

class DashboardBkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardBkController>(
      () => DashboardBkController(),
    );
  }
}
