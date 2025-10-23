import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_siswa_controller.dart';

class DaftarSiswaView extends GetView<DaftarSiswaController> {
  const DaftarSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Siswa'),
        actions: [
          if (controller.canManageSiswa)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Import dari Excel',
              onPressed: controller.goToImportSiswa,
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            // --- PANEL KONTROL (FILTER & PENCARIAN) ---
            _buildControlPanel(),
            
            // --- DAFTAR SISWA ---
            Expanded(
              child: Obx(() {
                if (controller.daftarSiswaFiltered.isEmpty) {
                  return const Center(child: Text("Data siswa tidak ditemukan."));
                }
                return RefreshIndicator(
                  onRefresh: () => controller.initializeData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: controller.daftarSiswaFiltered.length,
                    itemBuilder: (context, index) {
                      final siswa = controller.daftarSiswaFiltered[index];
                      final bool canPerformAction = controller.canPerformAnyActionOnSiswa(siswa);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: siswa.fotoProfilUrl != null ? NetworkImage(siswa.fotoProfilUrl!) : null,
                            child: siswa.fotoProfilUrl == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NISN: ${siswa.nisn}"),
                              const SizedBox(height: 4),
                              if(siswa.kelasId != null)
                                Chip(
                                  // --- [PERBAIKAN] Potong string kelasId di sini ---
                                  label: Text(
                                    siswa.kelasId!.split('-').first, 
                                    style: const TextStyle(fontSize: 10, color: Colors.white)
                                  ),
                                  // ----------------------------------------------
                                  backgroundColor: Colors.indigo.shade400,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )
                            ],
                          ),
                          trailing: canPerformAction ? const Icon(Icons.more_vert) : null,
    
                          // [DIUBAH] Aksi onTap hanya aktif jika ada aksi yang bisa dilakukan
                          onTap: canPerformAction ? () => controller.showAksiSiswaMenu(siswa) : null,
                          
                          // [BARU] Beri efek visual jika tidak aktif
                          enabled: canPerformAction,
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
      floatingActionButton: controller.canManageSiswa
          ? FloatingActionButton(
              onPressed: controller.goToTambahSiswa,
              child: const Icon(Icons.add),
              tooltip: 'Tambah Siswa Manual',
            )
          : null,
    );
  }

  // Widget baru untuk panel kontrol
  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Dropdown Kelas
          DropdownButtonFormField<String?>(
            value: controller.selectedKelasId.value,
            hint: const Text('Filter Berdasarkan Kelas'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [
              // Opsi untuk menampilkan semua kelas
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua Kelas'),
              ),
              // Daftar kelas dari controller
              ...controller.daftarKelas.map((kelas) {
                return DropdownMenuItem<String?>(
                  value: kelas['id'],
                  child: Text(kelas['nama']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              controller.selectedKelasId.value = value;
            },
          ),
          const SizedBox(height: 12),
          // Search Bar
          TextField(
            controller: controller.searchC,
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NISN...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}