// lib/app/modules/halaqah_setoran_siswa/views/halaqah_setoran_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/halaqah_setoran_siswa_controller.dart';

class HalaqahSetoranSiswaView extends GetView<HalaqahSetoranSiswaController> {
  const HalaqahSetoranSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Setoran: ${controller.siswa.nama}")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.pageMode.value == PageMode.BeriNilai) ...[
              // --- [BARU] Tampilkan catatan orang tua di sini ---
              _buildCatatanOrangTuaSection(),
              _buildPenilaianSection(),
            ],
            _buildTugasBaruSection(),
          ],
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.isSaving.value ? null : controller.saveData,
        label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Penilaian"),
        icon: controller.isSaving.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.save),
      )),
    );
  }

  Widget _buildCatatanOrangTuaSection() {
    return Obx(() {
      final catatan = controller.catatanOrangTuaTerakhir.value;
      return _buildCard(
        title: "Catatan dari Orang Tua",
        child: Text(
          catatan.isNotEmpty ? catatan : "Belum ada catatan dari orang tua untuk setoran ini.",
          style: TextStyle(
            fontStyle: catatan.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            color: catatan.isNotEmpty ? Colors.black87 : Colors.grey,
          ),
        ),
      );
    });
  }

  // Widget untuk menilai tugas yang sudah ada
  Widget _buildPenilaianSection() {
    return Column(
      children: [
        _buildCard(
          title: "Penilaian Setoran Hari Ini",
          child: Column(
            children: [
              _buildTextField("Nilai Sabak/Terbaru", controller.nilaiControllers['sabak']!),
              const SizedBox(height: 12),
              _buildTextField("Nilai Sabqi", controller.nilaiControllers['sabqi']!),
              const SizedBox(height: 12),
              _buildTextField("Nilai Manzil", controller.nilaiControllers['manzil']!),
              const SizedBox(height: 12),
              _buildTextField("Nilai Tambahan", controller.nilaiControllers['tambahan']!),
            ],
          ),
        ),
        _buildCard(
          title: "Catatan Pengampu",
          child: TextField(
            controller: controller.catatanPengampuC,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Tulis catatan untuk orang tua...",
            ),
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  // Widget untuk memberikan tugas baru
  Widget _buildTugasBaruSection() {
    bool isBeriNilaiMode = controller.pageMode.value == PageMode.BeriNilai;
    return _buildCard(
      // Judul berubah secara dinamis
      title: isBeriNilaiMode ? "Tugas Untuk Pertemuan Berikutnya" : "Beri Tugas Baru",
      child: Column(
        children: [
          // Jika mode BeriNilai, tampilkan tugas sebelumnya yang bisa diedit
          if (isBeriNilaiMode) ...[
             const Text(
              "Tugas sebelumnya ditampilkan. Anda bisa mengeditnya jika ada perubahan.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField("Tugas Sabak/Terbaru", controller.tugasControllers['sabak']!),
          const SizedBox(height: 12),
          _buildTextField("Tugas Sabqi", controller.tugasControllers['sabqi']!),
          const SizedBox(height: 12),
          _buildTextField("Tugas Manzil", controller.tugasControllers['manzil']!),
          const SizedBox(height: 12),
          _buildTextField("Tugas Tambahan", controller.tugasControllers['tambahan']!),
        ],
      ),
    );
  }

  // Helper untuk membuat Card yang konsisten
  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 24, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }
  
  // Helper untuk membuat TextField yang konsisten
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}