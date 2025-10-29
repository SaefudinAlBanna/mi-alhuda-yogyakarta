// lib/app/modules/manajemen_anggaran/views/manajemen_anggaran_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/number_input_formatter.dart';
import '../controllers/manajemen_anggaran_controller.dart';

class ManajemenAnggaranView extends GetView<ManajemenAnggaranController> {
  const ManajemenAnggaranView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atur Anggaran ${controller.tahunAnggaran}'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarKategori.isEmpty) {
          return const Center(child: Text("Tidak ada kategori pengeluaran yang bisa dianggarkan."));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding bawah agar tidak tertutup tombol
          itemCount: controller.daftarKategori.length,
          itemBuilder: (context, index) {
            final kategori = controller.daftarKategori[index];
            final textController = controller.anggaranControllers[kategori]!;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: kategori,
                  prefixText: "Rp ",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [NumberInputFormatter()],
              ),
            );
          },
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: controller.isSaving.value ? null : controller.simpanAnggaran,
          icon: controller.isSaving.value
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
              : const Icon(Icons.save),
          label: Text(controller.isSaving.value ? "MENYIMPAN..." : "SIMPAN ANGGARAN"),
        )),
      ),
    );
  }
}