import 'package:get/get.dart';

import '../controllers/data_sarpras_controller.dart';

class DataSarprasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DataSarprasController>(
      () => DataSarprasController(),
    );
  }
}
