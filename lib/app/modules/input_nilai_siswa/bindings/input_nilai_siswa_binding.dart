import 'package:get/get.dart';
import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaBinding extends Bindings {
  @override
  void dependencies() {
    // Tugas binding HANYA ini: mendaftarkan controller.
    // Jangan ada logika Get.arguments di sini.
    Get.lazyPut<InputNilaiSiswaController>(
      () => InputNilaiSiswaController(),
    );
  }
}