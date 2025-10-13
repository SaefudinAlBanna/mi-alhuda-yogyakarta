// lib/app/modules/create_edit_ekskul/views/create_edit_ekskul_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';
import '../controllers/create_edit_ekskul_controller.dart';

class CreateEditEkskulView extends GetView<CreateEditEkskulController> {
  const CreateEditEkskulView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode.value ? 'Edit Ekskul' : 'Tambah Ekskul'),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : controller.saveEkskul,
            child: controller.isSaving.value
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(controller: controller.namaC, decoration: const InputDecoration(labelText: "Nama Ekstrakurikuler"), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: controller.deskripsiC, decoration: const InputDecoration(labelText: "Deskripsi Singkat"), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: controller.tujuanC, decoration: const InputDecoration(labelText: "Tujuan"), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: controller.jadwalC, decoration: const InputDecoration(labelText: "Jadwal (Teks)", hintText: "Contoh: Setiap Sabtu, 08:00 - 10:00")),
              const SizedBox(height: 16),
              TextFormField(controller: controller.biayaC, decoration: const InputDecoration(labelText: "Biaya Bulanan (jika ada)", prefixText: "Rp "), keyboardType: TextInputType.number),
              const Divider(height: 32),
              
              // --- [DIROMBAK TOTAL] Bagian Pembina Fleksibel ---
              const Text("Informasi Pembina", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.listPembinaTerpilih.length,
                itemBuilder: (context, index) {
                  final pembina = controller.listPembinaTerpilih[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(pembina['jenis'] == 'internal' ? Icons.school : Icons.person_pin),
                      title: Text(pembina['nama']),
                      subtitle: Text(pembina['jenis'].toString().capitalizeFirst!),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => controller.removePembina(index),
                      ),
                    ),
                  );
                },
              )),
              if (controller.listPembinaTerpilih.isEmpty) 
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text("Belum ada pembina yang ditambahkan.", style: TextStyle(color: Colors.grey))),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: controller.openAddPembinaInternalDialog, icon: const Icon(Icons.school), label: const Text("Internal"))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(onPressed: controller.openAddPembinaEksternalDialog, icon: const Icon(Icons.person_pin), label: const Text("Eksternal"))),
                ],
              ),
              // --- AKHIR BAGIAN PEMBINA ---
              
              const Divider(height: 32),
              const Text("Penanggung Jawab (PJ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDropdownPegawai("Pilih Penanggung Jawab", controller.selectedPJ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDropdownPegawai(String label, Rxn<PegawaiSimpleModel> selectedValue) {
    return Obx(() => DropdownButtonFormField<PegawaiSimpleModel>(
      value: selectedValue.value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: controller.daftarPegawai.map((p) => DropdownMenuItem(
        value: p,
        child: Text("${p.nama} (${p.alias})", overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (value) => selectedValue.value = value,
      validator: (v) => v == null ? 'Wajib dipilih' : null,
    ));
  }
}