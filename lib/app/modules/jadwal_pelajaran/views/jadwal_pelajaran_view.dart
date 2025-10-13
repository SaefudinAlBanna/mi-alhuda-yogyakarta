import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/jadwal_pelajaran_controller.dart';

class JadwalPelajaranView extends GetView<JadwalPelajaranController> {
  const JadwalPelajaranView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Jadwal Pelajaran', style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold)),
        ),
        elevation: 0,
        backgroundColor: Colors.grey.shade300,
        actions: [
          if (controller.dashC.isPimpinan)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: "Editor Jadwal",
            onSelected: (value) {
              if (value == 'Atur_JP') {Get.toNamed(Routes.MASTER_JAM);}
              if (value == 'penugasan') {Get.toNamed(Routes.PENUGASAN_GURU);}
              if (value == 'Master_Mapel') {Get.toNamed(Routes.MASTER_MAPEL);}
              if (value == 'Edit_Jadwal') {Get.toNamed(Routes.EDITOR_JADWAL);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Atur_JP', child: ListTile(leading: Icon(Icons.timer_sharp), title: Text("Atur JP"))),
              const PopupMenuItem(value: 'penugasan', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("penugasan"))),
              const PopupMenuItem(value: 'Master_Mapel', child: ListTile(leading: Icon(Icons.bookmark_add_outlined), title: Text("Master Mapel"))),
              const PopupMenuItem(value: 'Edit_Jadwal', child: ListTile(leading: Icon(Icons.schedule_sharp), title: Text("Edit Jadwal"))),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarKelas.isEmpty) {
          return const Center(child: Text("Tidak ada kelas yang terdaftar di tahun ajaran ini."));
        }
        return Column(
          children: [
            _buildKelasSelector(),
            _buildHariTabBar(),
            Expanded(child: _buildJadwalContent()),
          ],
        );
      }),
    );
  }

  // Widget untuk Dropdown pemilih kelas
  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade300,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: controller.selectedKelasId.value,
              hint: const Text("Pilih Kelas..."),
              items: controller.daftarKelas.map((kelas) {
                return DropdownMenuItem<String>(
                  value: kelas['id'],
                  child: Text(kelas['nama']),
                );
              }).toList(),
              onChanged: controller.onKelasChanged,
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk Tab hari
  Widget _buildHariTabBar() {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: TabBar(
        controller: controller.tabController,
        isScrollable: true,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.indigo,
        indicatorWeight: 3,
        tabs: controller.daftarHari.map((hari) => Tab(text: hari)).toList(),
      ),
    );
  }

  // Widget untuk menampilkan konten jadwal
  Widget _buildJadwalContent() {
    return Obx(() {
      if (controller.isLoadingJadwal.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.selectedKelasId.value == null) {
        return const Center(child: Text("Silakan pilih kelas untuk melihat jadwal.", 
        style: TextStyle(color: Colors.grey)));
      }
      return TabBarView(
        controller: controller.tabController,
        children: controller.daftarHari.map((hari) {
          final jadwalHari = controller.jadwalPelajaran[hari] ?? [];
          if (jadwalHari.isEmpty) {
            return const Center(child: Text("Tidak ada jadwal untuk hari ini."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jadwalHari.length,
            itemBuilder: (context, index) {
              final pelajaran = jadwalHari[index];
              return _JadwalCard(pelajaran: pelajaran);
            },
          );
        }).toList(),
      );
    });
  }
}

// Widget untuk setiap kartu jadwal
class _JadwalCard extends StatelessWidget {
  final Map<String, dynamic> pelajaran;
  const _JadwalCard({required this.pelajaran});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: Colors.indigo, size: 28),
                const SizedBox(height: 4),
                Text(
                  pelajaran['jam'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pelajaran['namaMapel'] ?? 'Mata Pelajaran Belum Diatur',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pelajaran['namaGuru'] ?? 'Guru Belum Diatur',
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}