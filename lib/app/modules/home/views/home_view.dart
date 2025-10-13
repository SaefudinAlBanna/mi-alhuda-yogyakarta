import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../../marketplace/views/marketplace_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/home_controller.dart';
import '../pages/dashboard_page.dart';
import '../pages/palace_holder.dart'; // Jika Anda masih menggunakan ini

// --- [PERBAIKAN #1] Ubah dari GetView menjadi StatelessWidget ---
class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  List<Widget> _buildScreens() {
    return [
      const DashboardView(),
      const MarketplaceView(), // Ganti ini jika sudah ada
      const ProfileView(),
    ];
  }

  List<PersistentBottomNavBarItem> _buildNavBarsItems() {
    return [
      PersistentBottomNavBarItem(
          icon: const Icon(Icons.dashboard_rounded), title: ("Dashboard"), activeColorPrimary: Colors.indigo, inactiveColorPrimary: Colors.grey),
      PersistentBottomNavBarItem(
          // Gunakan ikon yang lebih relevan
          icon: const Icon(Icons.storefront_rounded), 
          title: ("Marketplace"), // Sesuaikan judul
          activeColorPrimary: Colors.indigo, inactiveColorPrimary: Colors.grey),
      PersistentBottomNavBarItem(
          icon: const Icon(Icons.person_rounded), title: ("Profil"), activeColorPrimary: Colors.indigo, inactiveColorPrimary: Colors.grey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // --- [PERBAIKAN #2] Inisialisasi controller di sini ---
    // Ini memastikan HomeController yang baru dan segar dibuat setiap kali HomeView ditampilkan.
    final HomeController controller = Get.put(HomeController());

    return WillPopScope(
      onWillPop: () async {
        _showExitDialog(context);
        return false;
      },
      child: PersistentTabView(
        context,
        controller: controller.tabController,
        screens: _buildScreens(),
        items: _buildNavBarsItems(),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        navBarStyle: NavBarStyle.style1,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(10.0),
          colorBehindNavBar: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            )
          ]
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tidak')),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}