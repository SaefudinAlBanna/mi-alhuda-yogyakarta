// lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  const DaftarSiswaPermapelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(controller.namaMapel, style: const TextStyle(fontSize: 18)),
            Text(controller.idKelas, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        actions: [
          // [PERBAIKAN UI/UX] Ganti PopupMenu dengan IconButton yang lebih jelas
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: "Manajemen Tugas & Penilaian",
            onPressed: () => controller.goToManajemenTugas(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.daftarSiswa.isEmpty) return const Center(child: Text("Belum ada siswa di kelas ini."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: controller.isPengganti ? Colors.grey.shade100 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text(siswa.namaLengkap[0])),
                title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("NISN: ${siswa.nisn}"),
                trailing: controller.isPengganti ? null : const Icon(Icons.chevron_right),
                onTap: controller.isPengganti ? null : () => controller.goToInputNilaiSiswa(siswa),
              ),
            );
          },
        );
      }),
    );
  }
}