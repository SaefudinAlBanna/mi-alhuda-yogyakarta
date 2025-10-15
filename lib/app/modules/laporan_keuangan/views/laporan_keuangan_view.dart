import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/rekap_jenis_tagihan_model.dart';
import '../../../models/tagihan_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/laporan_keuangan_controller.dart';

class LaporanKeuanganView extends GetView<LaporanKeuanganController> {
  const LaporanKeuanganView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.change_circle_outlined),
            onPressed: () => Get.toNamed(Routes.LAPORAN_PERUBAHAN_UP),
            tooltip: "Perubahan Uang Pangkal",
          ),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: "Laporan Tahunan"),
            Tab(text: "Laporan Uang Pangkal"),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          controller: controller.tabController,
          children: [
            _buildLaporanTahunan(),
            _buildLaporanUangPangkal(),
          ],
        );
      }),
    );
  }

  Widget _buildLaporanTahunan() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader("Rekapitulasi Tahun Ajaran ${controller.taAktif}", 
          controller.totalTagihanTahunan, controller.totalTerbayarTahunan),
        const SizedBox(height: 24),
        _buildRekapitulasiTahunan(),
      ],
    );
  }

  Widget _buildLaporanUangPangkal() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader("Rekapitulasi Uang Pangkal (Semua Angkatan)", 
          controller.totalTagihanUP, controller.totalTerbayarUP),
        const SizedBox(height: 24),
        _buildRincianUangPangkal(),
      ],
    );
  }

  Widget _buildHeader(String title, RxInt totalTagihan, RxInt totalTerbayar) {
    return Column(
      children: [
        Text(title, style: Get.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTotalCard("Total Tagihan", totalTagihan, Colors.blue),
            const SizedBox(width: 16),
            _buildTotalCard("Total Terbayar", totalTerbayar, Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => _buildTotalCard(
          "Total Tunggakan", 
          (totalTagihan.value - totalTerbayar.value).obs, // Buat RxInt sementara
          Colors.red, 
          isFullWidth: true)
        ),
      ],
    );
  }

  Widget _buildTotalCard(String title, RxInt value, Color color, {bool isFullWidth = false}) {
    final widget = Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Text(
              "Rp ${NumberFormat.decimalPattern('id_ID').format(value.value)}",
              style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            )),
          ],
        ),
      ),
    );
    return isFullWidth ? widget : Expanded(child: widget);
  }

  Widget _buildRekapitulasiTahunan() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Rincian per Jenis Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 30),
              _buildFilterKelas(),
            ],
          ),
        ),
        const Divider(),
        Obx(() => ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.rekapPerJenisTahunan.length,
          itemBuilder: (context, index) {
            final rekap = controller.rekapPerJenisTahunan[index];
            // [GANTI] Panggil widget card baru kita
            return _buildRekapCard(rekap); 
          },
        )),
      ],
    );
  }

  Widget _buildRekapCard(RekapJenisTagihan rekap) {
    final persentase = rekap.totalTagihan > 0 ? rekap.totalTerbayar / rekap.totalTagihan : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.goToRincianTunggakan(rekap), // <-- AKSI KLIK DI SINI
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rekap.jenis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Divider(height: 20),
              
              // Visualisasi Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: persentase,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${(persentase * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rincian Angka
              _buildDetailRow("Total Tagihan", rekap.totalTagihan),
              _buildDetailRow("Sudah Dibayar", rekap.totalTerbayar),
              _buildDetailRow("Tunggakan", rekap.sisa, isHighlight: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterKelas() {
    return Obx(() => DropdownButton<String>(
      value: controller.kelasTerpilih.value,
      items: controller.daftarKelasFilter.map((kelas) => DropdownMenuItem(
        value: kelas, child: Text(kelas),
      )).toList(),
      onChanged: (value) {
        if (value != null) controller.kelasTerpilih.value = value;
      },
    ));
  }

  Widget _buildRincianUangPangkal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rincian per Siswa (Belum Lunas)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        Obx(() {
          final belumLunas = controller.rincianUangPangkal.where((t) => t.status != 'Lunas').toList();
          if (belumLunas.isEmpty) return const Center(child: Text("Semua Uang Pangkal sudah lunas."));
          
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: belumLunas.length,
            itemBuilder: (context, index) {
              final tagihan = belumLunas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  // title: Text(tagihan.id.split('-').last), // Asumsi nama siswa ada di ID
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tagihan.namaSiswa != null ? tagihan.namaSiswa!.split('-').last : ''),
                        Text("Kelas: ${tagihan.kelasSaatDitagih?.split('-').first ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                      ],
                    ),
                  ), // Asumsi nama siswa ada di ID
                  subtitle: Text("Sisa: Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.sisaTagihan)}"),
                  trailing: Text(tagihan.status, style: TextStyle(color: Colors.red)),
                ),
              );
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildDetailRow(String title, int value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "Rp ${NumberFormat.decimalPattern('id_ID').format(value)}",
            style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: isHighlight ? Colors.red : null),
          ),
        ],
      ),
    );
  }
}