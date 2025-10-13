import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Tambahkan import ini
import '../controllers/pengaturan_akademik_controller.dart';

class PengaturanAkademikView extends GetView<PengaturanAkademikController> {
  const PengaturanAkademikView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akademik')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.isAuthorized.value) {
          return const Center(
            child: Text("Anda tidak memiliki izin untuk mengakses halaman ini.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
          );
        }
        return _buildBody();
      }),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Bagian Konfigurasi Tanggal Akademik ---
        _buildSectionCard(
          title: "Konfigurasi Tanggal Akademik",
          icon: Icons.date_range_rounded,
          children: [
            Obx(() => _buildDatePickerTile(
                  label: "Tanggal Mulai Semester 2",
                  date: controller.tanggalMulaiSemester2.value,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: controller.tanggalMulaiSemester2.value ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      controller.simpanKonfigurasiTanggal(tglSem2: picked, tglTAbaru: controller.tanggalMulaiTahunAjaranBaru.value);
                    }
                  },
                )),
            Obx(() => _buildDatePickerTile(
                  label: "Tanggal Mulai Tahun Ajaran Baru",
                  date: controller.tanggalMulaiTahunAjaranBaru.value,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: controller.tanggalMulaiTahunAjaranBaru.value ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      controller.simpanKonfigurasiTanggal(tglSem2: controller.tanggalMulaiSemester2.value, tglTAbaru: picked);
                    }
                  },
                )),
            const SizedBox(height: 8),
            // Obx(() => controller.isSaving.value
            //     ? const Center(child: CircularProgressIndicator())
            //     : const SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 24),


        // --- Bagian Operasi Semester ---
        _buildSectionCard(
          title: "Operasi Semester",
          icon: Icons.calendar_month_rounded,
          children: [
            ListTile(
              title: const Text("Tahun Ajaran Aktif"),
              trailing: Text(controller.tahunAjaranAktif, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text("Semester Aktif Saat Ini"),
              trailing: Text("Semester ${controller.semesterAktif}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                if (controller.semesterAktif == '1') {
                  return ElevatedButton.icon(
                    onPressed: controller.prosesLanjutkanKeSemesterBerikutnya,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text("Lanjutkan ke Semester 2"),
                  );
                } else {
                  return const ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.blue),
                    title: Text("Semester 2 sedang berjalan."),
                    subtitle: Text("Proses selanjutnya adalah Penutupan Tahun Ajaran di akhir semester."),
                  );
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // --- Bagian Operasi Akhir Tahun Ajaran ---
        _buildSectionCard(
          title: "Operasi Akhir Tahun",
          icon: Icons.school_rounded,
          children: [
            ListTile(
              title: const Text("Penutupan Tahun Ajaran & Kenaikan Kelas"),
              subtitle: Text("Proses ini akan mengakhiri tahun ajaran ${controller.tahunAjaranAktif} dan memindahkan siswa ke tahun ajaran berikutnya."),
            ),
             Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() => ElevatedButton(
                onPressed: controller.semesterAktif == '2' 
                    ? controller.goToProsesKenaikanKelas 
                    : null, // Dinonaktifkan jika masih semester 1
                child: const Text("Tutup Tahun Ajaran & Proses Kenaikan"),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // [BARU] Widget pembantu untuk DatePickerTile
  Widget _buildDatePickerTile({required String label, DateTime? date, VoidCallback? onTap}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(date != null ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date) : "Belum diatur"),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: onTap,
    );
  }
}