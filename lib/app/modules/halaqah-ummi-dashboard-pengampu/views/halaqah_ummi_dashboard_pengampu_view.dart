import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/halaqah_ummi_dashboard_pengampu_controller.dart';

class HalaqahUmmiDashboardPengampuView
    extends GetView<HalaqahUmmiDashboardPengampuController> {
  const HalaqahUmmiDashboardPengampuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Halaqah Ummi'),
        centerTitle: true,
        actions: [
          if (controller.dashC.canManageHalaqah)
          IconButton(onPressed: () => Get.toNamed(Routes.HALAQAH_UMMI_MANAGEMENT), 
          icon: const Icon(Icons.group_add_outlined)), 
        ],
      ),
      body: FutureBuilder<List<HalaqahGroupUmmiModel>>(
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
                "Anda tidak memiliki grup Halaqah Ummi untuk semester ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final groupList = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Reload data
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
                      child: Text(group.fase),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.namaGrup,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (group.isPengganti)
                          const Chip(
                            label: Text("Pengganti"),
                            backgroundColor: Colors.amber,
                            labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    subtitle: Text("Lokasi: ${group.lokasiDefault}"),
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