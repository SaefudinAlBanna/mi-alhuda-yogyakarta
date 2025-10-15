// lib/app/modules/home/views/placeholder_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/auth_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';

class ProfilePage extends StatelessWidget {
  final String pageTitle;
  const ProfilePage({Key? key, required this.pageTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kita bisa akses controller servis dari mana saja.
    // final configC = Get.find<ConfigController>();
    // final authC = Get.find<AuthController>();

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(pageTitle),
      //   actions: [
      //     // Contoh tombol logout di halaman profil
      //     if (pageTitle == "Profil")
      //       IconButton(
      //         icon: const Icon(Icons.logout),
      //         onPressed: () => authC.logout(),
      //       )
      //   ],
      // ),
      // body: Center(
      //   child: Obx(
      //     () => Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         const Text(
      //           "Selamat Datang di Halaman",
      //           style: TextStyle(fontSize: 18),
      //         ),
      //         Text(
      //           pageTitle,
      //           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      //         ),
      //         const SizedBox(height: 40),
      //         if (configC.isProfileLoading.value)
      //           const CircularProgressIndicator()
      //         else
      //           Card(
      //             margin: const EdgeInsets.all(16),
      //             child: Padding(
      //               padding: const EdgeInsets.all(16.0),
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text("Nama: ${configC.infoUser['nama'] ?? 'Memuat...'}", style: const TextStyle(fontSize: 16)),
      //                   const SizedBox(height: 8),
      //                   Text("Role: ${configC.userRole.value ?? 'Tidak ada'}", style: const TextStyle(fontSize: 16)),
      //                   const SizedBox(height: 8),
      //                   Text("Tugas: ${configC.userTugas.isEmpty ? 'Tidak ada' : configC.userTugas.join(', ')}", style: const TextStyle(fontSize: 16)),
      //                 ],
      //               ),
      //             ),
      //           ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}

// // lib/app/modules/home/pages/profile_page.dart

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/home_controller.dart';
// import 'package:intl/intl.dart';

// class ProfilePage extends GetView<HomeController> {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
// //       backgroundColor: Colors.grey.shade100,
// //       appBar: AppBar(
// //         title: const Text("Profil Saya"),
// //         centerTitle: true,
// //         actions: [
// //           IconButton(
// //             onPressed: () => Get.defaultDialog(
// //               title: "Logout",
// //               middleText: "Apakah Anda yakin ingin keluar?",
// //               textConfirm: "Ya",
// //               textCancel: "Tidak",
// //               onConfirm: controller.signOut, // Asumsi ada fungsi signOut
// //             ),
// //             icon: const Icon(Icons.logout),
// //           ),
// //         ],
// //       ),
// //       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
// //         stream: controller.userStream(), // Menggunakan stream yang sudah diperbaiki
// //         builder: (context, snapProfile) {
// //           if (snapProfile.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //           if (!snapProfile.hasData || snapProfile.data?.data() == null) {
// //             return const Center(child: Text('Data pengguna tidak ditemukan.'));
// //           }
// //           final data = snapProfile.data!.data()!;
// //           return ListView(
// //             padding: const EdgeInsets.symmetric(vertical: 8.0),
// //             children: [
// //               _ProfileHeaderCard(data: data),
// //               const SizedBox(height: 16),
// //               _ProfileDetailsCard(data: data),
// //             ],
// //           );
// //         },
// //       ),
//     );
//   }
// }

// // class _ProfileHeaderCard extends GetView<HomeController> { // <-- Ubah menjadi GetView<HomeController>
// //   final Map<String, dynamic> data;
// //   const _ProfileHeaderCard({required this.data});

// //   @override
// //   Widget build(BuildContext context) {
// //     // --- LOGIKA BARU UNTUK MENAMPILKAN GAMBAR ---
// //     final String? imageUrl = data['profileImageUrl'];
// //     final ImageProvider imageProvider;

// //     if (imageUrl != null && imageUrl.isNotEmpty) {
// //       // Jika ada URL dari Firestore, gunakan NetworkImage
// //       imageProvider = NetworkImage(imageUrl);
// //     } else {
// //       // Jika tidak ada, gunakan default (misal, dari ui-avatars atau aset lokal)
// //       imageProvider = NetworkImage("https://ui-avatars.com/api/?name=${data['alias'] ?? 'User'}&background=random&color=fff");
// //     }
// //     // --- AKHIR LOGIKA BARU ---

// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(vertical: 24.0),
// //       margin: const EdgeInsets.symmetric(horizontal: 16.0),
// //       decoration: BoxDecoration(
// //         color: Colors.green.shade700,
// //         borderRadius: BorderRadius.circular(15),
// //         image: const DecorationImage(
// //           image: AssetImage("assets/webp/profile.webp"), // Pastikan path aset ini benar
// //           fit: BoxFit.cover,
// //           opacity: 0.1,
// //         ),
// //       ),
// //       child: Column(
// //         children: [
// //           Stack(
// //             children: [
// //               CircleAvatar(
// //                 radius: 52,
// //                 backgroundColor: Colors.white,
// //                 child: CircleAvatar(
// //                   radius: 50,
// //                   backgroundImage: imageProvider, // <-- Gunakan imageProvider
// //                 ),
// //               ),
// //               Positioned(
// //                 bottom: 0,
// //                 right: 0,
// //                 child: CircleAvatar(
// //                   radius: 20,
// //                   backgroundColor: Colors.white,
// //                   child: IconButton(
// //                     icon: Icon(Icons.edit, size: 22, color: Colors.green.shade800),
// //                     // Panggil fungsi upload dari controller
// //                     onPressed: controller.pickAndUploadProfilePicture,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Text(data['alias'] ?? 'Nama Pengguna', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
// //           const SizedBox(height: 4),
// //           Text(data['role'] ?? 'Role', style: const TextStyle(fontSize: 14, color: Colors.white70)),
// //         ],
// //       ),
// //     );
// //   }
// // }
