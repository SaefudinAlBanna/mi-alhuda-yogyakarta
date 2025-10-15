// lib/app/modules/halaqah_management/views/halaqah_management_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_alhuda_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:get/get.dart';
import '../controllers/halaqah_management_controller.dart';

class HalaqahManagementView extends GetView<HalaqahManagementController> {
  const HalaqahManagementView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Halaqah'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamHalaqahGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada grup Halaqah untuk semester ini.\nSilakan buat grup baru.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final groupList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupList.length,
            itemBuilder: (context, index) {
              final group = HalaqahGroupModel.fromFirestore(groupList[index]);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  // --- [DIUBAH] Ganti seluruh leading ini ---
                  leading: CircleAvatar(
                // Gunakan backgroundImage jika URL ada
                backgroundImage: (group.profileImageUrl != null && group.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(group.profileImageUrl!)
                  : null,
                // Jika tidak ada gambar, tampilkan alias
                child: (group.profileImageUrl == null || group.profileImageUrl!.isEmpty)
                  ? Text(group.aliasPengampu)
                  : null,
              ),
                  title: Text(group.namaGrup, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Pengampu: ${group.namaPengampu}"),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Tombol untuk atur pengganti
                       IconButton(
                         icon: const Icon(Icons.person_add_alt_1_rounded),
                         onPressed: () => controller.goToSetPengganti(group),
                         tooltip: "Atur Pengganti",
                       ),
                       // Tombol hapus yang sudah ada
                       IconButton(
                         icon: const Icon(Icons.delete_outline, color: Colors.red),
                         onPressed: () => controller.deleteGroup(group),
                         tooltip: "Hapus Grup",
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
        label: const Text("Buat Grup Baru"),
      ),
    );
  }
}