import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_absensi_model.dart';
import '../controllers/absensi_wali_kelas_controller.dart';

class AbsensiWaliKelasView extends GetView<AbsensiWaliKelasController> {
  const AbsensiWaliKelasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime(2022),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                controller.onDateChanged(pickedDate);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Tanggal
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(controller.selectedDate.value),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                )),
          ),
          
          // Daftar Siswa
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.kelasDiampu.isEmpty) {
                return const Center(child: Text("Anda tidak ditugaskan sebagai wali kelas."));
              }
              if (controller.daftarSiswa.isEmpty) {
                return const Center(child: Text("Tidak ada siswa di kelas ini."));
              }
              return ListView.builder(
                itemCount: controller.daftarSiswa.length,
                itemBuilder: (context, index) {
                  final siswa = controller.daftarSiswa[index];
                  return _buildSiswaTile(siswa);
                },
              );
            }),
          ),
        ],
      ),
      // Tombol Simpan
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: controller.isSaving.value ? null : controller.simpanAbsensi,
              icon: controller.isSaving.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(controller.isSaving.value ? "MENYIMPAN..." : "Simpan Absensi Hari Ini"),
            )),
      ),
    );
  }

  // Widget untuk setiap baris siswa
  Widget _buildSiswaTile(SiswaAbsensiModel siswa) {
    return ListTile(
      leading: CircleAvatar(child: Text("${controller.daftarSiswa.indexOf(siswa) + 1}")),
      title: Text(siswa.nama),
      trailing: Obx(() => SizedBox(
            // --- [PERBAIKAN] Atur lebar secara manual untuk mencegah overflow ---
            width: 180, // Sesuaikan nilai ini jika perlu
            // -----------------------------------------------------------------
            child: SegmentedButton<String>(
              // --- [PERBAIKAN] Buat tombol lebih ringkas ---
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              // ---------------------------------------------
              segments: const [
                ButtonSegment(value: 'Hadir', label: Text('H'), tooltip: "Hadir"),
                ButtonSegment(value: 'Sakit', label: Text('S'), tooltip: "Sakit"),
                ButtonSegment(value: 'Izin', label: Text('I'), tooltip: "Izin"),
                ButtonSegment(value: 'Alfa', label: Text('A'), tooltip: "Alfa"),
              ],
              selected: {siswa.status.value},
              onSelectionChanged: (newSelection) {
                controller.ubahStatusAbsensi(siswa, newSelection.first);
              },
            ),
          )),
    );
  }
}