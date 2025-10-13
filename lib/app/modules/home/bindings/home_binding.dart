import 'package:get/get.dart';

// Import controller yang baru kita buat

// import '../../../controllers/dashboard_controller.dart';
// import '../../profile/controllers/profile_controller.dart';
// import '../controllers/home_controller.dart';

import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut<HomeController>(
    //   () => HomeController(),
    // );

    // Get.lazyPut<DashboardController>(() => DashboardController());

    // // --- TAMBAHKAN BARIS INI ---
    // // Daftarkan ProfileController di sini agar siap digunakan oleh ProfileView di dalam HomeView.
    // Get.lazyPut<ProfileController>(
    //   () => ProfileController(),
    // );
    // ---------------------------
  }
}