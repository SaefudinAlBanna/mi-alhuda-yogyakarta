// lib/app/modules/halaqah_set_pengganti/views/halaqah_set_pengganti_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mi_alhuda_yogyakarta/app/models/pegawai_simple_model.dart';
import '../controllers/halaqah_set_pengganti_controller.dart';

class HalaqahSetPenggantiView extends GetView<HalaqahSetPenggantiController> {
  const HalaqahSetPenggantiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Pengganti Halaqah'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Anda akan mengatur pengganti untuk grup:", style: Get.textTheme.titleSmall),
            Text(controller.group.namaGrup, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            
            // Pemilihan Tanggal
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Tanggal Penggantian"),
              subtitle: Obx(() => Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(controller.selectedDate.value),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => controller.pickDate(context),
            ),
            const SizedBox(height: 16),

            // Pemilihan Guru Pengganti
            Obx(() => DropdownButtonFormField<PegawaiSimpleModel>(
              value: controller.selectedPengganti.value,
              isExpanded: true,
              items: controller.daftarPengganti.map((p) => DropdownMenuItem(
                value: p,
                child: Text("${p.nama} (${p.alias})", overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) => controller.selectedPengganti.value = value,
              decoration: const InputDecoration(
                labelText: "Pilih Guru Pengganti",
                border: OutlineInputBorder(),
              ),
            )),
            const SizedBox(height: 32),

            // Tombol Simpan
            Obx(() => ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : controller.simpanPengganti,
              icon: controller.isSaving.value 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text("Simpan Pengganti"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )),
          ],
        );
      }),
    );
  }
}