import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/halaqah_ummi_grading_massal_controller.dart';

class HalaqahUmmiGradingMassalView extends GetView<HalaqahUmmiGradingMassalController> {
  const HalaqahUmmiGradingMassalView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Nilai Semua Siswa"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.listSiswaForGrading.isEmpty) {
          return const Center(child: Text("Tidak ada anggota di grup ini."));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.lokasiC,
                decoration: const InputDecoration(
                  labelText: "Lokasi Setoran Hari Ini",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: controller.listSiswaForGrading.length,
                itemBuilder: (context, index) {
                  final siswaModel = controller.listSiswaForGrading[index];
                  return _buildSiswaGradingCard(siswaModel);
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.isSaving.value ? null : controller.saveMassGrading,
        icon: controller.isSaving.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.save),
        label: const Text("Simpan Semua"),
      )),
    );
  }

  Widget _buildSiswaGradingCard(SiswaMassGradingModel siswaModel) {
    final progresText = "${siswaModel.progresData['tingkat']} ${siswaModel.progresData['detailTingkat']} Hal ${siswaModel.progresData['halaman']}";
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${siswaModel.siswa.nama} - $progresText", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => Row(
              children: ["Lancar", "Perlu Perbaikan", "Mengulang"].map((status) {
                return Expanded(
                  child: InkWell(
                    onTap: () => siswaModel.status.value = status,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: siswaModel.status.value == status ? Get.theme.primaryColor.withOpacity(0.1) : null,
                        border: Border.all(color: siswaModel.status.value == status ? Get.theme.primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: siswaModel.nilaiC,
                    decoration: const InputDecoration(labelText: "Nilai", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: siswaModel.catatanC,
                    decoration: const InputDecoration(labelText: "Catatan Singkat", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}