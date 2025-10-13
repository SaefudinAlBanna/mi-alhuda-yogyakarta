// lib/app/modules/home/views/placeholder_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class PlaceholderView extends StatelessWidget {
  final String pageTitle;
  const PlaceholderView({Key? key, required this.pageTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kita tetap ambil ConfigController untuk akses ke 'infoUser'
    final configC = Get.find<ConfigController>();
    final authC = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          if (pageTitle == "Profil")
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authC.logout(),
            )
        ],
      ),
      body: Center(
        child: Obx(
          () {
            // Kita tidak perlu cek 'isProfileLoading' lagi, karena
            // kita hanya bisa sampai di sini jika status sudah 'authenticated'.
            
            // Ambil data 'tugas' dengan cara yang aman
            final List<dynamic> tugasList = configC.infoUser['tugas'] ?? [];
            final String tugasText = tugasList.isEmpty ? 'Tidak ada' : tugasList.join(', ');

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Agar Card tidak memenuhi layar
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Halaman: $pageTitle", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    Text("Nama: ${configC.infoUser['nama'] ?? '...'}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Role: ${configC.infoUser['role'] ?? '...'}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Tugas: $tugasText", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}