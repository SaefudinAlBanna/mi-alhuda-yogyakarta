// lib/app/modules/financial_dashboard_pimpinan/views/financial_dashboard_pimpinan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/komite_log_transaksi_model.dart';
import '../controllers/financial_dashboard_pimpinan_controller.dart';

class FinancialDashboardPimpinanView extends GetView<FinancialDashboardPimpinanController> {
  const FinancialDashboardPimpinanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // [PERBAIKAN] Binding akan diurus oleh DashboardView, jadi init tidak perlu lagi di sini
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "Ringkasan Keuangan Pimpinan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildKeuanganSekolahCard(),
          // _buildKeuanganKomiteCard(), // Widget ini akan kita rombak total
        ],
      );
    });
  }

  Widget _buildKeuanganSekolahCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.goToLaporanKeuangan,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Keuangan Sekolah (TA Aktif)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 20),
              _buildInfoRow("Total Tunggakan", controller.totalTunggakanSekolah, Colors.red.shade700),
              _buildInfoRow("Total Terbayar", controller.totalTerbayarSekolah.value, Colors.green.shade700),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text("Ketuk untuk melihat rincian >", style: TextStyle(fontSize: 12, color: Get.theme.primaryColor)),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  // [PEROMBAKAN TOTAL UI DI SINI]
  Widget _buildKeuanganKomiteCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: controller.goToLaporanKomite,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text("Kas Komite Sekolah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Text("Saldo Kas Saat Ini", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(controller.saldoKasKomite.value),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              const Text("Transaksi Terbaru:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.logTransaksiKomiteTerbaru.isEmpty) {
                  return const Center(child: Text("Belum ada transaksi."));
                }
                return Column(
                  children: controller.logTransaksiKomiteTerbaru.map((trx) => _buildTransaksiRow(trx)).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  
  Widget _buildTransaksiRow(KomiteLogTransaksiModel trx) {
    bool isPemasukan = trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isPemasukan ? Icons.arrow_circle_down : Icons.arrow_circle_up,
            color: isPemasukan ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trx.sumber ?? trx.tujuan ?? trx.deskripsi ?? 'Transaksi',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${isPemasukan ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.nominal)}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPemasukan ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
}