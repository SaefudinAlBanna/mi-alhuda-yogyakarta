import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_simple_model.dart';
import '../controllers/halaqah_ummi_dashboard_koordinator_controller.dart';

class HalaqahUmmiDashboardKoordinatorView extends GetView<HalaqahUmmiDashboardKoordinatorController> {
  const HalaqahUmmiDashboardKoordinatorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Halaqah Ummi"),
        actions: [
        // --- PERUBAHAN DI SINI ---
        Obx(() => controller.isProcessingPdf.value
          ? const Padding(padding: EdgeInsets.all(16.0), 
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
          : IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: controller.exportPdf,
              tooltip: "Cetak Laporan",
            ),
        ),
        // --- AKHIR PERUBAHAN ---
      ],
    ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchDataForDashboard(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilterKelas(),
              const SizedBox(height: 16),
              _buildKpiCards(),
              const SizedBox(height: 24),
              _buildSection(
                title: "Distribusi Progres",
                icon: Icons.bar_chart,
                child: _buildChartAgregat(),
              ),
              _buildSection(
                title: "Siswa Diajukan Ujian",
                icon: Icons.flag,
                child: _buildSiswaDiajukanList(),
              ),
              _buildSection(
                title: "Siswa Tanpa Grup (${controller.siswaTanpaGrup.length})",
                icon: Icons.person_off_outlined,
                child: _buildSiswaList(controller.siswaTanpaGrup, showPengampu: false),
                isWarning: controller.siswaTanpaGrup.isNotEmpty,
              ),
              _buildSection(
                title: "Siswa Progres Lambat (${controller.siswaProgresLambat.length})",
                icon: Icons.hourglass_bottom,
                child: _buildSiswaList(controller.siswaProgresLambat, showPengampu: true),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterKelas() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedKelas.value,
      items: controller.daftarKelas.map((kelas) => DropdownMenuItem(value: kelas, child: Text(kelas))).toList(),
      onChanged: controller.onKelasFilterChanged,
      decoration: const InputDecoration(labelText: "Filter Berdasarkan Kelas", border: OutlineInputBorder()),
    ));
  }

  Widget _buildKpiCards() {
    return Obx(() => Row(
      children: [
        _buildKpiItem("Total Siswa", controller.semuaSiswaDiFilter.length.toString(), Colors.blue),
        _buildKpiItem("Tanpa Grup", controller.siswaTanpaGrup.length.toString(), controller.siswaTanpaGrup.isEmpty ? Colors.green : Colors.red),
        _buildKpiItem("Progres Lambat", controller.siswaProgresLambat.length.toString(), controller.siswaProgresLambat.isEmpty ? Colors.green : Colors.orange),
      ],
    ));
  }

  Widget _buildKpiItem(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartAgregat() {
    return Obx(() {
      if (controller.dataAgregat.isEmpty) return const Text("Tidak ada data progres di filter ini.");
      return Column(
        children: controller.dataAgregat.map((agregat) {
          // Cari semua siswa yang cocok dengan agregat ini
          final siswaDiTingkatIni = controller.semuaSiswaDiFilter
              .where((s) => "${s.progresTingkat} ${s.progresDetail}" == agregat.tingkat)
              .toList();
              
          return ExpansionTile(
            title: Text(agregat.tingkat),
            trailing: Text(
              agregat.jumlahSiswa.toString(),
              style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            children: [
              // Tampilkan daftar nama siswa di dalam ExpansionTile
              _buildSiswaList(siswaDiTingkatIni, showPengampu: true)
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildSiswaList(List<SiswaDashboardModel> siswaList, {required bool showPengampu}) {
    if (siswaList.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Tidak ada data."));
    return Column(
      children: siswaList.map((siswa) {
        String subtitle = "Kelas: ${siswa.kelasId.split('-').first}";
        if (showPengampu) {
          subtitle += " | Pengampu: ${siswa.namaPengampu}";
        }
        if (siswa.tanggalSetoranTerakhir != null) {
           subtitle += "\nTerakhir Setor: ${DateFormat('dd MMM yyyy').format(siswa.tanggalSetoranTerakhir!.toDate())}";
        }
        return ListTile(
          dense: true,
          title: Text(siswa.nama),
          subtitle: Text(subtitle),
        );
      }).toList(),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child, bool isWarning = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isWarning ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      child: ExpansionTile(
        initiallyExpanded: isWarning,
        leading: Icon(icon, color: isWarning ? Colors.red : Get.theme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaDiajukanList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamSiswaDiajukan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Tidak ada siswa yang diajukan ujian."));
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final siswa = SiswaSimpleModel.fromFirestore(doc);
            return ListTile(
              dense: true,
              title: Text(siswa.nama),
              subtitle: Text("Kelas: ${siswa.kelasId.split('-').first}"),
              trailing: ElevatedButton(
                child: const Text("Atur Jadwal"),
                onPressed: () => controller.openSchedulingSheet(siswa),
              ),
            );
          }).toList(),
        );
      },
    );
  }

}