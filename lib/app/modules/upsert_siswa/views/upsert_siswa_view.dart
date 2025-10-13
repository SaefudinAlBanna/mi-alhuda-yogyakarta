// lib/app/modules/upsert_siswa/views/upsert_siswa_view.dart (SEKOLAH - DIPERBAIKI)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/upsert_siswa_controller.dart';

class UpsertSiswaView extends GetView<UpsertSiswaController> {
  const UpsertSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Edit Siswa' : 'Tambah Siswa Manual'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: controller.namaC,
                decoration: const InputDecoration(labelText: 'Nama Lengkap Siswa', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.nisnC,
                decoration: InputDecoration(
                  labelText: 'NISN', 
                  border: const OutlineInputBorder(),
                  fillColor: controller.isEditMode ? Colors.grey.shade200 : null,
                  filled: controller.isEditMode,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v!.isEmpty ? 'NISN tidak boleh kosong' : null,
                readOnly: controller.isEditMode,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.sppC,
                decoration: const InputDecoration(labelText: 'Biaya SPP', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v!.isEmpty ? 'SPP tidak boleh kosong' : null,
              ),
              const SizedBox(height: 32),
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: controller.isLoading.value ? null : controller.validasiDanProses, // Panggil fungsi ini
                child: Text(controller.isLoading.value ? 'MEMPROSES...' : (controller.isEditMode ? 'UPDATE DATA' : 'SIMPAN SISWA')),
              )),
            ],
          ),
        ),
      ),
    );
  }
}