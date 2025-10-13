// lib/app/modules/upsert_pegawai/views/upsert_pegawai_view.dart (SEKOLAH - DIPERBAIKI)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../controllers/upsert_pegawai_controller.dart';

class UpsertPegawaiView extends GetView<UpsertPegawaiController> {
  const UpsertPegawaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Edit Data Pegawai' : 'Tambah Pegawai Baru')
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: controller.namaC,
                decoration: _buildInputDecoration(labelText: 'Nama Lengkap', icon: Icons.person),
                validator: (v) => controller.validator(v, 'Nama'),
              ),
              const SizedBox(height: 16),
              
              Text("Jenis Kelamin", style: theme.textTheme.titleMedium),
              Obx(() => Row(
                children: [
                  Expanded(child: RadioListTile<String>(title: const Text("Laki-Laki"), value: "Laki-Laki", groupValue: controller.jenisKelamin.value, onChanged: (v) => controller.jenisKelamin.value = v!)),
                  Expanded(child: RadioListTile<String>(title: const Text("Perempuan"), value: "Perempuan", groupValue: controller.jenisKelamin.value, onChanged: (v) => controller.jenisKelamin.value = v!)),
                ],
              )),
              const SizedBox(height: 8),

              TextFormField(
                controller: controller.emailC,
                keyboardType: TextInputType.emailAddress,
                readOnly: controller.isEditMode, 
                decoration: _buildInputDecoration(labelText: 'Email', icon: Icons.email).copyWith(
                  fillColor: controller.isEditMode ? Colors.grey[200] : null,
                  filled: controller.isEditMode
                ),
                validator: (v) => GetUtils.isEmail(v!) ? null : 'Format email tidak valid',
              ),
              const SizedBox(height: 16),

              Obx(() => DropdownButtonFormField<String>(
                value: controller.jabatanTerpilih.value,
                decoration: _buildInputDecoration(labelText: 'Jabatan Utama', icon: Icons.work),
                hint: const Text('Pilih satu jabatan...'),
                items: controller.configC.daftarRoleTersedia.map((jabatan) => DropdownMenuItem(value: jabatan, child: Text(jabatan))).toList(),
                onChanged: (v) => controller.jabatanTerpilih.value = v,
                validator: (v) => controller.validator(v, 'Jabatan'),
              )),
              const SizedBox(height: 20),

              Obx(() => MultiSelectDialogField<String>(
                    buttonIcon: const Icon(Icons.arrow_downward),
                    buttonText: const Text("Tugas Tambahan (Opsional)"),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    title: const Text("Pilih Tugas"),
                    items: controller.configC.daftarTugasTersedia.map((tugas) => MultiSelectItem<String>(tugas, tugas)).toList(),
                    listType: MultiSelectListType.CHIP,
                    onConfirm: (values) => controller.tugasTerpilih.assignAll(values),
                    initialValue: controller.tugasTerpilih.toList(),
                    chipDisplay: MultiSelectChipDisplay(onTap: (value) => controller.tugasTerpilih.remove(value)),
                  )),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                // --- PERBAIKAN KRUSIAL: PANGGIL FUNGSI YANG BENAR ---
                onPressed: controller.validasiDanProses,
                child: Obx(() => Text(
                  controller.isLoadingProses.value ? 'MEMPROSES...' : (controller.isEditMode ? 'UPDATE DATA' : 'SIMPAN DATA PEGAWAI')
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }
}