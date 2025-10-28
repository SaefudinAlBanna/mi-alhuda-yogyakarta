// lib/app/modules/manajemen_tunggakan_awal/views/manajemen_tunggakan_awal_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../widgets/number_input_formatter.dart';
import '../controllers/manajemen_tunggakan_awal_controller.dart';

class ManajemenTunggakanAwalView extends GetView<ManajemenTunggakanAwalController> {
  const ManajemenTunggakanAwalView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tunggakan Awal'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildFilterSection(),
            const Divider(height: 1),
            Expanded(child: _buildSiswaList()),
            _buildFormSection(),
          ],
        );
      }),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Obx(() => DropdownButtonFormField<String>(
            value: controller.kelasTerpilih.value,
            hint: const Text("Filter Berdasarkan Kelas"),
            isExpanded: true,
            items: controller.daftarKelas.map((kelas) {
              return DropdownMenuItem(value: kelas['id'], child: Text(kelas['nama']!));
            }).toList(),
            onChanged: (value) {
              controller.kelasTerpilih.value = value;
              controller.filterSiswa();
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: controller.kelasTerpilih.value != null ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.kelasTerpilih.value = null;
                  controller.filterSiswa();
                },
              ) : null,
            ),
          )),
          const SizedBox(height: 12),
          TextField(
            controller: controller.searchC,
            onChanged: (value) => controller.filterSiswa(),
            decoration: const InputDecoration(
              labelText: "Cari Nama atau NISN Siswa",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaList() {
    return Obx(() {
      if (controller.daftarSiswaTampil.isEmpty) {
        return const Center(child: Text("Tidak ada data siswa."));
      }
      return ListView.builder(
        itemCount: controller.daftarSiswaTampil.length,
        itemBuilder: (context, index) {
          final siswa = controller.daftarSiswaTampil[index];
          final isSelected = controller.siswaTerpilih.value?.uid == siswa.uid;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: isSelected ? Colors.blue.shade50 : null,
            child: ListTile(
              title: Text(siswa.nama),
              subtitle: Text("NISN: ${siswa.nisn} - Kelas: ${siswa.kelasNama}"),
              onTap: () => controller.pilihSiswa(siswa),
            ),
          );
        },
      );
    });
  }

  Widget _buildFormSection() {
    return Obx(() {
      if (controller.siswaTerpilih.value == null) {
        return const SizedBox.shrink(); // Tampilkan kosong jika tidak ada siswa dipilih
      }
      return Material(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Input untuk: ${controller.siswaTerpilih.value!.nama}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearSelection,
                      )
                    ],
                  ),
                  const Divider(),
                  TextFormField(
                    controller: controller.totalTunggakanC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, NumberInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: "Total Tunggakan",
                      prefixText: "Rp ",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Wajib diisi";
                      if (int.tryParse(value) == null) return "Angka tidak valid";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.keteranganC,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Keterangan Rincian Tunggakan",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Wajib diisi";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Obx(() => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: controller.isSaving.value ? null : controller.simpanTunggakanAwal,
                    icon: controller.isSaving.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                        : const Icon(Icons.save),
                    label: Text(controller.isSaving.value ? "MENYIMPAN..." : "SIMPAN DATA"),
                  )),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}