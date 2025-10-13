// lib/app/modules/jurnal_harian_guru/views/jurnal_harian_guru_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/jadwal_tugas_item_model.dart';
import '../controllers/jurnal_harian_guru_controller.dart';

class JurnalHarianGuruView extends GetView<JurnalHarianGuruController> {
  const JurnalHarianGuruView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Jurnal Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadTugasHarian(),
            tooltip: "Muat Ulang",
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => controller.tugasTerpilih.isNotEmpty
          ? _buildAksiMassalBottomBar()
          : const SizedBox.shrink()),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarTugasHariIni.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Tidak ada jadwal mengajar untuk Anda hari ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding bawah
          itemCount: controller.daftarTugasHariIni.length,
          itemBuilder: (context, index) {
            final tugas = controller.daftarTugasHariIni[index];
            return _buildTugasCard(tugas);
          },
        );
      }),
    );
  }

  Widget _buildAksiMassalBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.library_books_rounded),
          label: Obx(() => Text("Isi Jurnal (${controller.tugasTerpilih.length} Terpilih)")),
          onPressed: () => controller.openJurnalDialog(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTugasCard(JadwalTugasItem tugas) {
    final theme = Get.theme;
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    IconData statusIcon = Icons.hourglass_empty_rounded;
    String statusText = "Belum Diisi";

    switch (tugas.status) {
      case StatusJurnal.SudahDiisi:
        cardColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        statusIcon = Icons.check_circle_rounded;
        statusText = "Sudah Diisi";
        break;
      case StatusJurnal.TugasPengganti:
        cardColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade400;
        statusIcon = Icons.people_alt_rounded;
        statusText = "Tugas Pengganti";
        break;
      default:
        break;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (tugas.status == StatusJurnal.BelumDiisi)
                  Obx(() => Checkbox(
                    value: controller.tugasTerpilih.contains(tugas),
                    onChanged: (val) => controller.toggleTugasSelection(tugas),
                  )),
                if (tugas.status != StatusJurnal.BelumDiisi)
                  const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${tugas.idKelas.split('-').first} - Jam ${tugas.jamKe}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(tugas.namaMapel, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => controller.openJurnalDialog(targetTugas: tugas),
                  child: Text(tugas.status == StatusJurnal.SudahDiisi ? "Edit" : "Isi"),
                ),
              ],
            ),
            if (tugas.status == StatusJurnal.SudahDiisi) ...[
              const Divider(height: 20),
              _buildInfoRow(Icons.article_outlined, "Materi", tugas.materiDiisi ?? '-'),
              if (tugas.catatanDiisi != null && tugas.catatanDiisi!.isNotEmpty)
                _buildInfoRow(Icons.speaker_notes_outlined, "Catatan", tugas.catatanDiisi!),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(statusText, style: theme.textTheme.bodySmall),
                const Spacer(),
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(tugas.namaGuru, style: theme.textTheme.bodySmall),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}