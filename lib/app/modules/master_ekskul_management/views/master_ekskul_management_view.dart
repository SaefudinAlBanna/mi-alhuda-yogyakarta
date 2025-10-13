import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/ekskul_model.dart';

import '../../../routes/app_pages.dart';
import '../controllers/master_ekskul_management_controller.dart';

class MasterEkskulManagementView extends GetView<MasterEkskulManagementController> {
  const MasterEkskulManagementView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Ekstrakurikuler'),
        centerTitle: true,
        actions: [
          if (controller.dashC.isPimpinan)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: "Editor Jadwal",
            onSelected: (value) {
              if (value == 'Pend_Ekskul') {Get.toNamed(Routes.EKSKUL_PENDAFTARAN_MANAGEMENT);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Pend_Ekskul', child: ListTile(leading: Icon(Icons.timer_sharp), title: Text("Buka/Tutup Pendaftaran"))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamEkskul(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada ekskul untuk semester ini."));
          }
          final ekskulList = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ekskulList.length,
            itemBuilder: (context, index) {
              final ekskul = EkskulModel.fromFirestore(ekskulList[index]);
              final List<dynamic> listPembina = ekskul.listPembina;
              final namaPembina = listPembina.map((p) => p['nama']).join(', ');
            
              return Card(
                child: ListTile(
                  title: Text(ekskul.namaEkskul),
                  subtitle: Text("Pembina: ${namaPembina.isNotEmpty ? namaPembina : 'N/A'}"),
                  
                  // --- [PERBAIKAN #1] Tampilkan trailing hanya untuk pimpinan ---
                  trailing: controller.dashC.isPimpinan
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => controller.deleteEkskul(ekskul),
                              tooltip: "Hapus Ekskul",
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        )
                      : null, // Sembunyikan jika bukan pimpinan

                  // --- [PERBAIKAN #2] Aktifkan onTap hanya untuk pimpinan ---
                  onTap: controller.dashC.isPimpinan
                      ? () => controller.goToEditEkskul(ekskul)
                      : null, // Nonaktifkan tap jika bukan pimpinan
                ),
              );
            },
          );
        },
      ),
      
      // --- [PERBAIKAN #3] Tampilkan FAB hanya untuk pimpinan ---
      floatingActionButton: controller.dashC.isPimpinan
          ? FloatingActionButton.extended(
              onPressed: controller.goToCreateEkskul,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Ekskul"),
            )
          : null, // Sembunyikan FAB jika bukan pimpinan
    );
  }
}