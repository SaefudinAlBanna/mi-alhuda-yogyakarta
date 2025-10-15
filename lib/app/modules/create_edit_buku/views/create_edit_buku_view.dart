import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/number_input_formatter.dart';
import '../controllers/create_edit_buku_controller.dart';

class CreateEditBukuView extends GetView<CreateEditBukuController> {
  const CreateEditBukuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode.value ? 'Edit Buku/Paket' : 'Tambah Buku/Paket'),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : controller.simpanBuku,
            child: controller.isSaving.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SIMPAN", style: TextStyle(color: Colors.black)),
          )),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: controller.namaC, decoration: const InputDecoration(labelText: "Nama Item (cth: Paket Buku Kelas 1)"), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 16),
            TextFormField(controller: controller.deskripsiC, decoration: const InputDecoration(labelText: "Deskripsi Singkat"), maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(controller: controller.hargaC,
            inputFormatters: [NumberInputFormatter()],
            decoration: const InputDecoration(labelText: "Harga Total", 
            prefixText: "Rp "), 
            keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            const Divider(height: 32),
            Obx(() => SwitchListTile(
              title: const Text("Apakah ini Paket Buku?"),
              subtitle: const Text("Aktifkan jika item ini berisi beberapa buku."),
              value: controller.isPaket.value,
              onChanged: (val) => controller.isPaket.value = val,
            )),
            Obx(() {
              if (!controller.isPaket.value) return const SizedBox.shrink();
              return _buildPaketSection();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaketSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Isi Paket Buku", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.daftarBukuDiPaket.length,
            itemBuilder: (context, index) {
              final item = controller.daftarBukuDiPaket[index];
              return ListTile(
                leading: const Icon(Icons.book_outlined),
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => controller.hapusBukuDariPaket(index),
                ),
              );
            },
          )),
          if (controller.daftarBukuDiPaket.isEmpty)
            const Center(child: Text("Belum ada buku di dalam paket ini.", style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.bukuPaketC,
                  decoration: const InputDecoration(labelText: "Nama Buku", isDense: true),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: controller.tambahBukuKePaket,
              ),
            ],
          ),
        ],
      ),
    );
  }
}