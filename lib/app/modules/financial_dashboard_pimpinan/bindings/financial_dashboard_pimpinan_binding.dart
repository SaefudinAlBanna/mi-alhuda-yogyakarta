import 'package:get/get.dart';

import '../controllers/financial_dashboard_pimpinan_controller.dart';

class FinancialDashboardPimpinanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinancialDashboardPimpinanController>(
      () => FinancialDashboardPimpinanController(),
    );
  }
}
