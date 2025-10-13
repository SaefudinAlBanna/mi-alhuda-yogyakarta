// lib/app/modules/atp_form/views/atp_form_view.dart (FINAL DENGAN CASCADING DROPDOWN)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/atp_form_controller.dart';

class AtpFormView extends GetView<AtpFormController> {
  const AtpFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Edit ATP' : 'Buat ATP Baru')),
        actions: [ IconButton(icon: const Icon(Icons.save_rounded), onPressed: controller.saveAtp) ],
      ),
      body: Obx(() {
        if (controller.isPenugasanLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainInfoSection(),
              const SizedBox(height: 24),
              _buildUnitPembelajaranSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Informasi Umum", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Obx(() => DropdownButtonFormField<String>(
              value: controller.mapelTerpilih.value,
              hint: const Text("Pilih Mata Pelajaran"),
              items: controller.daftarMapelUnik.map((mapel) => DropdownMenuItem(value: mapel, child: Text(mapel))).toList(),
              onChanged: controller.onMapelChanged,
              decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
            )),
        const SizedBox(height: 12),
        Row(
          children: [
            // --- [PERBAIKAN KUNCI] Dropdown Kelas yang Reaktif ---
            Expanded(child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.kelasTerpilih.value,
                  hint: const Text("Pilih Kelas"),
                  // Items sekarang diambil dari state yang dinamis
                  items: controller.daftarKelasTersedia.map((kelas) => DropdownMenuItem(value: kelas, child: Text("Kelas $kelas"))).toList(),
                  // onChanged akan null (disabled) jika mapel belum dipilih
                  onChanged: controller.mapelTerpilih.value == null ? null : controller.onKelasChanged,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    border: const OutlineInputBorder(),
                    filled: controller.mapelTerpilih.value == null,
                    fillColor: Colors.grey.shade200,
                  ),
                ))),
            const SizedBox(width: 12),
            Expanded(child: Obx(() => TextFormField(
                  key: Key(controller.faseTerpilih.value),
                  initialValue: controller.faseTerpilih.value,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fase', border: const OutlineInputBorder(),
                    filled: true, fillColor: Colors.grey.shade200
                  ),
                ))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: controller.capaianPembelajaranC, maxLines: 4, decoration: const InputDecoration(labelText: 'Capaian Pembelajaran (CP)', border: OutlineInputBorder(), alignLabelWithHint: true)),
      ],
    );
  }

  Widget _buildUnitPembelajaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Unit Pembelajaran", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: controller.addUnitPembelajaran,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Unit"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.unitPembelajaranForms.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text("Klik 'Tambah Unit' untuk memulai.", style: TextStyle(color: Colors.grey)),
            ));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.unitPembelajaranForms.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final unitForm = controller.unitPembelajaranForms[index];
              return _UnitCard(unitForm: unitForm, index: index);
            },
          );
        }),
      ],
    );
  }
}

class _UnitCard extends GetView<AtpFormController> {
  final UnitPembelajaranForm unitForm;
  final int index;
  const _UnitCard({required this.unitForm, required this.index, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Unit ${index + 1}", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () => controller.removeUnitPembelajaran(index),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextField(controller: unitForm.lingkupMateriC, decoration: const InputDecoration(labelText: 'Lingkup Materi (Judul Bab)')),
            const SizedBox(height: 12),
            TextField(controller: unitForm.alokasiWaktuC, decoration: const InputDecoration(labelText: 'Alokasi Waktu (Contoh: 12 JP)')),
            const SizedBox(height: 24),
            _buildDynamicListSection(
              title: "Tujuan Pembelajaran (TP)",
              list: unitForm.tujuanPembelajaran,
            ),
          ],
        ),
      ),
    );
  }

  // Widget generik untuk menampilkan dan mengelola list dinamis
  Widget _buildDynamicListSection({
    required String title,
    required RxList<String> list,
  }) {
    final textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                leading: Text("${idx + 1}."),
                title: Text(list[idx]),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  onPressed: () => list.removeAt(idx),
                ),
              ),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Tambah baru...', border: OutlineInputBorder()),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  list.add(value);
                  textController.clear();
                }
              },
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Get.theme.primaryColor),
              icon: const Icon(Icons.add),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  list.add(textController.text);
                  textController.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}