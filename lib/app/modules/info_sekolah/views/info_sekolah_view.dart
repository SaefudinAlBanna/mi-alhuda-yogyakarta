// lib/app/modules/info_sekolah/views/info_sekolah_view.dart (FINAL & LENGKAP)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/info_sekolah_controller.dart';

class InfoSekolahView extends GetView<InfoSekolahController> {
  const InfoSekolahView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informasi Sekolah")),
      floatingActionButton: Obx(() => controller.canPost.value
          ? FloatingActionButton.extended(
              onPressed: () => controller.goToForm(),
              label: const Text("Buat Info Baru"),
              icon: const Icon(Icons.add),
            )
          : const SizedBox.shrink()),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada informasi yang dipublikasikan."));
          }
          final daftarInfo = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftarInfo.length,
            itemBuilder: (context, index) {
              final doc = daftarInfo[index];
              final data = doc.data();
              final timestamp = data['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias, // Penting untuk gambar
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                      Image.network(
                        data['imageUrl'],
                        width: double.infinity, height: 200, fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['judul'] ?? 'Tanpa Judul', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(data['penulisNama'] ?? 'Admin', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const Text(" • ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              if (timestamp != null)
                                Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(timestamp.toDate()), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(data['isi'] ?? '', style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                    if (controller.isPimpinan) // Hanya Pimpinan yang bisa edit/hapus
                      Container(
                        color: Colors.grey.shade100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade700), label: const Text("Edit"), onPressed: () => controller.goToForm(info: doc)),
                            TextButton.icon(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700), label: const Text("Hapus"), onPressed: () => controller.hapusInfo(doc.id)),
                          ],
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}