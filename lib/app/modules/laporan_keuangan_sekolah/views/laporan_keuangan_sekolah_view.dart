// lib/app/modules/laporan_keuangan_sekolah/views/laporan_keuangan_sekolah_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../routes/app_pages.dart';
import '../controllers/laporan_keuangan_sekolah_controller.dart';

class LaporanKeuanganSekolahView extends StatefulWidget {
  const LaporanKeuanganSekolahView({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganSekolahView> createState() => _LaporanKeuanganSekolahViewState();
}

class _LaporanKeuanganSekolahViewState extends State<LaporanKeuanganSekolahView> with SingleTickerProviderStateMixin {
  final LaporanKeuanganSekolahController controller = Get.find();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan Sekolah'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Obx(() => controller.isExporting.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.print_rounded)),
            onPressed: controller.exportToPdf,
            tooltip: "Cetak Laporan",
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'filter') controller.showFilterDialog();
              // [TAMBAHKAN KONDISI BARU INI]
              if (value == 'anggaran') {
                if (controller.tahunTerpilih.value != null) {
                  Get.toNamed(Routes.MANAJEMEN_ANGGARAN, arguments: controller.tahunTerpilih.value);
                } else {
                  Get.snackbar("Peringatan", "Silakan pilih tahun anggaran terlebih dahulu.");
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(leading: Icon(Icons.filter_list_rounded), title: Text('Filter Laporan')),
              ),
              // [TAMBAHKAN MENU BARU INI]
              const PopupMenuItem<String>(
                value: 'anggaran',
                child: ListTile(leading: Icon(Icons.assignment_rounded), title: Text('Atur Anggaran Tahunan')),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: "Buku Besar"),
            Tab(icon: Icon(Icons.pie_chart_rounded), text: "Analisis Grafik"),
            Tab(icon: Icon(Icons.assessment_rounded), text: "Anggaran"),
          ],
        ),
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardContent(),
                        _buildGrafikContent(),
                        _buildAnggaranContent(), // [BARU] Tampilan Anggaran
                      ],
                    ),
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

  Widget _buildAnggaranContent() {
    return Obx(() {
      if (controller.analisisAnggaran.isEmpty) {
        return const Center(
          child: Text("Anggaran untuk tahun ini belum diatur.\nSilakan atur melalui menu di pojok kanan atas.", textAlign: TextAlign.center),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: controller.analisisAnggaran.map((data) => _buildAnggaranCard(data)).toList(),
      );
    });
  }

  Widget _buildAnggaranCard(Map<String, dynamic> data) {
    final String kategori = data['kategori'];
    final int anggaran = data['anggaran'];
    final double realisasi = data['realisasi'];
    final double sisa = anggaran - realisasi;
    final double persentase = anggaran > 0 ? realisasi / anggaran : 0.0;

    Color progressBarColor;
    if (persentase < 0.5) {
      progressBarColor = Colors.green;
    } else if (persentase < 0.9) {
      progressBarColor = Colors.orange;
    } else {
      progressBarColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kategori, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: persentase,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(persentase * 100).toStringAsFixed(1)}%",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: progressBarColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rincian Angka
            _buildAnggaranDetailRow("Realisasi", realisasi),
            _buildAnggaranDetailRow("Anggaran", anggaran.toDouble()),
            const Divider(),
            _buildAnggaranDetailRow("Sisa", sisa, isSisa: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAnggaranDetailRow(String title, double value, {bool isSisa = false}) {
    final isMinus = isSisa && value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            (isMinus ? "- " : "") + controller.formatRupiah(value.abs()),
            style: TextStyle(
              fontWeight: isSisa ? FontWeight.bold : FontWeight.normal, 
              color: isSisa ? (isMinus ? Colors.red : Colors.green) : null,
            ),
          ),
        ],
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

  Widget _buildTransactionList() {
    return Obx(() {
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
        itemCount: controller.daftarTransaksiTampil.value.length,
        itemBuilder: (context, index) {
          final trx = controller.daftarTransaksiTampil.value[index];
          final jenis = trx['jenis'] ?? '';
          final date = (trx['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
          final urlBukti = trx['urlBuktiTransaksi'] as String?;
          
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
          } else {
            icon = Icons.swap_horiz_rounded;
            color = Colors.blue;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => _showDetailTransaksiDialog(trx), // Panggil dialog detail
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(trx['keterangan'] ?? 'Tanpa Keterangan', maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lapis 1: Indikator & Akses Cepat
                  if (urlBukti != null && urlBukti.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.receipt_long, color: Colors.grey.shade600),
                      onPressed: () => _launchURL(urlBukti),
                      tooltip: "Lihat Bukti Transaksi",
                    ),
                  Text(
                    "$prefix ${controller.formatRupiah(trx['jumlah'])}",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showDetailTransaksiDialog(Map<String, dynamic> trx) {
    final jumlah = trx['jumlah'] ?? 0;
    final tanggal = (trx['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
    final keterangan = trx['keterangan'] ?? 'N/A';
    final pencatat = trx['diinputOlehNama'] ?? 'N/A';
    final jenis = trx['jenis'] ?? 'N/A';
    final urlBukti = trx['urlBuktiTransaksi'] as String?;

    Get.defaultDialog(
      title: "Detail Transaksi",
      content: SingleChildScrollView( // Bungkus dengan SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Jenis", jenis),
            _buildDetailRow("Jumlah", controller.formatRupiah(jumlah)),
            _buildDetailRow("Tanggal", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tanggal)),
            _buildDetailRow("Keterangan", keterangan),
            _buildDetailRow("Dicatat oleh", pencatat),
            
            // Lapis 2: Thumbnail & Akses Detail di Dialog
            if (urlBukti != null && urlBukti.isNotEmpty) ...[
              const Divider(height: 24),
              const Text("Bukti Transaksi:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: Image.network(
                  urlBukti,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Lihat Ukuran Penuh"),
                  onPressed: () => _launchURL(urlBukti),
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Tutup")),
        if (jenis != 'Transfer' && jenis != 'Transfer Masuk' && jenis != 'Transfer Keluar')
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.showKoreksiDialog(trx); // Ubah nama fungsi panggil
            },
            child: const Text("Buat Koreksi"),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
          const Text(": "),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Tidak dapat membuka URL: $url");
    }
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

  Widget _buildGrafikContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBarChartCard(),
        const SizedBox(height: 24),
        _buildPieChartCard(),
      ],
    );
  }

  Widget _buildBarChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Arus Kas Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Pemasukan vs Pengeluaran (Non-Transfer)", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Obx(() => BarChart(_buildBarChartData())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Distribusi Pengeluaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Berdasarkan Kategori", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220, // Tambah tinggi untuk radius yang lebih besar
              child: Obx(() => PieChart(_buildPieChartData())),
            ),
            const SizedBox(height: 16),
            Obx(() => _buildPieChartIndicators()),
          ],
        ),
      ),
    );
  }

  // --- [UPGRADE] Logika Builder untuk Grafik ---

  BarChartData _buildBarChartData() {
    final data = controller.dataGrafikBulanan.value;
    return BarChartData(
      // [PERBAIKAN KUNCI] Bungkus properti tooltip di dalam BarTouchTooltipData
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final jenis = rod.color == Colors.green ? 'Pemasukan' : 'Pengeluaran';
            // Gunakan format Rupiah biasa untuk tooltip agar lebih jelas
            final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
            return BarTooltipItem(
              '$jenis\n',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              children: <TextSpan>[
                TextSpan(
                  text: formatter.format(rod.toY),
                  style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
      maxY: _calculateMaxY(data),
      barGroups: data.entries.map((entry) {
        final bulan = entry.key;
        final values = entry.value;
        return BarChartGroupData(
          x: bulan,
          barRods: [
            BarChartRodData(toY: values['pemasukan']!, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: values['pengeluaran']!, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getBulanTitles, reservedSize: 28)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: _getYTitles)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000000),
    );
  }
  
  PieChartData _buildPieChartData() {
    final data = controller.dataDistribusiPengeluaran.value;
    final List<PieChartSectionData> sections = [];
    int i = 0;
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber, Colors.cyan];
    final total = data.values.fold(0.0, (prev, e) => prev + e);
    
    if (data.isEmpty) {
      return PieChartData(sections: [
        PieChartSectionData(value: 1, color: Colors.grey.shade300, title: "Data Kosong", radius: 100, titleStyle: const TextStyle(fontSize: 14, color: Colors.black))
      ]);
    }

    data.forEach((kategori, jumlah) {
      final percentage = total > 0 ? (jumlah / total * 100) : 0.0;
      sections.add(PieChartSectionData(
        value: jumlah,
        // [UPGRADE] Tampilkan persentase di dalam chart
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        color: colors[i % colors.length],
        radius: 100, // Perbesar radius agar lebih jelas
      ));
      i++;
    });

    return PieChartData(sections: sections, centerSpaceRadius: 0);
  }

  Widget _buildPieChartIndicators() {
    final data = controller.dataDistribusiPengeluaran.value;
    int i = 0;
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
    final total = data.values.fold(0.0, (prev, e) => prev + e);

    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      children: data.entries.map((entry) {
        final color = colors[i % colors.length];
        i++;
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : "0.0";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Text("${entry.key} ($percentage%)"),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // --- [BARU] Helper untuk Grafik ---

  double _calculateMaxY(Map<int, Map<String, double>> data) {
    double maxVal = 0;
    data.values.forEach((val) {
      if (val['pemasukan']! > maxVal) maxVal = val['pemasukan']!;
      if (val['pengeluaran']! > maxVal) maxVal = val['pengeluaran']!;
    });
    return maxVal * 1.2; // Beri sedikit ruang di atas
  }

  Widget _getBulanTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text;
    switch (value.toInt()) {
      case 1: text = 'Jan'; break; case 2: text = 'Feb'; break;
      case 3: text = 'Mar'; break; case 4: text = 'Apr'; break;
      case 5: text = 'Mei'; break; case 6: text = 'Jun'; break;
      case 7: text = 'Jul'; break; case 8: text = 'Agu'; break;
      case 9: text = 'Sep'; break; case 10: text = 'Okt'; break;
      case 11: text = 'Nov'; break; case 12: text = 'Des'; break;
      default: text = '';
    }
    // [PERBAIKAN] Tambahkan kembali 'axisSide'
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  // [VERSI FINAL DEFINTIF UNTUK fl_chart: ^0.66.2]
  Widget _getYTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    if (value == 0) return const SizedBox.shrink();
    // [PERBAIKAN] Tambahkan kembali 'axisSide'
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text("${(value / 1000000).toStringAsFixed(1)} Jt", style: style),
    );
  }
}


// // lib/app/modules/laporan_keuangan_sekolah/views/laporan_keuangan_sekolah_view.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../controllers/laporan_keuangan_sekolah_controller.dart';
// import '../../../widgets/number_input_formatter.dart'; // Pastikan import ini benar

// class LaporanKeuanganSekolahView extends StatefulWidget {
//   const LaporanKeuanganSekolahView({Key? key}) : super(key: key);

//   @override
//   State<LaporanKeuanganSekolahView> createState() => _LaporanKeuanganSekolahViewState();
// }

// class _LaporanKeuanganSekolahViewState extends State<LaporanKeuanganSekolahView> with SingleTickerProviderStateMixin {
//   final LaporanKeuanganSekolahController controller = Get.find();
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Laporan Keuangan Sekolah'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Obx(() => controller.isExporting.value 
//               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
//               : const Icon(Icons.print_rounded)),
//             onPressed: controller.exportToPdf,
//             tooltip: "Cetak Laporan",
//           ),
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'filter') controller.showFilterDialog();
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(
//                 value: 'filter',
//                 child: ListTile(leading: Icon(Icons.filter_list_rounded), title: Text('Filter Laporan')),
//               ),
//             ],
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(icon: Icon(Icons.list_alt_rounded), text: "Buku Besar"),
//             Tab(icon: Icon(Icons.pie_chart_rounded), text: "Analisis Grafik"),
//           ],
//         ),
//       ),
//       body: Obx(() {
//         if (controller.daftarTahunAnggaran.isEmpty && !controller.isLoading.value) {
//           return const Center(child: Text("Belum ada data keuangan yang tercatat."));
//         }
//         return Column(
//           children: [
//             _buildYearSelector(),
//             Expanded(
//               child: controller.isLoading.value
//                   ? const Center(child: CircularProgressIndicator())
//                   : TabBarView(
//                       controller: _tabController,
//                       children: [
//                         _buildDashboardContent(),
//                         _buildGrafikContent(),
//                       ],
//                     ),
//             ),
//           ],
//         );
//       }),
//       floatingActionButton: FloatingActionButton(
//         onPressed: controller.showPilihanTransaksiDialog,
//         child: const Icon(Icons.add),
//         tooltip: "Tambah Transaksi",
//       ),
//     );
//   }

//   Widget _buildGrafikContent() {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         _buildBarChartCard(),
//         const SizedBox(height: 24),
//         _buildPieChartCard(),
//       ],
//     );
//   }

//   Widget _buildBarChartCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Arus Kas Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const Text("Pemasukan vs Pengeluaran (Non-Transfer)", style: TextStyle(color: Colors.grey)),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 250,
//               child: Obx(() => BarChart(_buildBarChartData())),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPieChartCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Distribusi Pengeluaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const Text("Berdasarkan Kategori", style: TextStyle(color: Colors.grey)),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: Obx(() => PieChart(_buildPieChartData())),
//             ),
//             const SizedBox(height: 16),
//             Obx(() => _buildPieChartIndicators()),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- [BARU] Logika Builder untuk Grafik ---

//   BarChartData _buildBarChartData() {
//     final data = controller.dataGrafikBulanan.value;
//     return BarChartData(
//       maxY: _calculateMaxY(data),
//       barGroups: data.entries.map((entry) {
//         final bulan = entry.key;
//         final values = entry.value;
//         return BarChartGroupData(
//           x: bulan,
//           barRods: [
//             BarChartRodData(toY: values['pemasukan']!, color: Colors.green, width: 12),
//             BarChartRodData(toY: values['pengeluaran']!, color: Colors.red, width: 12),
//           ],
//         );
//       }).toList(),
//       titlesData: FlTitlesData(
//         bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getBulanTitles)),
//         leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _getYTitles)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       ),
//       borderData: FlBorderData(show: false),
//       gridData: const FlGridData(show: true, drawVerticalLine: false),
//     );
//   }
  
//   PieChartData _buildPieChartData() {
//     final data = controller.dataDistribusiPengeluaran.value;
//     final List<PieChartSectionData> sections = [];
//     int i = 0;
//     final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
    
//     if (data.isEmpty) {
//       return PieChartData(sections: [
//         PieChartSectionData(value: 1, color: Colors.grey.shade300, title: "Data Kosong", radius: 80, titleStyle: const TextStyle(fontSize: 12, color: Colors.black))
//       ]);
//     }

//     data.forEach((kategori, jumlah) {
//       sections.add(PieChartSectionData(
//         value: jumlah,
//         title: '', // Judul diindikatorkan di luar
//         color: colors[i % colors.length],
//         radius: 80,
//       ));
//       i++;
//     });

//     return PieChartData(sections: sections, centerSpaceRadius: 0);
//   }

//   Widget _buildPieChartIndicators() {
//     final data = controller.dataDistribusiPengeluaran.value;
//     int i = 0;
//     final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
//     final total = data.values.fold(0.0, (prev, e) => prev + e);

//     if (data.isEmpty) return const SizedBox.shrink();

//     return Column(
//       children: data.entries.map((entry) {
//         final color = colors[i % colors.length];
//         i++;
//         final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : "0.0";
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2.0),
//           child: Row(
//             children: [
//               Container(width: 16, height: 16, color: color),
//               const SizedBox(width: 8),
//               Text("${entry.key} ($percentage%)"),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
  
//   // --- [BARU] Helper untuk Grafik ---

//   double _calculateMaxY(Map<int, Map<String, double>> data) {
//     double maxVal = 0;
//     data.values.forEach((val) {
//       if (val['pemasukan']! > maxVal) maxVal = val['pemasukan']!;
//       if (val['pengeluaran']! > maxVal) maxVal = val['pengeluaran']!;
//     });
//     return maxVal * 1.2; // Beri sedikit ruang di atas
//   }

//   Widget _buildYearSelector() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: DropdownButtonFormField<String>(
//         value: controller.tahunTerpilih.value,
//         hint: const Text("Pilih Tahun Anggaran"),
//         items: controller.daftarTahunAnggaran.map((tahun) {
//           return DropdownMenuItem(value: tahun, child: Text("Tahun Anggaran $tahun"));
//         }).toList(),
//         onChanged: (value) {
//           if (value != null) controller.pilihTahun(value);
//         },
//         decoration: const InputDecoration(border: OutlineInputBorder()),
//       ),
//     );
//   }

//   Widget _buildDashboardContent() {
//     return RefreshIndicator(
//       onRefresh: () => controller.pilihTahun(controller.tahunTerpilih.value!),
//       child: ListView(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: [
//           _buildSummaryCards(),
//           const SizedBox(height: 24),
//           // [BARU] Indikator filter aktif
//           Obx(() => Visibility(
//             visible: controller.isFilterActive,
//             child: _buildFilterIndicator(),
//           )),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text("Buku Besar Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               Obx(() => Text("${controller.daftarTransaksiTampil.value.length} item", style: Get.textTheme.bodySmall)),
//             ],
//           ),
//           const Divider(),
//           _buildTransactionList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterIndicator() {
//     return Container(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         children: [
//           if (controller.filterBulanTahun.value != null)
//             Chip(
//               label: Text(DateFormat.yMMMM('id_ID').format(controller.filterBulanTahun.value!)),
//               onDeleted: () => controller.filterBulanTahun.value = null,
//             ),
//           if (controller.filterJenis.value != null)
//             Chip(
//               label: Text(controller.filterJenis.value!),
//               onDeleted: () => controller.filterJenis.value = null,
//             ),
//           if (controller.filterKategori.value != null)
//             Chip(
//               label: Text(controller.filterKategori.value!),
//               onDeleted: () => controller.filterKategori.value = null,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCards() {
//     return Obx(() {
//       final summary = controller.summaryData;
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1.5,
//         children: [
//           _buildSummaryCard("Total Pemasukan", controller.formatRupiah(summary['totalPemasukan']), Colors.green),
//           _buildSummaryCard("Total Pengeluaran", controller.formatRupiah(summary['totalPengeluaran']), Colors.red),
//           _buildSummaryCard("Saldo Kas Tunai", controller.formatRupiah(summary['saldoKasTunai']), Colors.blue),
//           _buildSummaryCard("Saldo di Bank", controller.formatRupiah(summary['saldoBank']), Colors.orange),
//         ],
//       );
//     });
//   }

//   Widget _buildSummaryCard(String title, String value, MaterialColor color) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: color.shade50,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(title, style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
//             const Spacer(),
//             FittedBox(
//               fit: BoxFit.scaleDown,
//               child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTransactionList() {
//     return Obx(() {
//       if (controller.daftarTransaksiTampil.value.isEmpty) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 40.0),
//           child: Center(child: Text(
//             controller.isFilterActive 
//               ? "Tidak ada transaksi yang cocok dengan filter." 
//               : "Belum ada transaksi di tahun ini."
//           )),
//         );
//       }
//       return ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: controller.daftarTransaksiTampil.value.length,
//         itemBuilder: (context, index) {
//           final trx = controller.daftarTransaksiTampil.value[index];
//           final jenis = trx['jenis'] ?? '';
//           final date = (trx['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
//           final urlBukti = trx['urlBuktiTransaksi'] as String?;
          
//           IconData icon;
//           Color color;
//           String prefix = "";

//           if (jenis == 'Pemasukan') {
//             icon = Icons.arrow_downward_rounded;
//             color = Colors.green;
//             prefix = "+";
//           } else if (jenis == 'Pengeluaran') {
//             icon = Icons.arrow_upward_rounded;
//             color = Colors.red;
//             prefix = "-";
//           } else {
//             icon = Icons.swap_horiz_rounded;
//             color = Colors.blue;
//           }

//           return Card(
//             margin: const EdgeInsets.only(bottom: 8),
//             clipBehavior: Clip.antiAlias,
//             child: ListTile(
//               onTap: () => _showDetailTransaksiDialog(trx), // Panggil dialog detail
//               leading: CircleAvatar(
//                 backgroundColor: color.withOpacity(0.1),
//                 child: Icon(icon, color: color),
//               ),
//               title: Text(trx['keterangan'] ?? 'Tanpa Keterangan', maxLines: 2, overflow: TextOverflow.ellipsis),
//               subtitle: Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Lapis 1: Indikator & Akses Cepat
//                   if (urlBukti != null && urlBukti.isNotEmpty)
//                     IconButton(
//                       icon: Icon(Icons.receipt_long, color: Colors.grey.shade600),
//                       onPressed: () => _launchURL(urlBukti),
//                       tooltip: "Lihat Bukti Transaksi",
//                     ),
//                   Text(
//                     "$prefix ${controller.formatRupiah(trx['jumlah'])}",
//                     style: TextStyle(color: color, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     });
//   }

//   // [BARU] Fungsi untuk menampilkan dialog detail yang sudah disempurnakan
//   void _showDetailTransaksiDialog(Map<String, dynamic> trx) {
//     final jumlah = trx['jumlah'] ?? 0;
//     final tanggal = (trx['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
//     final keterangan = trx['keterangan'] ?? 'N/A';
//     final pencatat = trx['diinputOlehNama'] ?? 'N/A';
//     final jenis = trx['jenis'] ?? 'N/A';
//     final urlBukti = trx['urlBuktiTransaksi'] as String?;

//     Get.defaultDialog(
//       title: "Detail Transaksi",
//       content: SingleChildScrollView( // Bungkus dengan SingleChildScrollView
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow("Jenis", jenis),
//             _buildDetailRow("Jumlah", controller.formatRupiah(jumlah)),
//             _buildDetailRow("Tanggal", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tanggal)),
//             _buildDetailRow("Keterangan", keterangan),
//             _buildDetailRow("Dicatat oleh", pencatat),
            
//             // Lapis 2: Thumbnail & Akses Detail di Dialog
//             if (urlBukti != null && urlBukti.isNotEmpty) ...[
//               const Divider(height: 24),
//               const Text("Bukti Transaksi:", style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Center(
//                 child: Image.network(
//                   urlBukti,
//                   height: 150,
//                   fit: BoxFit.cover,
//                   loadingBuilder: (context, child, loadingProgress) {
//                     if (loadingProgress == null) return child;
//                     return const Center(child: CircularProgressIndicator());
//                   },
//                   errorBuilder: (context, error, stackTrace) {
//                     return const Icon(Icons.error, color: Colors.red);
//                   },
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Center(
//                 child: OutlinedButton.icon(
//                   icon: const Icon(Icons.open_in_new),
//                   label: const Text("Lihat Ukuran Penuh"),
//                   onPressed: () => _launchURL(urlBukti),
//                 ),
//               )
//             ]
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(onPressed: Get.back, child: const Text("Tutup")),
//         if (jenis != 'Transfer' && jenis != 'Transfer Masuk' && jenis != 'Transfer Keluar')
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               controller.showKoreksiDialog(trx); // Ubah nama fungsi panggil
//             },
//             child: const Text("Buat Koreksi"),
//           ),
//       ],
//     );
//   }

//   // [BARU] Helper untuk baris detail agar rapi
//   Widget _buildDetailRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(width: 80, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
//           const Text(": "),
//           Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
//         ],
//       ),
//     );
//   }

//   // [BARU] Helper untuk membuka URL
//   Future<void> _launchURL(String url) async {
//     final uri = Uri.parse(url);
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       Get.snackbar("Error", "Tidak dapat membuka URL: $url");
//     }
//   }

//   // [VERSI FINAL DEFINTIF UNTUK fl_chart: ^0.66.2]
//   Widget _getBulanTitles(double value, TitleMeta meta) {
//     const style = TextStyle(fontSize: 10);
//     String text;
//     switch (value.toInt()) {
//       case 1: text = 'Jan'; break; case 2: text = 'Feb'; break;
//       case 3: text = 'Mar'; break; case 4: text = 'Apr'; break;
//       case 5: text = 'Mei'; break; case 6: text = 'Jun'; break;
//       case 7: text = 'Jul'; break; case 8: text = 'Agu'; break;
//       case 9: text = 'Sep'; break; case 10: text = 'Okt'; break;
//       case 11: text = 'Nov'; break; case 12: text = 'Des'; break;
//       default: text = '';
//     }
//     // [PERBAIKAN] Tambahkan kembali 'axisSide'
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 4,
//       child: Text(text, style: style),
//     );
//   }

//   // [VERSI FINAL DEFINTIF UNTUK fl_chart: ^0.66.2]
//   Widget _getYTitles(double value, TitleMeta meta) {
//     const style = TextStyle(fontSize: 10);
//     if (value == 0) return const SizedBox.shrink();
//     // [PERBAIKAN] Tambahkan kembali 'axisSide'
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 4,
//       child: Text("${(value / 1000000).toStringAsFixed(1)} Jt", style: style),
//     );
//   }
// }