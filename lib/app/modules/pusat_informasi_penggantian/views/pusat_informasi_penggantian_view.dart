// lib/app/modules/pusat_informasi_penggantian/views/pusat_informasi_penggantian_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/models/info_penggantian_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/pusat_informasi_penggantian_controller.dart';

class PusatInformasiPenggantianView extends GetView<PusatInformasiPenggantianController> {
  const PusatInformasiPenggantianView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Penggantian Guru'),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: "Insidental (Per Sesi)"),
            Tab(text: "Terencana (Rentang Waktu)"),
          ],
        ),
        actions: [
          if (controller.dashC.isPimpinan)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: "Editor Jadwal",
            onSelected: (value) {
              if (value == 'Atur_Pengganti') {Get.toNamed(Routes.ATUR_PENGGANTIAN_HOST);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Atur_Pengganti', child: ListTile(leading: Icon(Icons.change_circle_outlined), title: Text("Atur Pengganti Guru"))),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          _buildDaftarPenggantian(controller.isLoadingInsidental, controller.daftarInsidental),
          _buildDaftarPenggantian(controller.isLoadingRentang, controller.daftarRentang),
        ],
      ),
    );
  }

  Widget _buildDaftarPenggantian(RxBool isLoading, RxList<InfoPenggantianModel> daftar) {
    return Obx(() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (daftar.isEmpty) {
        return const Center(child: Text("Tidak ada data penggantian."));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: daftar.length,
        itemBuilder: (context, index) {
          final item = daftar[index];
          return _buildInfoCard(item);
        },
      );
    });
  }

  Widget _buildInfoCard(InfoPenggantianModel item) {
    final isInsidental = item.tipe == TipePenggantian.Insidental;
    String tanggalFormatted;
    if (isInsidental) {
      tanggalFormatted = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(item.tanggalMulai);
    } else {
      final mulai = DateFormat('dd MMM', 'id_ID').format(item.tanggalMulai);
      final selesai = DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalSelesai!);
      tanggalFormatted = "$mulai - $selesai";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isInsidental ? Icons.access_time_filled_rounded : Icons.date_range_rounded, 
                  color: isInsidental ? Colors.blue.shade700 : Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(tanggalFormatted, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGuruInfo("Guru Asli", item.namaGuruAsli),
                const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                _buildGuruInfo("Guru Pengganti", item.namaGuruPengganti),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Detail: ${item.detailSesi}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuruInfo(String peran, String nama) {
    return Column(
      children: [
        Text(peran, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}