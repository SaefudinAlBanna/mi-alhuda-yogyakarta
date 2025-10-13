// lib/app/modules/create_edit_halaqah_group/views/create_edit_halaqah_group_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/pegawai_simple_model.dart';
import '../controllers/create_edit_halaqah_group_controller.dart';

class CreateEditHalaqahGroupView extends GetView<CreateEditHalaqahGroupController> {
  const CreateEditHalaqahGroupView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.isEditMode.value ? 'Edit Grup Halaqah' : 'Buat Grup Halaqah'),
          actions: [
            Obx(() => TextButton(
              onPressed: controller.isSaving.value ? null : controller.saveGroup,
              child: controller.isSaving.value 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text("SIMPAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildFormSection(),
              const TabBar(
                tabs: [Tab(text: "Anggota Grup"), Tab(text: "Siswa Tersedia")],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAnggotaGrupTab(),
                    _buildSiswaTersediaTab(),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Obx(() => DropdownButtonFormField<PegawaiSimpleModel>( // <-- [FIX] Tambahkan tipe generik
            value: controller.selectedPengampu.value,
            // [FIX] isExpanded membuat dropdown menggunakan lebar penuh
            isExpanded: true, 
            items: controller.availablePengampu.map((p) {
              return DropdownMenuItem<PegawaiSimpleModel>( // <-- [FIX] Tambahkan tipe generik
                value: p,
                child: Text(
                  "${p.nama} (${p.alias})",
                  overflow: TextOverflow.ellipsis, // Cegah teks terlalu panjang
                ),
              );
            }).toList(),
            onChanged: (value) => controller.selectedPengampu.value = value,
            decoration: const InputDecoration(labelText: "Pilih Pengampu", border: OutlineInputBorder()),
          )),
          const SizedBox(height: 12),
          TextField(
            controller: controller.namaGrupC,
            decoration: const InputDecoration(labelText: "Nama Grup Halaqah", border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildAnggotaGrupTab() {
    return Obx(() {
      if (controller.anggotaGrup.isEmpty) {
        return const Center(child: Text("Belum ada anggota di grup ini."));
      }
      return ListView.builder(
        itemCount: controller.anggotaGrup.length,
        itemBuilder: (context, index) {
          final siswa = controller.anggotaGrup[index];
          return ListTile(
            title: Text(siswa.nama),
            // [PERUBAHAN #1] Tampilkan progresi saat ini di subtitle
            subtitle: Text(
              "Kelas: ${siswa.kelasId.split('-').first} • Progres: ${siswa.tingkat} ${siswa.detailTingkat}",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [PERUBAHAN #2] Tombol Edit Progres
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                  onPressed: () => controller.showEditProgresDialog(siswa),
                  tooltip: "Edit Progres Siswa",
                ),
                // Tombol Hapus Siswa dari Grup
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => controller.removeSiswaFromGroup(siswa),
                  tooltip: "Keluarkan dari Grup",
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildSiswaTersediaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 40,
            child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              children: controller.daftarKelas.map((kelasId) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(kelasId),
                  selected: controller.selectedKelasFilter.value == kelasId,
                  onSelected: (selected) {
                    if (selected) controller.fetchAvailableStudentsByClass(kelasId);
                  },
                ),
              )).toList(),
            )),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (controller.selectedKelasFilter.value.isEmpty) {
              return const Center(child: Text("Pilih kelas di atas untuk melihat siswa."));
            }
            if (controller.siswaTersedia.isEmpty) {
              return const Center(child: Text("Tidak ada siswa tersedia di kelas ini."));
            }
            return ListView.builder(
              itemCount: controller.siswaTersedia.length,
              itemBuilder: (context, index) {
                final siswa = controller.siswaTersedia[index];
                return ListTile(
                  title: Text(siswa.nama),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => controller.addSiswaToGroup(siswa),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}