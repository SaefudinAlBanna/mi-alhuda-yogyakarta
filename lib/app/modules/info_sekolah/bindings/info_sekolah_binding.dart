// lib/app/modules/info_sekolah/bindings/info_sekolah_binding.dart (SATU-SATUNYA BINDING YANG DIPERLUKAN)

import 'package:get/get.dart';
import '../controllers/info_sekolah_controller.dart';

class InfoSekolahBinding extends Bindings {
  @override
  void dependencies() {
    // Tugas binding ini HANYA untuk membuat controller.
    // 'fenix: true' memastikan kita mendapat controller baru yang bersih
    // setiap kali kita masuk ke fitur Info Sekolah dari dasbor.
    Get.lazyPut<InfoSekolahController>(() => InfoSekolahController(), fenix: true);
  }
}