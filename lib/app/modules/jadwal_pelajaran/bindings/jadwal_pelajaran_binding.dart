import 'package:get/get.dart';

import '../controllers/jadwal_pelajaran_controller.dart';

class JadwalPelajaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JadwalPelajaranController>(
      () => JadwalPelajaranController(),
    );
  }
}
