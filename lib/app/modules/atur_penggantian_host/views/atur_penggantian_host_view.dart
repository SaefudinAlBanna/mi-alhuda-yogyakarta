import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/atur_guru_pengganti/views/atur_guru_pengganti_view.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/atur_penggantian_rentang/views/atur_penggantian_rentang_view.dart';
import '../controllers/atur_penggantian_host_controller.dart';

class AturPenggantianHostView extends GetView<AturPenggantianHostController> {
  const AturPenggantianHostView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Guru Pengganti'),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(child: Text("Per Sesi (Insidental)", textAlign: TextAlign.center)),
            Tab(child: Text("Rentang Waktu (Terencana)", textAlign: TextAlign.center)),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: const [
          // Tampilan 1: Halaman yang sudah ada & diperbaiki
          AturGuruPenggantiView(),
          // Tampilan 2: Halaman baru yang akan kita bangun
          AturPenggantianRentangView(),
        ],
      ),
    );
  }
}