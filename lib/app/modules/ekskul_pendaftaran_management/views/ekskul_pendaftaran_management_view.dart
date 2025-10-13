// lib/app/modules/ekskul_pendaftaran_management/views/ekskul_pendaftaran_management_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ekskul_pendaftaran_management_controller.dart';

class EkskulPendaftaranManagementView extends GetView<EkskulPendaftaranManagementController> {
  const EkskulPendaftaranManagementView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pendaftaran'),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.pendaftaranAktif.value == null) return const SizedBox.shrink();
            return controller.isProcessingPdf.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: controller.exportPdf,
                  tooltip: "Cetak Rekap Pendaftar",
                );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return controller.pendaftaranAktif.value != null
            ? _buildDashboardPendaftaranAktif(context)
            : _buildFormBukaPendaftaran(context);
      }),
    );
  }

  Widget _buildFormBukaPendaftaran(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Saat ini tidak ada periode pendaftaran ekskul yang aktif. Silakan buka pendaftaran baru.", textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(controller: controller.judulC, 
        decoration: const InputDecoration(labelText: "Judul Pendaftaran", 
        border: OutlineInputBorder())),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => controller.pickDateRange(context),
          icon: const Icon(Icons.calendar_month),
          label: Obx(() => Text(
            (controller.tanggalBuka.value == null || controller.tanggalTutup.value == null)
              ? "Pilih Tanggal Buka & Tutup"
              : "${DateFormat('dd MMM yyyy').format(controller.tanggalBuka.value!)} - ${DateFormat('dd MMM yyyy').format(controller.tanggalTutup.value!)}",
          )),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 24),
        Obx(() => ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : controller.bukaPendaftaran,
          icon: const Icon(Icons.play_circle_fill_rounded),
          label: const Text("Buka Pendaftaran Sekarang"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        )),
      ],
    );
  }

  Widget _buildDashboardPendaftaranAktif(BuildContext context) {
    final data = controller.pendaftaranAktif.value!.data() as Map<String, dynamic>;
    final pendaftar = data['ekskulDipilih'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("PENDAFTARAN SEDANG DIBUKA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(data['judul'], style: Get.textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text("Berakhir pada: ${DateFormat('dd MMMM yyyy').format((data['tanggalTutup'] as Timestamp).toDate())}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Rekap Pendaftar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.daftarEkskulDitawarkan.length,
              itemBuilder: (context, index) {
                final ekskul = controller.daftarEkskulDitawarkan[index];
                final jumlahPendaftar = (pendaftar[ekskul.id] as List?)?.length ?? 0;
                return ListTile(
                  title: Text(ekskul.namaEkskul),
                  trailing: Text("$jumlahPendaftar Pendaftar", style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            )),
          ),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : controller.tutupPendaftaran,
            icon: const Icon(Icons.stop_circle_rounded),
            label: const Text("Tutup Periode Pendaftaran"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          )),
        ],
      ),
    );
  }
}