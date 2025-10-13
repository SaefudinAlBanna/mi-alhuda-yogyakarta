import 'package:get/get.dart';

import '../controllers/halaqah_dashboard_pengampu_controller.dart';

class HalaqahDashboardPengampuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahDashboardPengampuController>(
      () => HalaqahDashboardPengampuController(),
    );
  }
}
