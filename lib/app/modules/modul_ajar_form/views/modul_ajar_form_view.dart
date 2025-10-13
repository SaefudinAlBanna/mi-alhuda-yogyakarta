// lib/app/modules/modul_ajar_form/views/modul_ajar_form_view.dart (FINAL & LENGKAP)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/modul_ajar_form_controller.dart';

class ModulAjarFormView extends GetView<ModulAjarFormController> {
  const ModulAjarFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Edit Modul Ajar' : 'Buat Modul Ajar')),
        actions: [
          // --- [PERBAIKAN KUNCI DI SINI] ---
          Obx(() => IconButton(
            icon: controller.isSaving.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.save_rounded),
            onPressed: controller.isSaving.value ? null : controller.saveModulAjar,
            tooltip: 'Simpan Modul Ajar',
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Informasi Umum"),
            _buildTextField(controller.mapelC, "Mata Pelajaran"),
            Row(
              children: [
                Expanded(child: _buildTextField(controller.faseC, "Fase")),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(controller.kelasC, "Kelas", keyboardType: TextInputType.number)),
              ],
            ),
            _buildTextField(controller.alokasiWaktuC, "Alokasi Waktu (Contoh: 2 JP)"),
            
            _buildSectionTitle("2. Kompetensi & Target"),
            _buildTextField(controller.kompetensiAwalC, "Kompetensi Awal", maxLines: 3),
            
            _buildSectionTitle("3. Profil & Model Pembelajaran"),
            _buildDynamicListSection(title: "Profil Pelajar Pancasila", list: controller.profilPancasila, hint: "Contoh: Beriman, bertakwa..."),
            _buildTextField(controller.modelPembelajaranC, "Model Pembelajaran"),

            _buildSectionTitle("4. Sarana & Prasarana"),
            _buildDynamicListSection(title: "Media Pembelajaran", list: controller.media, hint: "Contoh: Proyektor LCD"),
            _buildDynamicListSection(title: "Sumber Belajar", list: controller.sumberBelajar, hint: "Contoh: Buku Paket"),

            _buildSectionTitle("5. Komponen Inti"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tujuan Pembelajaran", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                  label: const Text("Impor dari ATP"),
                  onPressed: controller.imporTujuanPembelajaran,
                )
              ],
            ),
            _buildTextField(controller.tujuanPembelajaranC, "", maxLines: 5, hint: 'Tujuan pembelajaran akan muncul di sini...'),
            _buildTextField(controller.pemahamanBermaknaC, "Pemahaman Bermakna", maxLines: 3),
            _buildDynamicListSection(title: "Pertanyaan Pemantik", list: controller.pertanyaanPemantik),
            
            _buildSectionTitle("6. Kegiatan Pembelajaran"),
            _buildSesiPembelajaranSection(),
          ],
        ),
      ),
    );
  }
  
  // --- SEMUA HELPER WIDGET (Sama seperti referensi, diadaptasi) ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(title, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          // Jika label tidak kosong, tampilkan. Jika kosong, tampilkan null (tidak ada label).
          labelText: label.isNotEmpty ? label : null, 
          // Kita juga bisa tambahkan hintText sebagai panduan jika label kosong
          hintText: label.isEmpty ? 'Masukkan tujuan pembelajaran di sini...' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }


  Widget _buildDynamicListSection({required String title, required RxList<String> list, String? hint}) {
    final textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                title: Text(list[idx]),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                  onPressed: () => list.removeAt(idx),
                ),
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController, 
                decoration: InputDecoration(hintText: hint ?? 'Tambah item baru...'),
                onSubmitted: (value) { // Memungkinkan tambah dengan tombol enter di keyboard
                  if (value.isNotEmpty) {
                    list.add(value);
                    textController.clear();
                  }
                },
              )
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Get.theme.primaryColor),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  list.add(textController.text);
                  textController.clear();
                }
              },
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }


  Widget _buildSesiPembelajaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onPressed: () => controller.addSesiPembelajaran(),
            icon: Icon(Icons.add),
            label: Text("Tambah Sesi Pertemuan"),
          ),
        ),
        SizedBox(height: 8),
        Obx(() {
          return ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.sesiPembelajaranForms.length,
            separatorBuilder: (ctx, idx) => Divider(height: 32, thickness: 1.5),
            itemBuilder: (context, index) {
              final sesiForm = controller.sesiPembelajaranForms[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Sesi Pertemuan ${index + 1}", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                        onPressed: () => controller.removeSesiPembelajaran(index),
                        tooltip: "Hapus Sesi ${index + 1}",
                      ),
                    ],
                  ),
                  _buildTextField(sesiForm.judulSesiC, "Judul Sesi (Opsional)"),
                  _buildTextField(sesiForm.pendahuluanC, "Pendahuluan", maxLines: 4),
                  _buildTextField(sesiForm.kegiatanIntiC, "Kegiatan Inti", maxLines: 6),
                  _buildTextField(sesiForm.penutupC, "Penutup", maxLines: 4),
                ],
              );
            },
          );
        }),
      ],
    );
  }
}