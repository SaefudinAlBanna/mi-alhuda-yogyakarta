import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/santri_halaqah_laporan_model.dart';
import '../controllers/laporan_halaqah_controller.dart';

class LaporanHalaqahView extends GetView<LaporanHalaqahController> {
  const LaporanHalaqahView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Halaqah (Pantau)")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarGrup.isEmpty) {
          return const Center(child: Text("Belum ada grup Halaqah yang dibentuk."));
        }
        return Column(
          children: [
            _buildGroupSelector(),
            _buildInfoKontekstual(),
            Expanded(child: _buildDetailContent()),
          ],
        );
      }),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.daftarGrup.length,
        itemBuilder: (context, index) {
          final grup = controller.daftarGrup[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() => ChoiceChip(
                  label: Text(grup['namaGrup']),
                  selected: controller.grupTerpilih.value?['id'] == grup['id'],
                  onSelected: (_) => controller.onGrupChanged(grup),
                  selectedColor: Colors.teal.shade700,
                  labelStyle: TextStyle(
                      color: controller.grupTerpilih.value?['id'] == grup['id']
                          ? Colors.white
                          : Colors.black),
                )),
          );
        },
      ),
    );
  }

  Widget _buildInfoKontekstual() {
    return Obx(() {
      if (controller.grupTerpilih.value == null) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoItem("Pengampu", controller.infoPengampu.value),
              _infoItem("Jumlah Santri", "${controller.santriDiGrup.length} Santri"),
              _infoItem("Total Setoran Bulan Ini", controller.totalSetoranGrupBulanIni.value.toString()),
            ],
          ),
        ),
      );
    });
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDetailContent() {
    return Obx(() {
      if (controller.grupTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih grup untuk melihat laporan."));
      }
      if (controller.isDetailLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          TabBar(
            controller: controller.tabController,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Progres Santri"),
              Tab(text: "Statistik Grup"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildProgresSantriTab(),
                const Center(child: Text("Fitur Statistik Grup akan dikembangkan.")),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProgresSantriTab() {
    if (controller.santriDiGrup.isEmpty) {
      return const Center(child: Text("Belum ada santri di grup ini."));
    }
    return ListView.builder(
      itemCount: controller.santriDiGrup.length,
      itemBuilder: (context, index) {
        final santri = controller.santriDiGrup[index];
        return ListTile(
          leading: CircleAvatar(child: Text("${index + 1}")),
          title: Text(santri.nama),
          subtitle: Text("Setoran terakhir: ${santri.setoranTerakhir}"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${santri.totalSetoranBulanIni}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("Setoran", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}