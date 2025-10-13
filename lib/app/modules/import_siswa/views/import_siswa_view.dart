// lib/app/modules/import_siswa/views/import_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_siswa_controller.dart';

class ImportSiswaView extends GetView<ImportSiswaController> {
  const ImportSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Siswa dari Excel'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kotak Informasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Petunjuk Penggunaan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("1. Unduh file template Excel di bawah ini."),
                  const Text("2. Isi data siswa sesuai kolom: NISN, Nama, SPP."),
                  const Text("3. Upload kembali file yang sudah diisi."),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => OutlinedButton.icon(
                          onPressed: controller.isDownloading.value ? null : controller.downloadTemplate,
                          icon: controller.isDownloading.value
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download),
                          label: Text(controller.isDownloading.value ? "MENGUNDUH..." : "Unduh Template Excel"),
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Pilih File
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: controller.pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Pilih File Excel (.xlsx)"),
            ),
            const SizedBox(height: 12),
            Obx(() => Center(child: Text(controller.selectedFileName.value, style: const TextStyle(fontStyle: FontStyle.italic)))),
            
            const SizedBox(height: 30),

            // Tombol Mulai Import
            Obx(() => SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.pickedFile.value != null ? controller.startImport : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text("MULAI PROSES IMPORT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
            
            const SizedBox(height: 30),
            
            // Progress Bar dan Hasil
            Obx(() {
              if (controller.totalRows.value == 0) return const SizedBox.shrink();
              return Column(
                children: [
                  Text("Memproses ${controller.processedRows.value} dari ${controller.totalRows.value} baris..."),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.totalRows.value > 0
                        ? controller.processedRows.value / controller.totalRows.value
                        : 0,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Berhasil: ${controller.successCount.value}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text("Gagal: ${controller.errorCount.value}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (controller.errorDetails.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text("Detail Kegagalan:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: controller.errorDetails.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          child: Text(controller.errorDetails[index], style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ]
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}