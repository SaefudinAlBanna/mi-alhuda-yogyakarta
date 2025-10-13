// lib/app/modules/onboarding_school/controllers/onboarding_school_controller.dart (Untuk Aplikasi SEKOLAH)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/onboarding_item_model.dart';
import '../../../routes/app_pages.dart';

class OnboardingSchoolController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final PageController pageController = PageController();
  final RxInt currentPageIndex = 0.obs;
  final GetStorage _box = GetStorage();

  late List<OnboardingItemModel> onboardingItems;

  @override
  void onInit() {
    super.onInit();
    _loadSchoolAppOnboardingItems();
  }

  void _loadSchoolAppOnboardingItems() {
    onboardingItems = [
      OnboardingItemModel(
        title: "Ahlan wa Sahlan, Ustadz/Ustadzah MI Al-Huda YOGYAKARTA!",
        description: "Aplikasi ini dirancang untuk memudahkan ustadz/ustadzah mengelola kegiatan akademik, data siswa, dan komunikasi di sekolah.",
        imagePath: "assets/lotties/1.json",
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Manajemen Akademik yang Cerdas",
        description: "Catat progres belajar siswa, pantau kehadiran, dan atur jadwal dengan fitur-fitur intuitif, efisien dan akurat.",
        imagePath: "assets/lotties/2.json",
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Komunikasi Terintegrasi",
        description: "Informasi Terpusat, Komunikasi Lancar. Sampaikan pengumuman penting, pantau kalender akademik, dan kirim notifikasi secara langsung kepada orang tua siswa.",
        imagePath: "assets/lotties/3.json",
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Siap Membangun Generasi Qur'ani?",
        description: "Optimalkan waktu ustadz/ustadzah untuk mendidik. Kami yang urus administrasi agar Anda bisa fokus pada pengembangan potensi siswa dan kemajuan sekolah.",
        imagePath: "assets/lotties/4.json",
        isLottie: true,
      ),
    ];
  }

  void onPageChanged(int index) {
    currentPageIndex.value = index;
  }

  void onNext() {
    if (currentPageIndex.value < onboardingItems.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      _finishOnboarding();
    }
  }

  void onSkip() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    print("🎉 [OnboardingSchoolController] Onboarding finished. Setting 'hasSeenSchoolOnboarding' to true.");
    await _box.write('hasSeenSchoolOnboarding', true);
    print("➡️ [OnboardingSchoolController] Navigating directly to LOGIN screen.");
    Get.offAllNamed(Routes.LOGIN); // <-- PERUBAHAN DI SINI: Langsung ke LOGIN
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}