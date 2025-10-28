// lib/app/modules/cari_siswa_keuangan/views/cari_siswa_keuangan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/cari_siswa_keuangan_controller.dart';

class CariSiswaKeuanganView extends GetView<CariSiswaKeuanganController> {
  const CariSiswaKeuanganView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // [BARU] Judul AppBar dinamis berdasarkan mode
        title: Obx(() => Text(controller.mode.value == 'pilih' ? 'Pilih Siswa' : 'Cari Siswa')),
        centerTitle: true,
        actions: [
        if (controller.dashC.isPimpinan)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined),
            tooltip: "Editor Jadwal",
            onSelected: (value) {
              if (value == 'Biaya') {Get.toNamed(Routes.PENGATURAN_BIAYA);}
              if (value == 'Tagihan') {Get.toNamed(Routes.BUAT_TAGIHAN_TAHUNAN);}
              if (value == 'Laporan') {Get.toNamed(Routes.LAPORAN_KEUANGAN);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Biaya', child: ListTile(leading: Icon(Icons.dashboard_customize_outlined), title: Text("Biaya"))),
              const PopupMenuItem(value: 'Tagihan', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("Tagihan"))),
              const PopupMenuItem(value: 'Laporan', child: ListTile(leading: Icon(Icons.schedule_sharp), title: Text("Laporan"))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildFilterKelas(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: controller.searchC,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama siswa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.daftarSiswaTampil.isEmpty) {
                return const Center(child: Text("Siswa tidak ditemukan."));
              }
              return ListView.builder(
                itemCount: controller.daftarSiswaTampil.length,
                itemBuilder: (context, index) {
                  final siswa = controller.daftarSiswaTampil[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(siswa.namaLengkap[0].toUpperCase())),
                    title: Text(siswa.namaLengkap),
                    subtitle: Text("Kelas: ${siswa.kelasId?.split('-').first ?? 'N/A'}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    // [PERUBAHAN] Panggil fungsi handleSiswaTap
                    onTap: () => controller.handleSiswaTap(siswa),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Get.toNamed(Routes.MANAJEMEN_TUNGGAKAN_AWAL),
        icon: const Icon(Icons.post_add_rounded),
        label: const Text("Input Tunggakan Awal"),
      ),
    );
  }

  Widget _buildFilterKelas() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.kelasTerpilih.value,
      decoration: InputDecoration(
        labelText: "Filter Kelas",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.class_outlined),
      ),
      items: controller.daftarKelasFilter.map((kelas) => DropdownMenuItem(
        value: kelas,
        child: Text(kelas),
      )).toList(),
      onChanged: (value) {
        if (value != null) controller.kelasTerpilih.value = value;
      },
    ));
  }
}