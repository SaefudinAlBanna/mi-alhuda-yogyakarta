import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/modules/atur_guru_pengganti/controllers/atur_guru_pengganti_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/modules/atur_penggantian_rentang/controllers/atur_penggantian_rentang_controller.dart';
import '../controllers/atur_penggantian_host_controller.dart';

class AturPenggantianHostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AturPenggantianHostController>(() => AturPenggantianHostController());
    Get.lazyPut<AturGuruPenggantiController>(() => AturGuruPenggantiController());
    Get.lazyPut<AturPenggantianRentangController>(() => AturPenggantianRentangController());
  }
}