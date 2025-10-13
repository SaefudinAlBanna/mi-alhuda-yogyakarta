import 'package:get/get.dart';

import '../controllers/input_nilai_massal_akademik_controller.dart';

class InputNilaiMassalAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputNilaiMassalAkademikController>(
      () => InputNilaiMassalAkademikController(),
    );
  }
}
