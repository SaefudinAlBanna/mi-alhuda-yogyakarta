import 'package:get/get.dart';

import '../controllers/halaqah_ummi_dashboard_koordinator_controller.dart';

class HalaqahUmmiDashboardKoordinatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiDashboardKoordinatorController>(
      () => HalaqahUmmiDashboardKoordinatorController(),
    );
  }
}
