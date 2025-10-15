// lib/app/modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pemberian_kelas_siswa_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_model.dart';

class PemberianKelasSiswaView extends GetView<PemberianKelasSiswaController> {
  const PemberianKelasSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Kelas Siswa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Obx(() => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.blue.shade50,
            child: Text(
              "Tahun Ajaran Aktif: ${controller.tahunAjaranAktif ?? '...'}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildKelasSelector(),
            const Divider(height: 1),
            Expanded(
              child: Obx(() => controller.kelasTerpilih.value == null
                  ? const Center(child: Text("Pilih atau buat kelas untuk memulai."))
                  : _buildContentArea()),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildKelasSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.daftarKelas.length,
                itemBuilder: (context, index) {
                  final kelasDoc = controller.daftarKelas[index];
                  final namaKelas = (kelasDoc.data() as Map<String, dynamic>)['namaKelas'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Obx(() => ChoiceChip(
                      label: Text(namaKelas),
                      selected: controller.kelasTerpilih.value?.id == kelasDoc.id,
                      onSelected: (_) => controller.pilihKelas(kelasDoc),
                    )),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: controller.showBuatKelasDialog,
              tooltip: "Buat Kelas Baru",
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK KONTEN UTAMA ---
  Widget _buildContentArea() {
    final dataKelas = controller.kelasTerpilih.value!.data() as Map<String, dynamic>;
    final String? namaWaliKelas = dataKelas['waliKelasNama'];
    final bool hasWaliKelas = namaWaliKelas != null && namaWaliKelas.isNotEmpty;

    return Column(
      children: [
        // --- Area Wali Kelas ---
        _buildWaliKelasInfo(namaWaliKelas, hasWaliKelas),
        const Divider(thickness: 4),

        // --- Area Siswa (dengan Tab) ---
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [
                  Tab(text: "Siswa di Kelas Ini"),
                  Tab(text: "Siswa Tanpa Kelas"),
                ]),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSiswaList(isInKelas: true, isEnabled: hasWaliKelas),
                      _buildSiswaList(isInKelas: false, isEnabled: hasWaliKelas),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET BARU UNTUK INFO WALI KELAS ---
  Widget _buildWaliKelasInfo(String? namaWaliKelas, bool hasWaliKelas) {
    return ListTile(
      leading: Icon(Icons.person_pin_rounded, color: hasWaliKelas ? Colors.green : Colors.orange),
      title: Text(hasWaliKelas ? namaWaliKelas! : "Wali Kelas Belum Ditentukan",
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Wali Kelas"),
      trailing: ElevatedButton(
        child: Text(hasWaliKelas ? "Ganti" : "Pilih"),
        onPressed: () => _showPilihWaliKelasDialog(),
      ),
    );
  }

  // --- DIALOG BARU UNTUK MEMILIH WALI KELAS ---
  void _showPilihWaliKelasDialog() {

    controller.searchQueryGuru.value = ''; 

    Get.bottomSheet(
    Container(
      height: Get.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      child: Column(
        children: [
          const Text("Pilih Wali Kelas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          
          // --- TextField Pencarian Reaktif ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              onChanged: (value) => controller.searchQueryGuru.value = value,
              decoration: const InputDecoration(
                  hintText: "Cari nama guru...",
                  prefixIcon: Icon(Icons.search)),
            ),
          ),

          // --- Daftar Guru Reaktif ---
          Expanded(
            child: Obx(() {
              // Filter daftar guru langsung di dalam Obx
              final filteredGuru = controller.daftarGuru.where((guru) {
                  // TAMBAHKAN KONDISI INI
                  final isNotAssigned = !controller.assignedWaliKelasUids.contains(guru.uid);
                  
                  final matchesSearch = guru.nama.toLowerCase().contains(controller.searchQueryGuru.value.toLowerCase());
                  return isNotAssigned && matchesSearch;
              }).toList();
              
              if (filteredGuru.isEmpty) {
                return const Center(child: Text("Guru tidak ditemukan."));
              }
              
              return ListView.builder(
                itemCount: filteredGuru.length,
                itemBuilder: (context, index) {
                  final PegawaiModel guru = filteredGuru[index];
                  final namaTampilan = (guru.alias == null || guru.alias!.isEmpty) ? guru.nama : guru.alias!;
                  return ListTile(
                    // title: Text(guru.nama),
                    title: Text(namaTampilan),
                    subtitle: Text(guru.role?.displayName ?? ''),
                    onTap: () => controller.assignWaliKelas(guru),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSiswaList({required bool isInKelas, required bool isEnabled}) {
    if (!isEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("Tentukan wali kelas terlebih dahulu untuk mengelola siswa.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final listSiswa = isInKelas ? controller.siswaDiKelas : controller.siswaTanpaKelas;
    return Obx(() {
      if (controller.isProcessing.value && listSiswa.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (listSiswa.isEmpty) {
        return Center(child: Text(isInKelas ? "Belum ada siswa di kelas ini." : "Semua siswa sudah punya kelas."));
      }
      return ListView.builder(
        itemCount: listSiswa.length,
        itemBuilder: (context, index) {
          final siswa = listSiswa[index];
          return ListTile(
            title: Text(siswa.namaLengkap),
            subtitle: Text("NISN: ${siswa.nisn}"),
            trailing: IconButton(
              icon: Icon(
                isInKelas ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: isInKelas ? Colors.red : Colors.green,
              ),
              onPressed: () {
                if (isInKelas) {
                  controller.removeSiswaFromKelas(siswa);
                } else {
                  controller.addSiswaToKelas(siswa);
                }
              },
            ),
          );
        },
      );
    });
  }
}