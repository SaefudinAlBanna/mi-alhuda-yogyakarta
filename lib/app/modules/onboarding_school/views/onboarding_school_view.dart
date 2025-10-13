// lib/app/modules/onboarding_school/views/onboarding_school_view.dart (Untuk Aplikasi SEKOLAH)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Jika ada SVG di masa depan

import '../../../models/onboarding_item_model.dart';
import '../controllers/onboarding_school_controller.dart'; // Import controller yang benar

class OnboardingSchoolView extends GetView<OnboardingSchoolController> { // Gunakan OnboardingSchoolController
  const OnboardingSchoolView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            itemCount: controller.onboardingItems.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              final item = controller.onboardingItems[index];
              return _OnboardingSchoolPage(item: item); // Gunakan _OnboardingSchoolPage
            },
          ),
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Row(
                  children: List.generate(
                    controller.onboardingItems.length,
                    (index) => _buildDot(index, controller.currentPageIndex.value),
                  ),
                )),
                Obx(() {
                  final isLastPage = controller.currentPageIndex.value == controller.onboardingItems.length - 1;
                  return Row(
                    children: [
                      if (!isLastPage)
                        TextButton(
                          onPressed: controller.onSkip,
                          child: const Text("Lewati", style: TextStyle(color: Colors.grey)),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.onNext,
                        child: Text(isLastPage ? "Mulai" : "Lanjutkan"),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, int currentPage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: 8.0,
      decoration: BoxDecoration(
        color: currentPage == index ? Get.theme.primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

// Widget Page untuk Onboarding Aplikasi Sekolah
class _OnboardingSchoolPage extends StatelessWidget {
  final OnboardingItemModel item;
  const _OnboardingSchoolPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50.0, left: 40.0, right: 40.0, bottom: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: item.isLottie
                ? Lottie.asset(item.imagePath, repeat: true, fit: BoxFit.contain)
                : SvgPicture.asset(item.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}