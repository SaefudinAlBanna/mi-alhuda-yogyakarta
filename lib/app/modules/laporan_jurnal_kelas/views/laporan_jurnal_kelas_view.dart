// lib/app/modules/laporan_jurnal_kelas/views/laporan_jurnal_kelas_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/kelas_simple_model.dart';
import '../controllers/laporan_jurnal_kelas_controller.dart';

class LaporanJurnalKelasView extends GetView<LaporanJurnalKelasController> {
  const LaporanJurnalKelasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Jurnal per Kelas'),
        actions: [
          Obx(() => IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Ekspor ke PDF",
            onPressed: controller.daftarLaporan.isNotEmpty ? controller.exportToPdf : null,
          )),
        ],
      ),
      body: Column(
        children: [
          _buildFilterArea(context),
          const Divider(height: 1),
          Expanded(child: _buildResultArea()),
        ],
      ),
    );
  }

  Widget _buildFilterArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Obx(() => DropdownButtonFormField<KelasSimpleModel>(
            value: controller.kelasTerpilih.value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Pilih Kelas",
              border: const OutlineInputBorder(),
              suffix: controller.isKelasLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            ),
            items: controller.daftarKelas.map((k) => DropdownMenuItem(value: k, child: Text(k.nama))).toList(),
            onChanged: (value) => controller.kelasTerpilih.value = value,
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker(context, isMulai: true)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("s/d")),
              Expanded(child: _buildDatePicker(context, isMulai: false)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton.icon(
              icon: controller.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search),
              label: Text(controller.isLoading.value ? "Mencari..." : "Tampilkan Laporan"),
              onPressed: controller.isLoading.value ? null : controller.fetchLaporan,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool isMulai}) {
    return InkWell(
      onTap: () => controller.pickDate(context, isMulai: isMulai),
      child: Obx(() => InputDecorator(
        decoration: InputDecoration(
          labelText: isMulai ? "Dari Tanggal" : "Sampai Tanggal",
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        ),
        child: Text(DateFormat('dd MMM yyyy', 'id_ID').format(isMulai ? controller.tanggalMulai.value : controller.tanggalSelesai.value)),
      )),
    );
  }

  Widget _buildResultArea() {
    return Obx(() {
      if (controller.isLoading.value && controller.daftarLaporan.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarLaporan.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("Silakan pilih rentang tanggal dan klik 'Tampilkan Laporan' untuk memulai.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.daftarLaporan.length,
        itemBuilder: (context, index) {
          final item = controller.daftarLaporan[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Header (Tanggal & Nama Guru)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(item.tanggal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(item.namaGuru, style: TextStyle(fontSize: 12, color: item.isPengganti ? Colors.amber.shade800 : Colors.black, fontWeight: item.isPengganti ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  
                  // --- [TAMBAHAN BARU: REKAP ABSENSI] ---
                  if (item.rekapAbsensi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.checklist_rtl_rounded, size: 18, color: Colors.blue.shade800),
                            const SizedBox(width: 8),
                            Text(
                              "Kehadiran: ${item.rekapAbsensi!}",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const Divider(height: 16),
                  
                  // Detail Jurnal
                  Text("${item.namaMapel} (Jam ke-${item.jamKe})", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(item.materi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (item.catatan != null && item.catatan!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("Catatan: ${item.catatan}", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}