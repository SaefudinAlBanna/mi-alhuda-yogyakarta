// lib/app/modules/master_jam/views/master_jam_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/master_jam_controller.dart';

class MasterJamView extends GetView<MasterJamController> {
  const MasterJamView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Jam Pelajaran')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showFormDialog(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamJamPelajaran(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada jam pelajaran."));
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(doc.data()['urutan'].toString())),
                  title: Text(doc.data()['namaKegiatan'] ?? ''),
                  subtitle: Text("Waktu: ${doc.data()['jampelajaran']}"),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showFormDialog(context, doc: doc)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmation(doc.id)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    if (isEditing) {
      final data = doc.data() as Map<String, dynamic>;
      controller.namaC.text = data['namaKegiatan'] ?? '';
      final parseTime = (String timeStr) => TimeOfDay(hour: int.parse(timeStr.split(':')[0]), minute: int.parse(timeStr.split(':')[1]));
      controller.jamMulai.value = parseTime(data['jamMulai']);
      controller.jamSelesai.value = parseTime(data['jamSelesai']);
    } else {
      controller.namaC.clear();
      controller.jamMulai.value = null;
      controller.jamSelesai.value = null;
    }

    Get.defaultDialog(
      title: isEditing ? "Edit Jam" : "Tambah Jam",
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller.namaC, decoration: const InputDecoration(labelText: 'Nama Kegiatan')),
        const SizedBox(height: 16),
        Obx(() => _buildTimePickerField(context, 'Jam Mulai', controller.jamMulai.value, () => controller.pilihWaktu(context, isMulai: true))),
        const SizedBox(height: 8),
        Obx(() => _buildTimePickerField(context, 'Jam Selesai', controller.jamSelesai.value, () => controller.pilihWaktu(context, isMulai: false))),
      ]),
      confirm: ElevatedButton(onPressed: () => controller.simpanJam(docId: isEditing ? doc.id : null), child: const Text("Simpan")),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
  
  Widget _buildTimePickerField(BuildContext context, String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(time != null ? time.format(context) : 'Pilih Waktu'),
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    Get.defaultDialog(
      title: "Konfirmasi", middleText: "Anda yakin ingin menghapus jam pelajaran ini?",
      confirm: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => controller.hapusJam(docId), child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white))),
      cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
}