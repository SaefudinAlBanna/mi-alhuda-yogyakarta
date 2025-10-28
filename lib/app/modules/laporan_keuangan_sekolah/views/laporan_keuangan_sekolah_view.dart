// lib/app/modules/laporan_keuangan_sekolah/views/laporan_keuangan_sekolah_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/laporan_keuangan_sekolah_controller.dart';

class LaporanKeuanganSekolahView extends GetView<LaporanKeuanganSekolahController> {
  const LaporanKeuanganSekolahView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan Sekolah'),
        centerTitle: true,
        actions: [
          // [MODIFIKASI] Tombol Filter pindah ke dalam menu, digantikan tombol Cetak
          IconButton(
            icon: Obx(() => controller.isExporting.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.print_rounded)),
            onPressed: controller.exportToPdf,
            tooltip: "Cetak Laporan",
          ),
          // [BARU] Tambahkan menu untuk Filter dan Atur Kategori
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'filter') controller.showFilterDialog();
              // Tambahkan rute ke manajemen kategori jika diperlukan
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(leading: Icon(Icons.filter_list_rounded), title: Text('Filter Laporan')),
              ),
              // Anda bisa tambahkan menu lain di sini jika perlu
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.daftarTahunAnggaran.isEmpty && !controller.isLoading.value) {
          return const Center(child: Text("Belum ada data keuangan yang tercatat."));
        }
        return Column(
          children: [
            _buildYearSelector(),
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDashboardContent(),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showPilihanTransaksiDialog,
        child: const Icon(Icons.add),
        tooltip: "Tambah Transaksi",
      ),
    );
  }

  Widget _buildYearSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        value: controller.tahunTerpilih.value,
        hint: const Text("Pilih Tahun Anggaran"),
        items: controller.daftarTahunAnggaran.map((tahun) {
          return DropdownMenuItem(value: tahun, child: Text("Tahun Anggaran $tahun"));
        }).toList(),
        onChanged: (value) {
          if (value != null) controller.pilihTahun(value);
        },
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () => controller.pilihTahun(controller.tahunTerpilih.value!),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          // [BARU] Indikator filter aktif
          Obx(() => Visibility(
            visible: controller.isFilterActive,
            child: _buildFilterIndicator(),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Buku Besar Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Obx(() => Text("${controller.daftarTransaksiTampil.value.length} item", style: Get.textTheme.bodySmall)),
            ],
          ),
          const Divider(),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterIndicator() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (controller.filterBulanTahun.value != null)
            Chip(
              label: Text(DateFormat.yMMMM('id_ID').format(controller.filterBulanTahun.value!)),
              onDeleted: () => controller.filterBulanTahun.value = null,
            ),
          if (controller.filterJenis.value != null)
            Chip(
              label: Text(controller.filterJenis.value!),
              onDeleted: () => controller.filterJenis.value = null,
            ),
          if (controller.filterKategori.value != null)
            Chip(
              label: Text(controller.filterKategori.value!),
              onDeleted: () => controller.filterKategori.value = null,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final summary = controller.summaryData;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildSummaryCard("Total Pemasukan", controller.formatRupiah(summary['totalPemasukan']), Colors.green),
          _buildSummaryCard("Total Pengeluaran", controller.formatRupiah(summary['totalPengeluaran']), Colors.red),
          _buildSummaryCard("Saldo Kas Tunai", controller.formatRupiah(summary['saldoKasTunai']), Colors.blue),
          _buildSummaryCard("Saldo di Bank", controller.formatRupiah(summary['saldoBank']), Colors.orange),
        ],
      );
    });
  }

  Widget _buildSummaryCard(String title, String value, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Obx(() {
      // [MODIFIKASI KUNCI] Ganti sumber data ke daftarTransaksiTampil
      if (controller.daftarTransaksiTampil.value.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(child: Text(
            controller.isFilterActive 
              ? "Tidak ada transaksi yang cocok dengan filter." 
              : "Belum ada transaksi di tahun ini."
          )),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // [MODIFIKASI KUNCI] Ganti sumber data dan panjang list
        itemCount: controller.daftarTransaksiTampil.value.length,
        itemBuilder: (context, index) {
          // [MODIFIKASI KUNCI] Ganti sumber data
          final trx = controller.daftarTransaksiTampil.value[index];
          final jenis = trx['jenis'] ?? '';
          final date = (trx['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          IconData icon;
          Color color;
          String prefix = "";

          if (jenis == 'Pemasukan') {
            icon = Icons.arrow_downward_rounded;
            color = Colors.green;
            prefix = "+";
          } else if (jenis == 'Pengeluaran') {
            icon = Icons.arrow_upward_rounded;
            color = Colors.red;
            prefix = "-";
          } else { // Transfer
            icon = Icons.swap_horiz_rounded;
            color = Colors.blue;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(trx['keterangan'] ?? 'Tanpa Keterangan', maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
              trailing: Text(
                "$prefix ${controller.formatRupiah(trx['jumlah'])}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    });
  }
}