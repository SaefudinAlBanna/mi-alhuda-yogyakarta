// lib/app/modules/manajemen_penawaran_buku/views/manajemen_penawaran_buku_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/buku_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/manajemen_penawaran_buku_controller.dart';

class ManajemenPenawaranBukuView extends GetView<ManajemenPenawaranBukuController> {
  const ManajemenPenawaranBukuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Penawaran Buku'),
        centerTitle: true,
        actions: [
          if (controller.dashC.canManageKbm)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: "Pendaftaran Buku",
            onSelected: (value) {
              if (value == 'Pend_Buku') {Get.toNamed(Routes.MANAJEMEN_PENDAFTARAN_BUKU);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Pend_Buku', child: ListTile(leading: Icon(Icons.timer_sharp), title: Text("Buka/Tutup Pendaftaran"))),
            ],
          ),
        ],
      ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.how_to_reg_rounded),
      //       tooltip: "Buka/Tutup Pendaftaran",
      //       onPressed: controller.goToManajemenPendaftaran,
      //     )
      //   ],
      // ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamBukuDitawarkan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada buku yang ditawarkan."));
          }
          final bukuList = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bukuList.length,
            itemBuilder: (context, index) {
              final buku = BukuModel.fromFirestore(bukuList[index]);
              return Card(
                child: ListTile(
                  title: Text(buku.namaItem),
                  subtitle: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(buku.harga)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => controller.deleteBuku(buku),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => controller.goToEditBuku(buku),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToCreateBuku,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Buku/Paket"),
      ),
    );
  }
}