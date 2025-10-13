// lib/app/modules/import_pegawai/views/import_pegawai_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_pegawai_controller.dart';

class ImportPegawaiView extends GetView<ImportPegawaiController> {
  const ImportPegawaiView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Import Pegawai dari Excel'),
      //   centerTitle: true,
      // ),
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(24),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       // 1. Kotak Informasi
      //       Container(
      //         padding: const EdgeInsets.all(16),
      //         decoration: BoxDecoration(
      //           color: Colors.blue.shade50,
      //           borderRadius: BorderRadius.circular(12),
      //           border: Border.all(color: Colors.blue.shade200),
      //         ),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             const Text("Petunjuk Penggunaan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      //             const SizedBox(height: 8),
      //             const Text("1. Unduh file template Excel yang sudah disediakan."),
      //             const Text("2. Isi data pegawai sesuai kolom: Nama, Email, Jabatan."),
      //             const Text("3. Upload file yang sudah diisi ke sistem ini."),
      //             const SizedBox(height: 12),
      //             SizedBox(
      //               width: double.infinity,
      //               child: Obx(() => OutlinedButton.icon(
      //                     onPressed: controller.isDownloading.value ? null : controller.downloadTemplate,
      //                     icon: controller.isDownloading.value
      //                         ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
      //                         : const Icon(Icons.download),
      //                     label: Text(controller.isDownloading.value ? "MENGUNDUH..." : "Unduh Template Excel"),
      //                   )),
      //             ),
      //           ],
      //         ),
      //       ),
      //       const SizedBox(height: 30),

      //       // 2. Tombol Pilih File
      //       OutlinedButton.icon(
      //         style: OutlinedButton.styleFrom(
      //           padding: const EdgeInsets.symmetric(vertical: 16),
      //         ),
      //         onPressed: controller.pickFile,
      //         icon: const Icon(Icons.upload_file),
      //         label: const Text("Pilih File Excel (.xlsx)"),
      //       ),
      //       const SizedBox(height: 12),
      //       Obx(() => Center(child: Text(controller.selectedFileName.value, style: const TextStyle(fontStyle: FontStyle.italic)))),
            
      //       const SizedBox(height: 30),

      //       // 3. Tombol Mulai Import
      //       Obx(() => SizedBox(
      //             height: 50,
      //             child: ElevatedButton.icon(
      //               style: ElevatedButton.styleFrom(
      //                 backgroundColor: Colors.green.shade700,
      //                 foregroundColor: Colors.white,
      //               ),
      //               // Menggunakan controller.pickedFile.value untuk pengecekan
      //               onPressed: controller.pickedFile.value != null ? controller.startImport : null,
      //               icon: const Icon(Icons.play_arrow_rounded),
      //               label: const Text("MULAI PROSES IMPORT", style: TextStyle(fontWeight: FontWeight.bold)),
      //             ),
      //           )),
            
      //       const SizedBox(height: 30),
            
      //       // 4. Progress Bar dan Hasil
      //       Obx(() {
      //         if (controller.totalRows.value == 0) return const SizedBox.shrink();
      //         return Column(
      //           children: [
      //             Text("Memproses ${controller.processedRows.value} dari ${controller.totalRows.value} baris..."),
      //             const SizedBox(height: 8),
      //             LinearProgressIndicator(
      //               value: controller.totalRows.value > 0
      //                   ? controller.processedRows.value / controller.totalRows.value
      //                   : 0,
      //               minHeight: 10,
      //             ),
      //             const SizedBox(height: 20),
      //             Row(
      //               mainAxisAlignment: MainAxisAlignment.spaceAround,
      //               children: [
      //                 Text("Berhasil: ${controller.successCount.value}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      //                 Text("Gagal: ${controller.errorCount.value}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      //               ],
      //             ),
      //             if (controller.errorDetails.isNotEmpty) ...[
      //               const SizedBox(height: 10),
      //               const Text("Detail Kegagalan:", style: TextStyle(fontWeight: FontWeight.bold)),
      //               ...controller.errorDetails.map((e) => Text(e, style: const TextStyle(fontSize: 12)))
      //             ]
      //           ],
      //         );
      //       })
      //     ],
      //   ),
      // ),
    );
  }
}