// lib/app/modules/home/controllers/home_controller.dart

import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class HomeController extends GetxController {
  // Tugas HomeController sekarang SANGAT sederhana
  final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}