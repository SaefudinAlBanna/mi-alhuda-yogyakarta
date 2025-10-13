import 'dart:async'; // Pastikan ini diimpor
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/auth_controller.dart'; // Tambahkan ini
import '../../../controllers/config_controller.dart';
import '../../../routes/app_pages.dart';

class RootController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>(); // Dapatkan AuthController
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    print("🚀 [RootController] onInit called."); // Debugging
  }

  @override
  void onReady() {
    super.onReady();
    print("✨ [RootController] onReady called. Initiating routing decision."); // Debugging
    _decideInitialRoute();
  }

  Future<void> _decideInitialRoute() async {
    print("🧐 [RootController] Checking onboarding status from GetStorage."); // Debugging
    final bool hasSeenSchoolOnboarding = _box.read('hasSeenSchoolOnboarding') ?? false;
    print("✅ [RootController] hasSeenSchoolOnboarding: $hasSeenSchoolOnboarding"); // Debugging

    if (!hasSeenSchoolOnboarding) {
      print("➡️ [RootController] Navigating to ONBOARDING_SCHOOL as it has not been seen."); // Debugging
      Get.offAllNamed(Routes.ONBOARDING_SCHOOL);
    } else {
      print("➡️ [RootController] Onboarding already seen. Determining main app route."); // Debugging
      String targetRoute = await _determineMainAppRoute();
      print("🎯 [RootController] Navigating to $targetRoute."); // Debugging
      Get.offAllNamed(targetRoute);
    }
  }

  Future<String> _determineMainAppRoute() async {
    print("🚦 [RootController] _determineMainAppRoute started. Initial configC status: ${configC.status.value}");

    // Pertama, pastikan ConfigController telah selesai memproses status auth awal.
    // Ini penting agar RootController bekerja dengan status yang paling mutakhir.
    if (configC.status.value == AppStatus.loading) {
      print("⏳ [RootController] ConfigController is loading. Waiting for stable status..."); // Debugging
      await configC.status.stream.firstWhere((status) => status != AppStatus.loading);
      print("✅ [RootController] ConfigController status stabilized to: ${configC.status.value}"); // Debugging
    }
    
    // Setelah ConfigController memiliki status dasar yang stabil,
    // Kita cek apakah statusnya 'authenticated' dan 'isUserDataReady' belum siap.
    if (configC.status.value == AppStatus.authenticated && !configC.isUserDataReady.value) {
      print("⏳ [RootController] Authenticated but user data not ready. Waiting for isUserDataReady OR unauthenticated status..."); // Debugging
      
      // [PERBAIKAN KRUSIAL]: Gunakan Future.any untuk menunggu dua kondisi secara bersamaan.
      // 1. isUserDataReady menjadi true (indikasi data siap)
      // 2. status berubah menjadi unauthenticated (indikasi logout atau error setelah auth)
      // 3. Tambahkan timeout untuk mencegah hang jika tidak ada event yang datang
      await Future.any([
        configC.isUserDataReady.stream.firstWhere((isReady) => isReady == true).then((_) => 'data_ready'),
        configC.status.stream.firstWhere((status) => status == AppStatus.unauthenticated).then((_) => 'unauthenticated_status'),
        Future.delayed(const Duration(seconds: 15)).then((_) => throw TimeoutException("RootController data read timeout.")),
      ]).then((result) {
        print("✅ [RootController] Async wait finished. Result: $result");
      }).catchError((e) {
        print("❌ [RootController] Error or timeout during waiting: $e. Re-evaluating status."); // Debugging
        // Jika terjadi timeout atau error lain, ConfigController seharusnya sudah menangani
        // dengan mengatur status ke AppStatus.unauthenticated (melalui logout internal jika ada error sync data).
        // Jadi, kita biarkan alur di bawah mengambil keputusan berdasarkan status yang sekarang.
      });
    }

    final finalStatus = configC.status.value; // Dapatkan status akhir yang paling stabil

    switch (finalStatus) {
      case AppStatus.unauthenticated:
        print("➡️ [RootController] Final status: Unauthenticated. Routing to LOGIN."); // Debugging
        return Routes.LOGIN;
      case AppStatus.needsNewPassword:
        print("➡️ [RootController] Final status: Needs New Password. Routing to NEW_PASSWORD."); // Debugging
        return Routes.NEW_PASSWORD;
      case AppStatus.authenticated:
        // Hanya pergi ke HOME jika benar-benar authenticated DAN data sudah siap
        if (configC.isUserDataReady.value) {
          print("➡️ [RootController] Final status: Authenticated and data ready. Routing to HOME."); // Debugging
          return Routes.HOME;
        } else {
          // Fallback ke login jika entah bagaimana authenticated tetapi data belum siap setelah menunggu.
          // Ini seharusnya tidak terjadi dengan logika Future.any di atas.
          print("⚠️ [RootController] Authenticated but data not ready after wait. Routing to LOGIN as fallback."); // Debugging
          return Routes.LOGIN;
        }
      default:
        print("⚠️ [RootController] Unexpected final status: $finalStatus. Routing to LOGIN as fallback."); // Debugging
        return Routes.LOGIN; // Fallback
    }
  }

  @override
  void onClose() {
    print("🗑️ [RootController] onClose called."); // Debugging
    super.onClose();
  }
}