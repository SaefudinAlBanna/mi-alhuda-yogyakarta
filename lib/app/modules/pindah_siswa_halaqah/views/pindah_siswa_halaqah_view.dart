// lib/app/modules/pindah_siswa_halaqah/views/pindah_siswa_halaqah_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../controllers/pindah_siswa_halaqah_controller.dart';

class PindahSiswaHalaqahView extends GetView<PindahSiswaHalaqahController> {
  const PindahSiswaHalaqahView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindahkan Anggota Halaqah'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Pilih anggota dari grup '${controller.grupAsal.namaGrup}' yang ingin Anda pindahkan.",
                style: Get.textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.anggotaGrupAsal.length,
                itemBuilder: (context, index) {
                  final siswa = controller.anggotaGrupAsal[index];
                  return Obx(() => CheckboxListTile(
                    value: controller.siswaTerpilih.contains(siswa),
                    onChanged: (val) => controller.toggleSiswa(siswa),
                    title: Text(siswa.nama),
                    subtitle: Text("Kelas: ${siswa.kelasId.split('-').first}"),
                  ));
                },
              )),
            ),
            _buildDestinationSection(),
          ],
        );
      }),
      bottomNavigationBar: _buildProcessButton(),
    );
  }

  Widget _buildDestinationSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pindahkan ke Grup Tujuan:", style: Get.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<HalaqahGroupUmmiModel>(
            value: controller.selectedGrupTujuan.value,
            hint: const Text("Pilih grup tujuan..."),
            isExpanded: true,
            items: controller.grupTujuanList.map((grup) {
              return DropdownMenuItem(
                value: grup,
                child: Text("${grup.namaGrup} (Pengampu: ${grup.namaPengampu})", overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => controller.selectedGrupTujuan.value = val,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: controller.isProcessing.value || controller.siswaTerpilih.isEmpty || controller.selectedGrupTujuan.value == null
            ? null
            : controller.prosesPindahSiswa,
        icon: controller.isProcessing.value
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.transfer_within_a_station),
        label: const Text("Pindahkan Siswa Terpilih"),
      )),
    );
  }
}