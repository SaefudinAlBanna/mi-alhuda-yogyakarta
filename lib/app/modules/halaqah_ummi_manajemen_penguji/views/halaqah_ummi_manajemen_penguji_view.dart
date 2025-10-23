import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/halaqah_ummi_manajemen_penguji_controller.dart';

class HalaqahUmmiManajemenPengujiView extends GetView<HalaqahUmmiManajemenPengujiController> {
  const HalaqahUmmiManajemenPengujiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Penguji Munaqosyah'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.allPengampu.isEmpty) {
          return const Center(child: Text("Tidak ada kandidat pengampu yang ditemukan."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.allPengampu.length,
          itemBuilder: (context, index) {
            final pengampu = controller.allPengampu[index];
            return Obx(() {
              final isSelected = controller.pengujiStatus[pengampu.uid] ?? false;
              return SwitchListTile(
                // --- [PERBAIKAN UI] Tampilkan nama yang lebih baik ---
                title: Text(pengampu.displayName), // Gunakan displayName
                subtitle: Text(pengampu.nama), // Tampilkan nama lengkap sebagai subtitle
                value: isSelected,
                onChanged: (value) {
                  controller.togglePenguji(pengampu.uid, value);
                },
              );
            });
          },
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.isSaving.value ? null : controller.simpanPerubahan,
        icon: controller.isSaving.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.save),
        label: const Text("Simpan Perubahan"),
      )),
    );
  }
}