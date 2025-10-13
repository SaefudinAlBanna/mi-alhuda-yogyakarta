// lib/app/modules/info_sekolah_form/bindings/info_sekolah_form_binding.dart (FINAL & BENAR)

import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/info_sekolah/controllers/info_sekolah_controller.dart';

class InfoSekolahFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<InfoSekolahController>();
  }
}