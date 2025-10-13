// lib/app/modules/halaqah_dashboard_pengampu/views/halaqah_dashboard_pengampu_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';

import '../controllers/halaqah_dashboard_pengampu_controller.dart';

class HalaqahDashboardPengampuView extends GetView<HalaqahDashboardPengampuController> {
  const HalaqahDashboardPengampuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Halaqah Saya'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<HalaqahGroupModel>>(
        future: controller.listGroupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Anda tidak memiliki grup Halaqah untuk semester ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final groupList = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              controller.listGroupFuture = controller.fetchMyGroups();
              (context as Element).reassemble();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupList.length,
              itemBuilder: (context, index) {
                final group = groupList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (group.profileImageUrl != null && group.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(group.profileImageUrl!)
                        : null,
                      child: (group.profileImageUrl == null || group.profileImageUrl!.isEmpty)
                        ? Text(group.aliasPengampu)
                        : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                              group.namaGrup,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // Cegah teks terlalu panjang
                            ),
                          ),
                        const SizedBox(width: 8),
                        // --- [BARU] Tampilkan Chip jika ini adalah tugas pengganti ---
                        if (group.isPengganti)
                          Chip(
                            label: const Text("Pengganti Hari Ini"),
                            backgroundColor: Colors.amber.shade100,
                            side: BorderSide(color: Colors.amber.shade700),
                            labelStyle: TextStyle(color: Colors.amber.shade800, fontSize: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                      ],
                    ),
                    subtitle: Text("Pengampu Utama: ${group.aliasPengampu ?? group.namaPengampu}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.goToGradingPage(group),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}