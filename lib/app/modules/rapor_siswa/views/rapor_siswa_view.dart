// app/modules/rapor_siswa/views/rapor_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rapor_siswa_controller.dart';

class RaporSiswaView extends GetView<RaporSiswaController> {
  const RaporSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Rapor Siswa'),
  //       centerTitle: true,
  //       actions: [
  //         // Tombol untuk cetak/download PDF
  //         IconButton(
  //           icon: Icon(Icons.picture_as_pdf),
  //           onPressed: () {
  //             // Panggil fungsi untuk generate PDF di controller
  //             // controller.generatePdfRapor();
  //              Get.snackbar("Fitur Dalam Pengembangan", "Cetak ke PDF akan segera tersedia.");
  //           },
  //         )
  //       ],
  //     ),
  //     body: Obx(() {
  //       if (controller.isLoading.value) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       return SingleChildScrollView(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             _buildHeaderRapor(),
  //             const SizedBox(height: 24),
  //             const Text("A. Capaian Akademik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //             const SizedBox(height: 8),
  //             _buildTabelNilai(),
  //             const SizedBox(height: 24),
  //             const Text("B. Catatan Wali Kelas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //             const SizedBox(height: 8),
  //             Container(
  //               width: double.infinity,
  //               padding: EdgeInsets.all(12),
  //               decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
  //               child: Text(controller.dataPendukungRapor.value['catatanWaliKelas'] ?? 'Tidak ada catatan.'),
  //             ),
  //             // Anda bisa tambahkan bagian Absensi, Ekstrakurikuler, dll di sini
  //           ],
  //         ),
  //       );
  //     }),
  //   );
  // }

  // Widget _buildHeaderRapor() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("Nama Siswa\t\t: ${controller.dataSiswa.value['namasiswa']}"),
  //       Text("Kelas\t\t\t\t\t\t\t\t: ${controller.dataSiswa.value['idKelas']}"),
  //       Text("Semester\t\t\t\t\t: I (Satu)"), // Bisa dibuat dinamis
  //       Text("Tahun Ajaran\t: 2024/2025"), // Bisa dibuat dinamis
  //     ],
  //   );
  // }
  
  // Widget _buildTabelNilai() {
  //   return DataTable(
  //     columns: const [
  //       DataColumn(label: Text('No')),
  //       DataColumn(label: Text('Mata Pelajaran')),
  //       DataColumn(label: Text('Nilai Akhir')),
  //       DataColumn(label: Text('Capaian Kompetensi')),
  //     ],
  //     rows: List<DataRow>.generate(
  //       controller.daftarNilaiRapor.length,
  //       (index) {
  //         final data = controller.daftarNilaiRapor[index];
  //         return DataRow(cells: [
  //           DataCell(Text((index + 1).toString())),
  //           DataCell(Text(data.namaMapel)),
  //           DataCell(Text(data.nilaiAkhir.toStringAsFixed(1))), // Dibulatkan 1 desimal
  //           DataCell(Text(data.capaianKompetensi, softWrap: true)),
  //         ]);
  //       },
  //     ),
    );
  }
}