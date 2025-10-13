// lib/app/modules/input_nilai_massal_akademik/views/input_nilai_massal_akademik_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/input_nilai_massal_akademik_controller.dart';

class InputNilaiMassalAkademikView
    extends GetView<InputNilaiMassalAkademikController> {
  const InputNilaiMassalAkademikView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input Nilai: ${controller.judulTugas}',
                style: const TextStyle(fontSize: 18)),
            Text('${controller.namaMapel} - Kelas ${controller.idKelas}',
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.daftarSiswa.isEmpty) {
                return const Center(child: Text("Tidak ada siswa di kelas ini."));
              }
              // Gunakan filteredSiswa untuk membangun list
              if (controller.filteredSiswa.isEmpty) {
                return const Center(child: Text("Siswa tidak ditemukan."));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding bawah agar tidak tertutup FAB
                itemCount: controller.filteredSiswa.length,
                itemBuilder: (context, index) {
                  final siswa = controller.filteredSiswa[index];
                  // Ambil TextEditingController yang sesuai dari map
                  final textController = controller.textControllers[siswa.uid];

                  return Obx(() {
                    final isAbsen = controller.absentStudents.contains(siswa.uid);
                    return Card(
                      color: isAbsen ? Colors.grey.shade300 : null,
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Checkbox untuk menandai absen
                            Checkbox(
                              value: isAbsen,
                              onChanged: (value) => controller.toggleAbsen(siswa.uid),
                              activeColor: Colors.red.shade700,
                            ),
                            // Nama Siswa
                            Expanded(
                              child: Text(
                                siswa.namaLengkap,
                                style: TextStyle(
                                  decoration: isAbsen ? TextDecoration.lineThrough : null,
                                  color: isAbsen ? Colors.grey.shade700 : null,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // TextField untuk input nilai
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: textController,
                                enabled: !isAbsen, // Nonaktifkan jika absen
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Nilai",
                                  counterText: "", // Hilangkan counter
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
      // Tombol Simpan menggunakan FloatingActionButton
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            onPressed: controller.isLoading.value || controller.isSaving.value
                ? null // Nonaktifkan tombol saat loading atau saving
                : controller.simpanNilaiMassal,
            icon: controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_alt_rounded),
            label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Semua"),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Widget untuk field pencarian
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          labelText: 'Cari Nama Siswa...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => controller.searchController.clear(),
          ),
        ),
      ),
    );
  }
}