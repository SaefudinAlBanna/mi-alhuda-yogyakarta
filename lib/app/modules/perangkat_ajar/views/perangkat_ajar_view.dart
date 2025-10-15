// lib/app/modules/perangkat_ajar/views/perangkat_ajar_view.dart (FINAL & LENGKAP)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_alhuda_yogyakarta/app/models/atp_model.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';
import '../../../models/modul_ajar_model.dart';
import '../controllers/perangkat_ajar_controller.dart';

class PerangkatAjarView extends GetView<PerangkatAjarController> {
  const PerangkatAjarView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perangkat Ajar Saya'),
          actions: [
            Obx(() {
              if (controller.daftarTahunAjaran.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.tahunAjaranFilter.value,
                    onChanged: controller.gantiTahunAjaranFilter,
                    items: controller.daftarTahunAjaran.map((String idTahun) {
                      return DropdownMenuItem<String>(
                        value: idTahun,
                        child: Text(idTahun.replaceAll('-', '/'), style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    dropdownColor: Colors.indigo.shade700,
                    iconEnabledColor: Colors.white,
                  ),
                ),
              );
            }),
          ],
          bottom: const TabBar(
            tabs: [ Tab(text: 'ATP (Alur Tujuan Pembelajaran)'), Tab(text: 'Modul Ajar') ],
          ),
        ),
        body: TabBarView(
          children: [ _buildAtpListView(), _buildModulAjarListView() ],
        ),
        floatingActionButton: Builder(
          builder: (BuildContext newContext) {
            return FloatingActionButton.extended(
              onPressed: () {
                int currentIndex = DefaultTabController.of(newContext).index;
                if (currentIndex == 0) {
                  Get.toNamed(Routes.ATP_FORM);
                } else {
                  // Get.snackbar("Info", "Modul Ajar sedang dalam pengembangan.");
                  Get.toNamed(Routes.MODUL_AJAR_FORM);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Buat Baru"),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAtpListView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamAtp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('ATP');

        final daftarAtp = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: daftarAtp.length,
          itemBuilder: (context, index) {
            final doc = daftarAtp[index];
            final atp = AtpModel.fromJson(doc.data()..['idAtp'] = doc.id);
            final bool isOwner = controller.configC.infoUser['uid'] == atp.idPenyusun;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.route_rounded, color: Colors.blue),
                title: Text(atp.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kelas ${atp.kelas} (Fase ${atp.fase}) - Oleh: ${atp.namaPenyusun}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_outlined, color: Colors.grey),
                      onPressed: () => Get.snackbar("Info", "Fitur Cetak PDF akan segera hadir."),
                      tooltip: "Cetak PDF",
                    ),
                    if (isOwner)
                      PopupMenuButton<String>( // <-- Tambahkan tipe <String> di sini
                        itemBuilder: (context) => <PopupMenuEntry<String>>[ // <-- Beri tipe eksplisit pada List
                          const PopupMenuItem<String>(value: 'edit', child: Text("Edit")),
                          const PopupMenuItem<String>(value: 'prosem', child: Text("Jadwal (Prosem)")),
                          const PopupMenuDivider(), // Divider tidak butuh tipe
                          const PopupMenuItem<String>(value: 'hapus', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') Get.toNamed(Routes.ATP_FORM, arguments: atp);
                          // if (value == 'prosem') Get.snackbar("Info", "Fitur Prota/Prosem akan segera hadir.");
                          if (value == 'prosem') Get.toNamed(Routes.PROTA_PROSEM, arguments: atp);
                          if (value == 'hapus') controller.deleteAtp(atp.idAtp);
                        },
                      ),
                  ],
                ),
                onTap: () {
                  // Jika pemilik, langsung ke mode edit. Jika bukan, ke halaman detail (read-only).
                  if (isOwner) {
                    Get.toNamed(Routes.ATP_FORM, arguments: atp);
                  } else {
                    Get.snackbar("Info", "Anda hanya dapat melihat ATP ini (read-only).");
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModulAjarListView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamModulAjar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Modul Ajar');
        }

        final daftarModul = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: daftarModul.length,
          itemBuilder: (context, index) {
            final doc = daftarModul[index];
            final modul = ModulAjarModel.fromJson(doc.data()..['idModul'] = doc.id);
            final bool isOwner = controller.configC.infoUser['uid'] == modul.idPenyusun;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.green),
                title: Text(modul.mapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kelas ${modul.kelas} (Fase ${modul.fase}) - Oleh: ${modul.namaPenyusun}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_outlined, color: Colors.grey),
                      onPressed: () => Get.snackbar("Info", "Fitur Cetak PDF akan segera hadir."),
                      tooltip: "Cetak PDF",
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          // Panggil fungsi delete dari controller utama (perlu dibuat)
                          controller.deleteModulAjar(modul.idModul);
                        },
                        tooltip: "Hapus Modul",
                      ),
                  ],
                ),
                onTap: () {
                  // Jika pemilik, langsung ke mode edit.
                  if (isOwner) {
                    Get.toNamed(Routes.MODUL_AJAR_FORM, arguments: modul);
                  } else {
                    Get.snackbar("Info", "Anda hanya dapat melihat Modul Ajar ini (read-only).");
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String jenis) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'Belum ada $jenis yang Anda buat untuk tahun ajaran ini.\nKlik tombol (+) untuk memulai.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}