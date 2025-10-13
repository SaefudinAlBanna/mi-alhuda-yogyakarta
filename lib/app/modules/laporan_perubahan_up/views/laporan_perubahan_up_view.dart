// lib/app/modules/laporan_perubahan_up/views/laporan_perubahan_up_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/laporan_perubahan_up_controller.dart';

class LaporanPerubahanUpView extends GetView<LaporanPerubahanUpController> {
  const LaporanPerubahanUpView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Perubahan UP'),
        centerTitle: true,
        actions: [
          Obx(() => controller.isProcessingPdf.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: controller.exportPdf,
                  tooltip: "Ekspor Laporan ke PDF",
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedAlasan.value,
              items: controller.alasanFilterOptions.map((alasan) => DropdownMenuItem(
                value: alasan,
                child: Text(alasan),
              )).toList(),
              onChanged: (value) {
                if (value != null) controller.selectedAlasan.value = value;
              },
              decoration: const InputDecoration(
                labelText: "Filter Berdasarkan Alasan",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
            )),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredLogList.isEmpty) {
                return const Center(child: Text("Tidak ada data log yang cocok."));
              }
              return ListView.builder(
                itemCount: controller.filteredLogList.length,
                itemBuilder: (context, index) {
                  final log = controller.filteredLogList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.namaSiswa,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Diubah pada: ${DateFormat('EEEE, dd MMM yyyy, HH:mm', 'id_ID').format(log.timestamp)}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Divider(height: 20),
                          _buildDetailRow("Alasan:", log.alasan),
                          if(log.catatan != null && log.catatan!.isNotEmpty)
                            _buildDetailRow("Catatan:", log.catatan!),
                          _buildDetailRow("Diubah oleh:", log.diubahOleh['nama'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNominalColumn("LAMA", log.nominalLama, Colors.red),
                              const Icon(Icons.arrow_forward_rounded),
                              _buildNominalColumn("BARU", log.nominalBaru, Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNominalColumn(String title, int value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}