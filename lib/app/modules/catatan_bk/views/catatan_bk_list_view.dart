import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/catatan_bk_controller.dart';

class CatatanBkListView extends GetView<CatatanBkController> {
  const CatatanBkListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Panggil fetchCatatanList saat halaman pertama kali dibangun
    controller.fetchCatatanList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan BK: ${controller.siswaNama}'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isListLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarCatatan.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Belum ada catatan BK untuk siswa ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchCatatanList(),
          child: ListView.builder(
            itemCount: controller.daftarCatatan.length,
            itemBuilder: (context, index) {
              final catatan = controller.daftarCatatan[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    catatan.status == 'Ditutup' ? Icons.check_circle : Icons.chat_bubble_outline,
                    color: catatan.status == 'Ditutup' ? Colors.green : Colors.orange,
                  ),
                  title: Text(catatan.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Dibuat oleh: ${catatan.pembuatNama}\n${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(catatan.tanggalDibuat)}'),
                  isThreeLine: true,
                  onTap: () => controller.goToDetail(catatan),
                ),
              );
            },
          ),
        );
      }),
      // --- [BAGIAN KRUSIAL YANG PERLU DIPERBAIKI ADA DI SINI] ---
      floatingActionButton: Obx(() {
        // Tampilkan tombol HANYA jika controller.canCreateNote.value adalah true
        if (controller.canCreateNote.value) {
          return FloatingActionButton(
            onPressed: controller.showCreateNoteForm,
            child: const Icon(Icons.add),
            tooltip: 'Buat Catatan Baru',
          );
        } else {
          // Jika tidak, kembalikan widget kosong
          return const SizedBox.shrink();
        }
      }),
      // --- [AKHIR BAGIAN PERBAIKAN] ---
    );
  }
}