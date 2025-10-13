// lib/app/modules/rekap_absensi/views/rekap_absensi_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/rekap_absensi_controller.dart';

class RekapAbsensiView extends GetView<RekapAbsensiController> {
  const RekapAbsensiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Absensi'),
        actions: [
          Obx(() => controller.isProcessingPdf.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: controller.exportPdf,
                  tooltip: "Cetak Laporan Absensi",
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(context),
          Expanded(
            child: Obx(() {
              if (controller.selectedKelasId.value == null && controller.scope.value == 'sekolah') {
                return const Center(child: Text("Silakan pilih kelas untuk melihat rekap."));
              }
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // [PERBAIKAN] Gunakan rekapDataHarian untuk mengecek data
              if (controller.rekapDataHarian.isEmpty) {
                return const Center(child: Text("Tidak ada data absensi pada periode ini."));
              }
              // [PEROMBAKAN TOTAL TAMPILAN KONTEN]
              return Column(
                children: [
                  _buildTotalRekapSection(), // Tetap menampilkan total
                  const Divider(thickness: 1, height: 1),
                  
                  // Judul baru untuk rincian per siswa
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Rincian Ketidakhadiran per Siswa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Tampilkan daftar rincian per siswa
                  Expanded(
                    child: Obx(() {
                      if (controller.rekapPerSiswa.isEmpty) {
                        return const Center(child: Text("Semua siswa hadir selama periode ini."));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.rekapPerSiswa.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final siswaRekap = controller.rekapPerSiswa[index];
                          return _buildSiswaRekapItem(siswaRekap);
                        },
                      );
                    }),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
  
  // [WIDGET BARU] Untuk menampilkan rincian per siswa
  Widget _buildSiswaRekapItem(SiswaAbsensiRekap siswaRekap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(siswaRekap.nama, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (siswaRekap.sakit > 0) Chip(label: Text("S: ${siswaRekap.sakit}"), backgroundColor: Colors.orange.shade100),
          if (siswaRekap.izin > 0) const SizedBox(width: 4),
          if (siswaRekap.izin > 0) Chip(label: Text("I: ${siswaRekap.izin}"), backgroundColor: Colors.blue.shade100),
          if (siswaRekap.alfa > 0) const SizedBox(width: 4),
          if (siswaRekap.alfa > 0) Chip(label: Text("A: ${siswaRekap.alfa}"), backgroundColor: Colors.red.shade100),
        ],
      ),
    );
  }

  // ... (sisa widget tidak berubah, hanya widget _buildRekapHarianItem yang dihapus)

  Widget _buildFilterSection(BuildContext context) {
    final months = List.generate(12, (index) {
      return DropdownMenuItem(
        value: index + 1,
        child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(0, index + 1))),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (controller.scope.value == 'sekolah')
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text("Pilih Kelas"),
              items: controller.daftarKelas.map((kelasData) {
                final id = kelasData['id'];
                final nama = kelasData['nama'];
                return DropdownMenuItem(value: id, child: Text(nama!));
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.selectedKelasId.value = value;
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => DropdownButtonFormField<int>(
                  value: controller.selectedMonth.value,
                  items: months,
                  onChanged: (val) {
                    if (val != null) controller.selectedMonth.value = val;
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Obx(() => DropdownButtonFormField<int>(
                  value: controller.selectedYear.value,
                  items: controller.availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.selectedYear.value = val;
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: controller.fetchRekapData,
            icon: const Icon(Icons.search),
            label: const Text("Tampilkan Data"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildTotalRekapSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _rekapItem("Hadir", controller.totalRekap['hadir'] ?? 0, Colors.green.shade700),
          _rekapItem("Sakit", controller.totalRekap['sakit'] ?? 0, Colors.orange.shade700),
          _rekapItem("Izin", controller.totalRekap['izin'] ?? 0, Colors.blue.shade700),
          _rekapItem("Alfa", controller.totalRekap['alfa'] ?? 0, Colors.red.shade700),
        ],
      )),
    );
  }

  Widget _rekapItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}