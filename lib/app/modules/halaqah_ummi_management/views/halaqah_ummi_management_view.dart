// lib/app/modules/halaqah_ummi_management/views/halaqah_ummi_management_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/halaqah_ummi_management_controller.dart';

class HalaqahUmmiManagementView extends GetView<HalaqahUmmiManagementController> {
  const HalaqahUmmiManagementView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Halaqah Ummi'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: "Editor Jadwal",
            onSelected: (value) {
              if (value == 'Dashboard') {Get.toNamed(Routes.HALAQAH_UMMI_DASHBOARD_KOORDINATOR);}
              if (value == 'penugasan') {Get.toNamed(Routes.HALAQAH_UMMI_MANAJEMEN_PENGUJI);}
              if (value == 'Jadwal') {Get.toNamed(Routes.HALAQAH_UMMI_JADWAL_PENGUJI);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Dashboard', child: ListTile(leading: Icon(Icons.dashboard_customize_outlined), title: Text("Dashboard"))),
              const PopupMenuItem(value: 'penugasan', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("penugasan"))),
              const PopupMenuItem(value: 'Jadwal', child: ListTile(leading: Icon(Icons.schedule_sharp), title: Text("Jadwal"))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamHalaqahUmmiGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Belum ada grup Halaqah Ummi.", textAlign: TextAlign.center),
            );
          }
          final groupList = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupList.length,
            itemBuilder: (context, index) {
              final groupDoc = groupList[index];
              final group = HalaqahGroupUmmiModel.fromFirestore(groupDoc);
              
              final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final penggantiData = (groupDoc.data()['penggantiHarian'] as Map<String, dynamic>?)?[todayKey];
              final bool adaPengganti = penggantiData != null;
              final String namaPengganti = penggantiData?['aliasPengganti'] ?? penggantiData?['namaPengganti'] ?? '';

              return Card(
                color: adaPengganti ? Colors.amber.shade50 : null,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(group.fase, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(group.namaGrup, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: adaPengganti
                      ? Text("Digantikan oleh: $namaPengganti", style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold))
                      : Text("Pengampu: ${group.namaPengampu}"),
                  
                  // [PEROMBAKAN UI DI SINI]
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Aksi Cepat
                      if (adaPengganti)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          onPressed: () => controller.batalkanPengganti(group),
                          tooltip: "Batalkan Pengganti",
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                          onPressed: () => controller.goToSetPengganti(group),
                          tooltip: "Atur Pengganti Sementara",
                        ),
                      
                      // Menu Aksi Tambahan
                      PopupMenuButton<String>(
                        tooltip: "Aksi Lainnya",
                        onSelected: (value) {
                          if (value == 'ganti_pengampu') {
                            controller.showGantiPengampuDialog(group);
                          } else if (value == 'pindah_siswa') {
                            controller.goToPindahSiswaPage(group);
                          } else if (value == 'hapus_grup') {
                            controller.deleteGroup(group);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'ganti_pengampu',
                            child: ListTile(leading: Icon(Icons.person_search), title: Text("Ganti Pengampu")),
                          ),
                          const PopupMenuItem(
                            value: 'pindah_siswa',
                            child: ListTile(leading: Icon(Icons.transfer_within_a_station), title: Text("Pindahkan Anggota")),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'hapus_grup',
                            child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text("Hapus Grup", style: TextStyle(color: Colors.red))),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => controller.goToEditGroup(group),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToCreateGroup,
        icon: const Icon(Icons.add),
        label: const Text("Grup Ummi Baru"),
      ),
    );
  }
}