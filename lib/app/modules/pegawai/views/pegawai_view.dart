import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/enums/user_role_enum.dart';
import '../controllers/pegawai_controller.dart';

class PegawaiView extends GetView<PegawaiController> {
  const PegawaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pegawai'),
        actions: [
          // Tombol ini hanya muncul jika pengguna punya hak konfigurasi
          if (controller.canConfigureRoles)
            IconButton(
              icon: const Icon(Icons.rule_folder_outlined),
              tooltip: 'Kelola Peran & Tugas',
              onPressed: controller.goToManajemenPeran,
            ),
        ],
        // Kolom pencarian di bawah AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: controller.searchC,
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Cari nama atau jabatan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarPegawaiFiltered.isEmpty) {
          return const Center(child: Text("Data pegawai tidak ditemukan."));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchPegawai(),
          child: ListView.builder(
            itemCount: controller.daftarPegawaiFiltered.length,
            itemBuilder: (context, index) {
              final pegawai = controller.daftarPegawaiFiltered[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: pegawai.profileImageUrl != null
                        ? NetworkImage(pegawai.profileImageUrl!)
                        : null,
                    child: pegawai.profileImageUrl == null
                        ? Text(pegawai.nama.substring(0, 1))
                        : null,
                  ),
                  title: Text(pegawai.alias ?? pegawai.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pegawai.role.displayName),
                  trailing: (controller.canManagePegawai)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                              onPressed: () => controller.goToEditPegawai(pegawai),
                              tooltip: 'Edit Pegawai',
                            ),
                            // Jangan biarkan Super Admin menghapus dirinya sendiri
                            if (pegawai.role != UserRole.superAdmin)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                                onPressed: () => controller.hapusPegawai(pegawai),
                                tooltip: 'Hapus Pegawai',
                              ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      }),
      // Tombol Tambah hanya muncul untuk yang berhak
      floatingActionButton: controller.canManagePegawai
          ? FloatingActionButton(
              onPressed: controller.goToTambahPegawai,
              child: const Icon(Icons.person_add_alt_1),
              tooltip: 'Tambah Pegawai Baru',
            )
          : null,
    );
  }
}