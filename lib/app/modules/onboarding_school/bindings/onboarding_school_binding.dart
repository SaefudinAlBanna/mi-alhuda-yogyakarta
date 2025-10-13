// lib/app/modules/onboarding_school/bindings/onboarding_school_binding.dart (Untuk Aplikasi SEKOLAH)

import 'package:get/get.dart';

import '../controllers/onboarding_school_controller.dart';

class OnboardingSchoolBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingSchoolController>(
      () => OnboardingSchoolController(),
    );
  }
}