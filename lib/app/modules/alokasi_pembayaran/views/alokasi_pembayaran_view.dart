import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/alokasi_pembayaran_controller.dart';
// [PENTING] Kita akan import NumberInputFormatter di Langkah 5
import '../../../widgets/number_input_formatter.dart'; 

class AlokasiPembayaranView extends GetView<AlokasiPembayaranController> {
  const AlokasiPembayaranView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alokasi Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if(controller.currentPage.value == 1) {
              controller.backToNominalPage();
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildNominalInputPage(),
          _buildAllocationPage(),
        ],
      ),
    );
  }

  Widget _buildNominalInputPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Siswa: ${controller.siswa.namaLengkap}", style: Get.textTheme.titleLarge),
          const SizedBox(height: 30),
          Text("Masukkan jumlah total uang yang diterima dari orang tua/wali:", textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            controller: controller.totalDiterimaC,
            keyboardType: TextInputType.number,
            inputFormatters: [NumberInputFormatter()], // <-- Terapkan formatter
            decoration: const InputDecoration(
              labelText: "Jumlah Diterima",
              prefixText: "Rp ",
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: controller.goToAllocationPage,
            child: const Text("Lanjutkan ke Alokasi"),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationPage() {
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.itemsToAllocate.length,
            itemBuilder: (context, index) {
              final item = controller.itemsToAllocate[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.tagihan.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Sisa Tagihan: Rp ${NumberFormat.decimalPattern('id_ID').format(item.tagihan.sisaTagihan)}"),
                      const SizedBox(height: 8),
                      Obx(() => TextField(
                        controller: item.controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [NumberInputFormatter()],
                        decoration: InputDecoration(
                          labelText: "Jumlah Alokasi",
                          prefixText: "Rp ",
                          border: const OutlineInputBorder(),
                          // Tampilkan pesan error jika ada
                          errorText: item.sppValidationError.value, 
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle),
                            tooltip: "Alokasikan Sesuai Sisa Tagihan",
                            onPressed: (){
                              item.controller.text = NumberFormat.decimalPattern('id_ID').format(item.tagihan.sisaTagihan);
                            },
                          )
                        ),
                      )),
                    ],
                  ),
                ),
              );
            },
          )),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: controller.isSaving.value ? null : controller.prosesAlokasiPembayaran,
            child: controller.isSaving.value 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Simpan Semua Pembayaran"),
          )),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => Column(
          children: [
             _summaryRow("Dana Diterima:", controller.totalDiterima.value),
             _summaryRow("Total Dialokasikan:", controller.totalDialokasikan.value, isNegative: true),
             const Divider(),
             _summaryRow("Sisa Dana:", controller.sisaUntukAlokasi.value, isTotal: true),
          ],
        )),
      ),
    );
  }

  Widget _summaryRow(String title, int value, {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            "${isNegative ? '-' : ''}Rp ${NumberFormat.decimalPattern('id_ID').format(value)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal && value < 0 ? Colors.red : (isTotal ? Colors.green.shade800 : null),
            ),
          ),
        ],
      ),
    );
  }
}