// lib/app/modules/info_sekolah_detail/bindings/info_sekolah_detail_binding.dart (FINAL & BENAR)

import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/modules/info_sekolah/controllers/info_sekolah_controller.dart';

class InfoSekolahDetailBinding extends Bindings {
  @override
  void dependencies() {
    // CUKUP PASTIKAN CONTROLLER-NYA ADA. TIDAK PERLU lazyPut.
    // GetX cukup pintar untuk menemukannya jika sudah di-put sebelumnya.
    // Baris Get.find() ini bahkan opsional, tetapi bagus untuk kejelasan.
    Get.find<InfoSekolahController>();
  }
}