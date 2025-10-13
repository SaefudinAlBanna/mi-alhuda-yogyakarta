// lib/app/modules/upsert_pegawai/bindings/upsert_pegawai_binding.dart

import 'package:get/get.dart';
import '../controllers/upsert_pegawai_controller.dart';

class UpsertPegawaiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpsertPegawaiController>(
      () => UpsertPegawaiController(),
    );
  }
}