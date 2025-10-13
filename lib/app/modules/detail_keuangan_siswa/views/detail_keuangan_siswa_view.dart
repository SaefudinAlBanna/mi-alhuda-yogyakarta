// lib/app/modules/detail_keuangan_siswa/views/detail_keuangan_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/tagihan_model.dart';
import '../../../models/transaksi_model.dart';
import '../controllers/detail_keuangan_siswa_controller.dart';

class DetailKeuanganSiswaView extends GetView<DetailKeuanganSiswaController> {
  const DetailKeuanganSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: Text(controller.siswa.namaLengkap)),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(controller.siswa.namaLengkap),
          actions: [
            Obx(() => controller.isProcessingPdf.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: controller.exportPdfLaporanSiswa,
                  tooltip: "Cetak Laporan Keuangan Siswa",
                ),
            ),
          ],
          bottom: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabs: controller.tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: Column(
          children: [
            _buildTotalTunggakanCard(),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: controller.tabTitles.map((title) {
                  if (title == "SPP") return _buildSppTab();
                  if (title == "Riwayat") return _buildRiwayatTab();
                  return _buildUmumTab(title);
                }).toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFabs(),
      );
    });
  }

  // ... (widget _buildTotalTunggakanCard, _buildSppTab, _buildSppCard, _buildDividerTunggakan tetap sama) ...
  Widget _buildTotalTunggakanCard() {
    return Obx(() => Card(
      margin: const EdgeInsets.all(16),
      color: controller.totalTunggakan.value > 0 ? Colors.red.shade50 : Colors.green.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total Tunggakan Saat Ini", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "Rp ${NumberFormat.decimalPattern('id_ID').format(controller.totalTunggakan.value)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: controller.totalTunggakan.value > 0 ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    ));
  }


  Widget _buildSppTab() {
    return Obx(() {
      final tunggakan = controller.tagihanSPP.where((t) => t.isTunggakan).toList();
      final reguler = controller.tagihanSPP.where((t) => !t.isTunggakan).toList();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tunggakan.isNotEmpty) ...[
            _buildDividerTunggakan("Tunggakan SPP Tahun Lalu"),
            ...tunggakan.map((tagihan) => _buildSppCard(tagihan)),
            const SizedBox(height: 24),
            _buildDividerTunggakan("Tagihan SPP Tahun Ini"),
          ],
          ...reguler.map((tagihan) => _buildSppCard(tagihan)),
        ],
      );
    });
  }

  Widget _buildSppCard(TagihanModel tagihan) {
    final isLunas = tagihan.status == 'Lunas';
    final isJatuhTempo = !isLunas && tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isBefore(DateTime.now());
    final isSelected = controller.sppBulanTerpilih.contains(tagihan.id);
    
    return Card(
      color: isLunas ? Colors.green.shade50 : (isJatuhTempo ? Colors.red.shade50 : null),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: isLunas ? null : (val) => controller.toggleBulanSpp(tagihan.id),
        title: Text(tagihan.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Sisa: Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.sisaTagihan)}"),
        secondary: Text(
          isLunas ? "LUNAS" : (isJatuhTempo ? "JATUH TEMPO" : "BELUM LUNAS"),
          style: TextStyle(color: isLunas ? Colors.green : (isJatuhTempo ? Colors.red : Colors.orange), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDividerTunggakan(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }

  Widget _buildUmumTab(String jenisPembayaran) {
    final List<TagihanModel> tagihanRelevant;
    final isUangPangkalTab = jenisPembayaran == 'Uang Pangkal';

    if (isUangPangkalTab) {
      tagihanRelevant = controller.tagihanUangPangkal.value != null ? [controller.tagihanUangPangkal.value!] : [];
    } else {
      tagihanRelevant = controller.tagihanLainnya.where((t) => t.jenisPembayaran == jenisPembayaran).toList();
    }
    
    // ... sisa logika tidak berubah
    return ListView(
      padding: const EdgeInsets.all(16),
      children: tagihanRelevant.map((tagihan) => _buildUmumCard(tagihan, isUangPangkal: isUangPangkalTab)).toList(),
    );
  }

  // [PERUBAHAN UTAMA] Widget ini sekarang bisa menampilkan tombol edit
  Widget _buildUmumCard(TagihanModel tagihan, {bool isUangPangkal = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // [BARU] Baris judul dengan tombol edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tagihan.deskripsi,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Tampilkan tombol edit hanya untuk Uang Pangkal dan jika diizinkan
                if (isUangPangkal && controller.isAllowedToModify)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => controller.showDialogEditUangPangkal(tagihan),
                    tooltip: "Edit Nominal Tagihan",
                  ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailRow("Total Tagihan", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTagihan)}"),
            _buildDetailRow("Sudah Dibayar", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTerbayar)}"),
            const Divider(),
            _buildDetailRow("Kekurangan", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.sisaTagihan)}", isTotal: true),
            const SizedBox(height: 16),
            if (tagihan.status != 'Lunas')
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => controller.showDialogPembayaranUmum(tagihan),
                child: const Text("Catat Pembayaran"),
              )
          ],
        ),
      ),
    );
  }

  // ... (sisa widget _buildRiwayatTab, _buildFabs, _buildDetailRow tetap sama)
   Widget _buildRiwayatTab() {
    return Obx(() {
      if (controller.riwayatTransaksi.isEmpty) {
        return const Center(child: Text("Belum ada riwayat pembayaran."));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: controller.riwayatTransaksi.length,
        itemBuilder: (context, index) {
          final trx = controller.riwayatTransaksi[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => controller.showDetailTransaksiDialog(trx),
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trx.keterangan, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      "Dicatat oleh: ${trx.dicatatOlehNama} pada ${DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggalBayar)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.info_outline, color: Colors.blue),
              ),
            ),
          );
        },
      );
    });
  }
  
   Widget _buildFabs() {
    return GetBuilder<DetailKeuanganSiswaController>(
      id: 'fab', 
      builder: (_) {
        if (controller.tabTitles.isEmpty) return const SizedBox.shrink();
        
        final currentTab = controller.tabTitles[controller.tabController.index];

        if (currentTab == "SPP") {
          return Obx(() {
            if (controller.totalSppAkanDibayar.value > 0) {
              return FloatingActionButton.extended(
                onPressed: controller.showDialogPembayaranSpp,
                label: Text("Bayar SPP (Rp ${NumberFormat.decimalPattern('id_ID').format(controller.totalSppAkanDibayar.value)})"),
                icon: const Icon(Icons.payment),
              );
            }
            return const SizedBox.shrink();
          });
        }
        return const SizedBox.shrink();
      }
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
        ],
      ),
    );
  }
}