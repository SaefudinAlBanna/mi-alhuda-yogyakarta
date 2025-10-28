import 'package:get/get.dart';

import '../controllers/manajemen_tunggakan_awal_controller.dart';

class ManajemenTunggakanAwalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenTunggakanAwalController>(
      () => ManajemenTunggakanAwalController(),
    );
  }
}
