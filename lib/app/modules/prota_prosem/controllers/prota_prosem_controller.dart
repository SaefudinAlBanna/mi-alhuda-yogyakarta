import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/atp_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/perangkat_ajar/controllers/perangkat_ajar_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/services/pdf_export_service.dart'; // Akan kita gunakan nanti

class ProtaProsemController extends GetxController {
  final PerangkatAjarController _perangkatAjarC = Get.find<PerangkatAjarController>();

  // State
  late final Rx<AtpModel> atp;
  final List<String> bulanSemester1 = ["Juli", "Agustus", "September", "Oktober", "November", "Desember"];
  final List<String> bulanSemester2 = ["Januari", "Februari", "Maret", "April", "Mei", "Juni"];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is AtpModel) {
      atp = (Get.arguments as AtpModel).obs;
    } else {
      Get.back();
      Get.snackbar("Error", "Data ATP tidak valid.");
    }
  }

  Future<void> jadwalkanUnit({required String idUnit, required int semester, required String bulan}) async {
    int unitIndex = atp.value.unitPembelajaran.indexWhere((unit) => unit.idUnit == idUnit);
    if (unitIndex != -1) {
      atp.value.unitPembelajaran[unitIndex].semester = semester;
      atp.value.unitPembelajaran[unitIndex].bulan = bulan;
      await _perangkatAjarC.updateAtp(atp.value); // Gunakan fungsi update yang sudah ada
      atp.refresh(); // Paksa UI untuk rebuild
      Get.snackbar("Berhasil", "'${atp.value.unitPembelajaran[unitIndex].lingkupMateri}' berhasil dijadwalkan.");
    }
  }

  Future<void> batalkanJadwalUnit({required String idUnit}) async {
    int unitIndex = atp.value.unitPembelajaran.indexWhere((unit) => unit.idUnit == idUnit);
    if (unitIndex != -1) {
      atp.value.unitPembelajaran[unitIndex].semester = null;
      atp.value.unitPembelajaran[unitIndex].bulan = null;
      await _perangkatAjarC.updateAtp(atp.value);
      atp.refresh();
      Get.snackbar("Berhasil", "Jadwal untuk '${atp.value.unitPembelajaran[unitIndex].lingkupMateri}' telah dibatalkan.");
    }
  }
  
  void cetakProtaProsem() {
    Get.snackbar("Info", "Fitur Cetak PDF akan segera diimplementasikan.");
    // Logika pemanggilan PdfExportService akan ada di sini
  }
}