import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/tugas_model.dart'; // <-- Model baru yang akan kita buat
import '../controllers/manajemen_tugas_controller.dart';

class ManajemenTugasView extends GetView<ManajemenTugasController> {
  const ManajemenTugasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Tugas', style: TextStyle(fontSize: 18)),
            Text(
              '${controller.namaMapel} - ${controller.idKelas}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: "PR / Harian"),
            Tab(icon: Icon(Icons.quiz), text: "Ulangan"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Buat Tugas Baru",
            onPressed: () => controller.showBuatTugasDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          _buildTugasList("PR"),
          _buildTugasList("Ulangan"),
        ],
      ),
    );
  }

  Widget _buildTugasList(String kategori) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<TugasModel> daftarTugas = (kategori == "PR")
          ? controller.daftarTugasPR
          : controller.daftarTugasUlangan;

      if (daftarTugas.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Belum ada $kategori',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text("Buat $kategori Baru"),
                onPressed: () => controller.showBuatTugasDialog(kategori: kategori),
              )
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchTugas,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: daftarTugas.length,
          itemBuilder: (context, index) {
            final tugas = daftarTugas[index];
            return Card(
              elevation: 2.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => controller.goToInputNilaiMassal(tugas),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tugas.judul,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPopupMenu(tugas),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dibuat: ${DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tugas.tanggalDibuat)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (tugas.deskripsi.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            tugas.deskripsi,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.grading_rounded, size: 18),
                            label: const Text("Input Nilai"),
                            onPressed: () => controller.goToInputNilaiMassal(tugas),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPopupMenu(TugasModel tugas) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          controller.showEditTugasDialog(tugas);
        } else if (value == 'delete') {
          controller.confirmDeleteTugas(tugas);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Hapus')),
        ),
      ],
    );
  }
}