import 'package:get/get.dart';

import '../controllers/manajemen_dashboard_controller.dart';

class ManajemenDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenDashboardController>(
      () => ManajemenDashboardController(),
    );
  }
}
