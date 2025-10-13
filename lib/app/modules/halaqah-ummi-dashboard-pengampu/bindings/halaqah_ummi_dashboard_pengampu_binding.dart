import 'package:get/get.dart';
import '../../halaqah-ummi-grading/controllers/halaqah_ummi_grading_controller.dart';
import '../controllers/halaqah_ummi_dashboard_pengampu_controller.dart';

class HalaqahUmmiDashboardPengampuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiDashboardPengampuController>(
      () => HalaqahUmmiDashboardPengampuController(),
    );
    // --- TAMBAHAN PENTING ---
    // Daftarkan GradingController di sini agar bisa diakses dari halaman riwayat
    Get.lazyPut<HalaqahUmmiGradingController>(
      () => HalaqahUmmiGradingController(),
    );
  }
}


// import 'package:get/get.dart';

// import '../controllers/halaqah_ummi_dashboard_pengampu_controller.dart';

// class HalaqahUmmiDashboardPengampuBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<HalaqahUmmiDashboardPengampuController>(
//       () => HalaqahUmmiDashboardPengampuController(),
//     );
//   }
// }
