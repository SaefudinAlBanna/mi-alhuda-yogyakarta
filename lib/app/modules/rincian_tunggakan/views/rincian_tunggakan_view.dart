// lib/app/modules/rincian_tunggakan/views/rincian_tunggakan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/rincian_tunggakan_controller.dart';

class RincianTunggakanView extends GetView<RincianTunggakanController> {
  const RincianTunggakanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Penunggak ${controller.jenisPembayaran}'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Filter Kelas: ${controller.filterKelas}",
              style: TextStyle(color: Colors.black.withOpacity(0.8)),
            ),
          ),
        ),
        // [BARU] Tambahkan tombol aksi untuk ekspor PDF
        actions: [
          Obx(() => controller.isProcessingPdf.value
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: controller.exportPdf,
                tooltip: "Ekspor ke PDF",
              ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarPenunggak.isEmpty) {
          return const Center(
            child: Text("Tidak ada data tunggakan ditemukan untuk kategori ini."),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.daftarPenunggak.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final siswa = controller.daftarPenunggak[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(siswa.namaSiswa),
              subtitle: Text("Kelas: ${siswa.namaKelasSimple}"),
              trailing: Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(siswa.totalTunggakan),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}