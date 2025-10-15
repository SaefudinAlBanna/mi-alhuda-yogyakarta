// lib/app/modules/manajemen_peran/views/manajemen_peran_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import '../controllers/manajemen_peran_controller.dart';

class ManajemenPeranView extends GetView<ManajemenPeranController> {
  const ManajemenPeranView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kita butuh ConfigController untuk mendapatkan datanya
    final configC = Get.find<ConfigController>();

    return DefaultTabController(
      length: 2, // Dua tab: Peran dan Tugas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Peran & Tugas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Peran / Jabatan', icon: Icon(Icons.admin_panel_settings_outlined)),
              Tab(text: 'Tugas Tambahan', icon: Icon(Icons.assignment_ind_outlined)),
            ],
          ),
        ),
        body: Obx(
          () => configC.isRoleManagementLoading.value
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // --- TAB 1: DAFTAR PERAN ---
                    _buildListView(
                      context: context,
                      title: "Daftar Peran / Jabatan",
                      items: configC.daftarRoleTersedia,
                      onAdd: () => controller.showFormDialog(isRole: true),
                      onDelete: (item) => controller.showDeleteConfirmation(itemName: item, isRole: true),
                    ),
                    // --- TAB 2: DAFTAR TUGAS ---
                    _buildListView(
                      context: context,
                      title: "Daftar Tugas Tambahan",
                      items: configC.daftarTugasTersedia,
                      onAdd: () => controller.showFormDialog(isRole: false),
                      onDelete: (item) => controller.showDeleteConfirmation(itemName: item, isRole: false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Helper widget untuk membangun UI list yang bisa dipakai ulang.
  Widget _buildListView({
    required BuildContext context,
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(String) onDelete,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('Belum ada data. Silakan tambahkan.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(item),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                          onPressed: () => onDelete(item),
                          tooltip: 'Hapus $item',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}